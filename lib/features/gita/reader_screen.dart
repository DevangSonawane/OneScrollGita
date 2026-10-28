import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core_providers.dart';
import '../../application/library_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';
import '../common/save_toggle_button.dart';
import '../../core/design/copy_on_tap.dart';
import 'chapter_sheet.dart';
import 'heart_burst.dart';
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
      final entries = await ref.read(
        chapterEntriesProvider(chapter).future,
      );
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

  void _saveNow() {
    final e = current;
    if (e == null) return;
    ref.read(settingsProvider.notifier).setLastVerseId(e.id);
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
          _open(_pendingId ?? current?.id ?? formatVerseId(1, 1), animate: false);
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
          Positioned.fill(child: body),
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
    unawaited(ref.read(libraryControllerProvider.notifier).setFavourite(e.id, true));
    setState(() => _hearts.add((key: UniqueKey(), position: position)));
  }

  /// Turns the page when a long verse is pulled past its end.
  void _turn(int direction) {
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
              onNextChapter: (n) => _open(formatVerseId(n, 1), animate: false),
              onPullPastEdge: _turn,
            );
            if (reduced) return page;
            // Neighbouring pages fade to 60% and shift 12 px.
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
              child: page,
            );
          },
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
                    GlassPill(
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
  static const _pullToTurn = 48.0;
  double _pull = 0;
  bool _turned = false;
  bool _sharing = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification) {
      _pull = 0;
      _turned = false;
    } else if (n is OverscrollNotification) {
      // Drags and flicks both count, so a quick swipe at the edge turns.
      _pull += n.overscroll + n.velocity.sign * (n.dragDetails == null ? 24 : 0);
      if (!_turned && _pull.abs() > _pullToTurn) {
        _turned = true;
        widget.onPullPastEdge(_pull.sign.toInt());
      }
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
      await shareVerse(
        context,
        widget.entry,
        ref.read(languageProvider),
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
    return NotificationListener<ScrollNotification>(
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
              VerseTextBlock(entry: entry, copyable: true),
              const SizedBox(height: Space.s24),
              Row(
                children: [
                  SaveToggleButton(verseId: entry.id, kind: SaveKind.favourite),
                  SaveToggleButton(verseId: entry.id, kind: SaveKind.bookmark),
                  Builder(
                    builder: (buttonContext) => Pressable(
                      onTap: _sharing ? null : () => _share(buttonContext),
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
                  const Spacer(),
                  if (entry.hasPurport)
                    FilledButton(
                      onPressed: () => openPurport(context, entry.id),
                      child: const Text('Purport'),
                    ),
                ],
              ),
              if (widget.isLast) ...[
                const SizedBox(height: Space.s32),
                const Divider(),
                const SizedBox(height: Space.s16),
                if (next != null)
                  Center(
                    child: TextButton(
                      onPressed: () => widget.onNextChapter(next),
                      child: Text('Continue to Chapter $next'),
                    ),
                  )
                else ...[
                  Text(
                    'You have reached the end of the Gita',
                    textAlign: TextAlign.center,
                    style: ui.emptyTitle,
                  ),
                  const SizedBox(height: Space.s8),
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
    );
  }
}
