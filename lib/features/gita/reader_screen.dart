import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core_providers.dart';
import '../../application/library_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/study_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/read_rule.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';
import '../common/qualifying_read.dart';
import '../common/save_toggle_button.dart';
import '../../core/design/components.dart';
import '../../core/design/copy_on_tap.dart';
import '../summary/summary_screen.dart' show openSummary;
import 'go_to_verse_sheet.dart';
import 'heart_burst.dart';
import '../study/study_actions.dart';
import '../trainer/trainer_entry.dart';
import 'share_card.dart';
import 'verse_snap_physics.dart';

/// The Gita tab: one scroll per chapter, verse after verse, with verse
/// snapping (VerseSnapPhysics).
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  /// The chapter scroll (tests swipe on it).
  static const scrollKey = ValueKey('reader-scroll');

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

@visibleForTesting
class ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  int? _chapter;
  List<VerseEntry>? _entries;

  /// The chapter scroll. Offset 0 is the top of the verse at [_centerIndex];
  /// earlier verses sit at negative offsets (so any verse opens instantly).
  ScrollController? _scroll;
  int _centerIndex = 0;
  GlobalKey _beforeKey = GlobalKey();
  GlobalKey _afterKey = GlobalKey();
  late final VerseLayout _layout = VerseLayout(
    beforeKey: _beforeKey,
    afterKey: _afterKey,
    centerIndex: () => _centerIndex,
  );
  int _index = 0;
  Object? _error;
  String? _pendingId;
  Timer? _saveTimer;
  Timer? _historyTimer;
  int _loadSerial = 0;
  final _hearts = <({Key key, Offset position})>[];
  Offset _lastDoubleTap = Offset.zero;

  VerseEntry? get current =>
      _entries != null && _index < _entries!.length ? _entries![_index] : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings; // read now, while ref is usable
    final jump = ref.read(readerJumpProvider);
    final start =
        jump?.verseId ??
        ref.read(settingsProvider).lastVerseId ??
        formatVerseId(1, 1);
    _open(start, animate: false);
    ref.listenManual(readerJumpProvider, (prev, next) {
      if (next != null && next.serial != prev?.serial) {
        _open(next.verseId, animate: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveNow();
    _saveTimer?.cancel();
    _historyTimer?.cancel();
    _scroll?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveNow();
    }
  }

  /// Opens the entry [id], loading its chapter if needed.
  Future<void> _open(String id, {required bool animate}) async {
    final chapter = (chapterOfId(id) ?? 1).clamp(1, chapterCount);
    if (chapter == _chapter && _entries != null) {
      final target = indexOfId(_entries!, id).clamp(0, _entries!.length - 1);
      _goToIndex(target, animate: animate);
      return;
    }
    final serial = ++_loadSerial;
    setState(() {
      _error = null;
      _pendingId = id;
    });
    try {
      final entries = await ref.read(chapterEntriesProvider(chapter).future);
      if (!mounted || serial != _loadSerial) return;
      final i = indexOfId(entries, id);
      _scroll?.dispose();
      setState(() {
        _chapter = chapter;
        _entries = entries;
        _index = i < 0 ? 0 : i;
        _recenter(_index);
        _scroll = ScrollController()..addListener(_onScroll);
        _pendingId = null;
      });
      final repo = ref.read(scriptureRepositoryProvider);
      repo.preload(nextChapter(chapter));
      _onSettled();
    } catch (e) {
      if (!mounted || serial != _loadSerial) return;
      setState(() => _error = e);
    }
  }

  /// Makes [index] the scroll's anchor (offset 0). New keys rebuild both
  /// lists around it.
  void _recenter(int index) {
    _layout.lockedTarget = null;
    _centerIndex = index;
    _beforeKey = GlobalKey();
    _afterKey = GlobalKey();
    _layout
      ..beforeKeyRef = _beforeKey
      ..afterKeyRef = _afterKey;
  }

  void _goToIndex(int target, {required bool animate}) {
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients) return;
    _layout.lockedTarget = null; // a jump is not a swipe
    final span = _layout.spans().where((v) => v.index == target).firstOrNull;
    final near = (target - _index).abs() <= 5;
    if (span != null && animate && near && !Motion.of(context).reduced) {
      scroll.animateTo(
        span.top,
        duration: AppDurations.base,
        curve: AppCurves.position,
      );
      return;
    }
    // Far away (or not laid out): reopen the chapter at that verse.
    setState(() => _recenter(target));
    if (target != _index) _onPageChanged(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(0);
    });
  }

  /// The verse under the middle of the screen is the current one.
  void _onScroll() {
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients) return;
    final pos = scroll.position;
    final span = _layout.at(pos.pixels + pos.viewportDimension / 2);
    if (span != null && span.index != _index) _onPageChanged(span.index);
  }

  void _onPageChanged(int i) {
    // Going back a verse (swipe or pull-to-turn) always brings the nav back.
    if (i < _index) ref.read(navBarVisibleProvider.notifier).show();
    setState(() => _index = i);
    _onSettled();
    final e = current;
    if (e != null) {
      final view = View.of(context);
      SemanticsService.sendAnnouncement(
        view,
        'Chapter ${e.chapter}, verse ${shortLabel(e)}, '
        'page ${i + 1} of ${_entries!.length}',
        TextDirection.ltr,
      );
    }
  }

  /// Debounced position save and the 2-second history rule.
  void _onSettled() {
    _saveTimer?.cancel();
    _historyTimer?.cancel();
    final e = current;
    if (e == null) return;
    _saveTimer = Timer(AppDurations.positionDebounce, _saveNow);
    _historyTimer = Timer(AppDurations.historyDwell, () {
      ref.read(libraryControllerProvider.notifier).recordHistory(e.id);
    });
  }

  // Kept in a field: dispose() saves too, when ref is no longer usable.
  late final SettingsNotifier _settings = ref.read(settingsProvider.notifier);

  void _saveNow() {
    final e = current;
    if (e == null) return;
    _settings.setLastVerseId(e.id);
  }

  /// One "Go to verse" sheet for both the chapter and the verse pill.
  void _openGoTo(ChaptersIndex index) async {
    final picked = await showGoToVerseSheet(
      context,
      index: index,
      currentChapter: _chapter ?? 1,
      currentId: current?.id,
    );
    if (picked == null || picked == current?.id) return;
    final sameChapter = chapterOfId(picked) == _chapter;
    unawaited(_open(picked, animate: sameChapter));
  }

  @override
  Widget build(BuildContext context) {
    final indexAsync = ref.watch(chaptersIndexProvider);
    final c = AppColors.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    Widget body;
    if (_error != null || indexAsync.hasError) {
      body = LoadError(
        error: _error ?? indexAsync.error,
        onRetry: () {
          ref.invalidate(chaptersIndexProvider);
          _open(
            _pendingId ?? current?.id ?? formatVerseId(1, 1),
            animate: false,
          );
        },
      );
    } else if (_entries == null || _scroll == null || !indexAsync.hasValue) {
      body = const SizedBox.expand();
    } else {
      body = _buildPages(context, indexAsync.value!);
    }

    final index = indexAsync.value;
    final chapter = index != null && _chapter != null
        ? index.chapter(_chapter!)
        : null;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: QualifyingRead(
              verseId: current?.id,
              dwell: ReadRule.readerDwell,
              child: body,
            ),
          ),
          if (chapter != null && current != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _TopBar(
                topInset: topInset,
                chapter: chapter,
                entry: current!,
                progress: (_index + 1) / _entries!.length,
                onChapterTap: () => _openGoTo(index!),
                onVerseTap: () => _openGoTo(index!),
              ),
            ),
          for (final h in _hearts)
            HeartBurst(
              key: h.key,
              position: h.position,
              onDone: () => setState(() => _hearts.remove(h)),
            ),
          // Keep the colour behind the status bar calm.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset,
            child: IgnorePointer(child: ColoredBox(color: c.bg)),
          ),
        ],
      ),
    );
  }

  /// Double-tap anywhere on a verse: favourite it, with a heart.
  void _like(Offset position) {
    final e = current;
    if (e == null) return;
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      ref.read(libraryControllerProvider.notifier).setFavourite(e.id, true),
    );
    setState(() => _hearts.add((key: UniqueKey(), position: position)));
  }

  Widget _buildPages(BuildContext context, ChaptersIndex index) {
    final entries = _entries!;
    final scroll = _scroll!;
    final topPad = MediaQuery.paddingOf(context).top + _TopBar.height;
    Widget page(int i) => _EntryPage(
      key: ValueKey(entries[i].id),
      entry: entries[i],
      isLast: i == entries.length - 1,
      topPadding: topPad,
      onNextChapter: (n) => _open(formatVerseId(n, 1), animate: false),
    );
    return NavHideOnScroll(
      child: GestureDetector(
        key: ReaderScreen.scrollKey,
        onDoubleTapDown: (d) => _lastDoubleTap = d.localPosition,
        onDoubleTap: () => _like(_lastDoubleTap),
        child: Listener(
          // Each touch starts a fresh swipe decision (VerseSnapPhysics).
          onPointerDown: (_) {
            if (scroll.hasClients) {
              _layout.touchDown(scroll.position.pixels);
            }
          },
          child: LayoutBuilder(
            builder: (context, box) => _VerseViewport(
              height: box.maxHeight,
              child: CustomScrollView(
                key: ValueKey('chapter-$_chapter'),
                controller: scroll,
                center: _afterKey,
                // Keep the neighbouring verses laid out, so snapping always
                // knows where the next and previous verse begin.
                scrollCacheExtent: const ScrollCacheExtent.viewport(1.5),
                physics: VerseSnapPhysics(
                  layout: _layout,
                  parent: const ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverList(
                    key: _beforeKey,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => page(_centerIndex - 1 - i),
                      childCount: _centerIndex,
                    ),
                  ),
                  SliverList(
                    key: _afterKey,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => page(_centerIndex + i),
                      childCount: entries.length - _centerIndex,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reader's screen height, so each verse is at least one screen tall
/// (short verses centred, one per swipe).
class _VerseViewport extends InheritedWidget {
  const _VerseViewport({required this.height, required super.child});

  final double height;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_VerseViewport>()?.height ??
      MediaQuery.sizeOf(context).height;

  @override
  bool updateShouldNotify(_VerseViewport old) => old.height != height;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.topInset,
    required this.chapter,
    required this.entry,
    required this.progress,
    required this.onChapterTap,
    required this.onVerseTap,
  });

  /// One row since v7 (owner removed the separate verse pill).
  static const height = Touch.pillHeight + Space.s8 * 2 + 2;

  final double topInset;
  final Chapter chapter;
  final VerseEntry entry;
  final double progress;
  final VoidCallback onChapterTap;
  final VoidCallback onVerseTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Column(
          children: [
            GlassLayer(
              strength: GlassStrength.light,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.s16,
                  Space.s8,
                  Space.s16,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GlassPill(
                            onTap: onChapterTap,
                            semanticLabel:
                                'Chapter ${chapter.number}, ${chapter.titleEn}, '
                                'verse ${entry.label}. Choose chapter and verse',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    // Where you are, in one pill: "2.47 · title".
                                    '${entry.label} · ${chapter.titleEn}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ui.label(size: 14),
                                  ),
                                ),
                                const SizedBox(width: Space.s4),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: IconSizes.small,
                                  color: c.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.s8),
                        GlassPill(
                          onTap: () => openSummary(context, chapter.number),
                          semanticLabel: 'Summary of chapter ${chapter.number}',
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            width: Touch.pillHeight,
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: IconSizes.small,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.s8),
                        const GlassPill(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: LanguageToggle(onSurface: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.s8),
            // Decorative chapter progress line.
            ExcludeSemantics(
              child: SizedBox(
                height: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: AppDurations.fast,
                    widthFactor: progress,
                    child: ColoredBox(color: c.accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overflow menu in the reader's top row: search and chapter summary, in
/// a floating glass menu that matches the rest of the reader.
class _EntryPage extends ConsumerStatefulWidget {
  const _EntryPage({
    super.key,
    required this.entry,
    required this.isLast,
    required this.topPadding,
    required this.onNextChapter,
  });

  final VerseEntry entry;
  final bool isLast;
  final double topPadding;
  final ValueChanged<int> onNextChapter;

  @override
  ConsumerState<_EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends ConsumerState<_EntryPage> {
  bool _sharing = false;

  /// The folded study tools (highlight, note, learn by heart).
  bool _moreOpen = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final format = await pickShareFormat(context);
      if (format == null || !mounted) return;
      await shareVerse(
        context,
        widget.entry,
        ref.read(languageProvider),
        format: format,
        origin: origin,
      );
    } catch (_) {
      if (mounted) showToast(context, 'Could not share. Please try again.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final entry = widget.entry;
    final next = nextChapter(entry.chapter);
    final top = widget.topPadding + Space.s32;
    final bottom = navBarInset(context);
    // At least one screen tall: a short verse is centred on its own page; a
    // long one starts at the top and continues below.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _VerseViewport.of(context)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Space.readingSide,
          top,
          Space.readingSide,
          bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VerseTextBlock(
                    entry: entry,
                    copyable: true,
                    showWordMeanings: true,
                    highlight: ref.watch(highlightForProvider(entry.id)),
                  ),
                  const SizedBox(height: Space.s24),
                  // Heart, bookmark and share stay out; the study tools fold
                  // away behind "More". Wraps at large text sizes.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: Space.s4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SaveToggleButton(
                            verseId: entry.id,
                            kind: SaveKind.favourite,
                          ),
                          SaveToggleButton(
                            verseId: entry.id,
                            kind: SaveKind.bookmark,
                          ),
                          Builder(
                            builder: (buttonContext) => Pressable(
                              onTap: _sharing
                                  ? null
                                  : () => _share(buttonContext),
                              semanticLabel: 'Share verse',
                              child: SizedBox.square(
                                dimension: Touch.minTarget,
                                child: Icon(
                                  Theme.of(context).platform ==
                                          TargetPlatform.iOS
                                      ? Icons.ios_share_rounded
                                      : Icons.share_rounded,
                                  size: IconSizes.regular,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Pressable(
                            onTap: () => setState(() => _moreOpen = !_moreOpen),
                            semanticLabel: _moreOpen
                                ? 'Hide study tools'
                                : 'More: highlight, note, learn by heart',
                            selected: _moreOpen,
                            child: SizedBox.square(
                              dimension: Touch.minTarget,
                              child: AnimatedRotation(
                                turns: _moreOpen ? 0.25 : 0,
                                duration: Motion.of(context).crossFade,
                                child: Icon(
                                  LucideIcons.ellipsis,
                                  size: IconSizes.regular,
                                  color: _moreOpen
                                      ? c.accentText
                                      : c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (entry.hasPurport)
                        FilledButton(
                          style: compactButtonStyle(context),
                          onPressed: () => openPurport(context, entry.id),
                          child: const Text('Purport'),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: Motion.of(context).crossFade,
                    curve: AppCurves.standard,
                    alignment: Alignment.topLeft,
                    child: !_moreOpen
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: Space.s4),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: Space.s4,
                              children: [
                                HighlightButton(verseId: entry.id),
                                NoteButton(verseId: entry.id),
                                LearnByHeartButton(verseId: entry.id),
                              ],
                            ),
                          ),
                  ),
                  if (widget.isLast) ...[
                    const SizedBox(height: Space.s32),
                    const Divider(),
                    const SizedBox(height: Space.s16),
                    if (next != null) ...[
                      Text(
                        'End of Chapter ${entry.chapter}',
                        textAlign: TextAlign.center,
                        style: ui.emptyTitle,
                      ),
                      const SizedBox(height: Space.s8),
                      Text(
                        'Take a moment, then go on when you are ready.',
                        textAlign: TextAlign.center,
                        style: ui.body(),
                      ),
                      const SizedBox(height: Space.s16),
                      // Two equal choices; nothing advances on its own.
                      FilledButton(
                        onPressed: () => widget.onNextChapter(next),
                        child: Text('Continue to Chapter $next'),
                      ),
                      const SizedBox(height: Space.s8),
                      OutlinedButton(
                        onPressed: () =>
                            reflectOnChapter(context, ref, entry.id),
                        child: const Text('Reflect on this chapter'),
                      ),
                    ] else ...[
                      Text(
                        'You have reached the end of the Gita',
                        textAlign: TextAlign.center,
                        style: ui.emptyTitle,
                      ),
                      const SizedBox(height: Space.s8),
                      const SizedBox(height: Space.s8),
                      OutlinedButton(
                        onPressed: () =>
                            reflectOnChapter(context, ref, entry.id),
                        child: const Text('Reflect on what you read'),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => widget.onNextChapter(1),
                          child: const Text('Begin again at Chapter 1'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
