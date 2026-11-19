import 'dart:async';

import 'package:flutter/material.dart';
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
import 'chapter_sheet.dart';
import 'heart_burst.dart';
import '../study/study_actions.dart';
import '../trainer/trainer_entry.dart';
import 'share_card.dart';
import 'verse_selector_sheet.dart';

/// The Gita tab: one PageView per chapter, one page per entry.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

@visibleForTesting
class ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  int? _chapter;
  List<VerseEntry>? _entries;
  PageController? _pages;
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
    _pages?.dispose();
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
      _pages?.dispose();
      setState(() {
        _chapter = chapter;
        _entries = entries;
        _index = i < 0 ? 0 : i;
        _pages = PageController(initialPage: _index);
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

  void _goToIndex(int target, {required bool animate}) {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final distance = (target - _index).abs();
    if (!animate || distance > 5 || Motion.of(context).reduced) {
      pages.jumpToPage(target);
    } else {
      pages.animateToPage(
        target,
        duration: AppDurations.base,
        curve: AppCurves.position,
      );
    }
  }

  void _onPageChanged(int i) {
    debugPrint('SWIPELOG page $_index -> $i'); // TEMP-SWIPE-LOG
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

  void _openChapterSheet(ChaptersIndex index) async {
    final picked = await showChapterSheet(
      context,
      index: index,
      currentChapter: _chapter ?? 1,
    );
    if (picked != null && picked != _chapter) {
      unawaited(_open(formatVerseId(picked, 1), animate: false));
    }
  }

  void _openVerseSelector(Chapter chapter) async {
    final entries = _entries;
    if (entries == null) return;
    final picked = await showVerseSelector(
      context,
      chapter: chapter,
      entries: entries,
      currentIndex: _index,
    );
    if (picked != null && picked != _index) {
      _goToIndex(picked, animate: true);
    }
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
    } else if (_entries == null || _pages == null || !indexAsync.hasValue) {
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
                onChapterTap: () => _openChapterSheet(index!),
                onVerseTap: () => _openVerseSelector(chapter),
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

  /// Turns the page when a long verse is pulled past its end.
  void _turn(int direction) {
    debugPrint('SWIPELOG pull-turn $direction'); // TEMP-SWIPE-LOG
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final duration = Motion.of(context).pageSwap;
    if (direction > 0 && _index < _entries!.length - 1) {
      pages.nextPage(duration: duration, curve: AppCurves.position);
    } else if (direction < 0 && _index > 0) {
      pages.previousPage(duration: duration, curve: AppCurves.position);
    }
  }

  Widget _buildPages(BuildContext context, ChaptersIndex index) {
    final entries = _entries!;
    final pages = _pages!;
    final topPad = MediaQuery.paddingOf(context).top + _TopBar.height;
    final reduced = Motion.of(context).reduced;
    return NavHideOnScroll(
      minDepth: 1, // page swipes do not hide the nav pill
      child: GestureDetector(
        onDoubleTapDown: (d) => _lastDoubleTap = d.localPosition,
        onDoubleTap: () => _like(_lastDoubleTap),
        // Reels-style: swipe up for the next verse, down for the previous.
        child: NotificationListener<ScrollNotification>(
          // TEMP-SWIPE-LOG
          onNotification: (n) {
            if (n.depth == 0 && n is! ScrollUpdateNotification) {
              debugPrint(
                'SWIPELOG pager ${n.runtimeType} '
                'drag=${n is ScrollStartNotification ? n.dragDetails != null : '-'}',
              );
            }
            return false;
          },
          child: PageView.builder(
            key: ValueKey('chapter-$_chapter'),
            controller: pages,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final page = _EntryPage(
                entry: entries[i],
                isLast: i == entries.length - 1,
                topPadding: topPad,
                onNextChapter: (n) =>
                    _open(formatVerseId(n, 1), animate: false),
                onPullPastEdge: _turn,
              );
              if (reduced) return page;
              // Neighbouring pages fade to 60% and shift 12 px. The boundary
              // keeps the verse text from repainting on every swipe frame.
              final painted = RepaintBoundary(child: page);
              return AnimatedBuilder(
                animation: pages,
                builder: (context, child) {
                  var delta = 0.0;
                  if (pages.hasClients && pages.position.haveDimensions) {
                    delta = (pages.page! - i).clamp(-1.0, 1.0);
                  }
                  return Opacity(
                    opacity: 1 - 0.4 * delta.abs(),
                    child: Transform.translate(
                      offset: Offset(0, delta * 12),
                      child: child,
                    ),
                  );
                },
                child: painted,
              );
            },
          ),
        ),
      ),
    );
  }
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

  static const height = Touch.pillHeight * 2 + Space.s8 * 3 + 2;

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
                                'Chapter ${chapter.number}, ${chapter.titleEn}. '
                                'Choose chapter',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Ch ${chapter.number} · ${chapter.titleEn}',
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
                        GlassPill(
                          padding: EdgeInsets.zero,
                          child: _ReaderOverflow(chapter: chapter.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s8),
                    Row(
                      children: [
                        GlassPill(
                          onTap: onVerseTap,
                          semanticLabel: 'Verse ${entry.label}. Choose verse',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(entry.label, style: ui.label(size: 14)),
                              const SizedBox(width: Space.s4),
                              Icon(
                                Icons.expand_more_rounded,
                                size: IconSizes.small,
                                color: c.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
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
class _ReaderOverflow extends StatelessWidget {
  const _ReaderOverflow({required this.chapter});

  final int chapter;

  Future<void> _open(BuildContext context) async {
    final picked = await showGlassMenu<String>(
      context,
      items: const [
        GlassMenuItem(
          value: 'search',
          icon: Icons.search_rounded,
          label: 'Search',
        ),
        GlassMenuItem(
          value: 'summary',
          icon: Icons.info_outline_rounded,
          label: 'Chapter summary',
        ),
      ],
    );
    if (!context.mounted || picked == null) return;
    picked == 'search' ? openSearch(context) : openSummary(context, chapter);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: () => _open(context),
      semanticLabel: 'More',
      radius: Touch.pillHeight / 2,
      child: SizedBox.square(
        dimension: Touch.pillHeight,
        child: Icon(
          Icons.more_horiz_rounded,
          size: IconSizes.small,
          color: c.textPrimary,
        ),
      ),
    );
  }
}

class _EntryPage extends ConsumerStatefulWidget {
  const _EntryPage({
    required this.entry,
    required this.isLast,
    required this.topPadding,
    required this.onNextChapter,
    required this.onPullPastEdge,
  });

  final VerseEntry entry;
  final bool isLast;
  final double topPadding;
  final ValueChanged<int> onNextChapter;

  /// +1 when a long verse is pulled up past its end, -1 past its start.
  final ValueChanged<int> onPullPastEdge;

  @override
  ConsumerState<_EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends ConsumerState<_EntryPage> {
  double _pull = 0;
  bool _turned = false;
  bool _sharing = false;

  /// Where the current drag began: only a drag that starts at an edge may
  /// turn the page, so reading to the end of a long verse never does.
  bool _dragFromTop = false;
  bool _dragFromBottom = false;

  /// More verse text below the fold (shows a soft fade).
  bool _moreBelow = false;

  /// The folded study tools (highlight, note, learn by heart).
  bool _moreOpen = false;

  void _updateMore(ScrollMetrics m) {
    final more = m.extentAfter > ReaderMetrics.edgeSlop;
    if (more != _moreBelow && mounted) setState(() => _moreBelow = more);
  }

  bool _onScroll(ScrollNotification n) {
    // TEMP-SWIPE-LOG
    if (n is! ScrollUpdateNotification) {
      debugPrint(
        'SWIPELOG inner ${n.runtimeType} d=${n.depth} '
        'px=${n.metrics.pixels.toStringAsFixed(0)} '
        'max=${n.metrics.maxScrollExtent.toStringAsFixed(0)} '
        'vp=${n.metrics.viewportDimension.toStringAsFixed(0)} '
        '${n is OverscrollNotification ? 'os=${n.overscroll.toStringAsFixed(1)} drag=${n.dragDetails != null}' : ''}',
      );
    }
    if (n.depth != 0) return false;
    final m = n.metrics;
    if (n is ScrollStartNotification) {
      _pull = 0;
      _turned = false;
      _dragFromTop = m.extentBefore <= ReaderMetrics.edgeSlop;
      _dragFromBottom = m.extentAfter <= ReaderMetrics.edgeSlop;
    } else if (n is OverscrollNotification) {
      // Only a deliberate pull turns: never momentum from a flick, and
      // never a drag that began mid-verse and ran into the edge.
      final allowed = n.overscroll > 0 ? _dragFromBottom : _dragFromTop;
      if (n.dragDetails != null && allowed) {
        _pull += n.overscroll;
        if (!_turned && _pull.abs() > ReaderMetrics.pullToTurn) {
          _turned = true;
          widget.onPullPastEdge(_pull.sign.toInt());
        }
      }
    }
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _updateMore(m);
    }
    return false;
  }

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
    final page = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        if (n.depth == 0) _updateMore(n.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: SingleChildScrollView(
          // Clamping, so pulling past the end reports an overscroll.
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            top: widget.topPadding + Space.s32,
            bottom: navBarInset(context),
            left: Space.readingSide,
            right: Space.readingSide,
          ),
          child: ContentWidth(
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
                                Theme.of(context).platform == TargetPlatform.iOS
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
                      onPressed: () => reflectOnChapter(context, ref, entry.id),
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
                      onPressed: () => reflectOnChapter(context, ref, entry.id),
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
        ),
      ),
    );
    final c2 = AppColors.of(context);
    return Stack(
      children: [
        page,
        // A soft fade says "there is more below" on long verses.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: navBarInset(context) + ReaderMetrics.moreFade,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _moreBelow ? 1 : 0,
              duration: Motion.of(context).crossFade,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c2.bg.withValues(alpha: 0), c2.bg],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
