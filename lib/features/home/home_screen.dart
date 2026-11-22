import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/search_providers.dart';
import '../../application/streak_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/motion.dart';
import '../../core/design/native_glass.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/read_rule.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';
import '../common/qualifying_read.dart';
import '../common/save_toggle_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(tabReselectProvider, (_, next) {
      if (next.tab == 0 && _scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: AppDurations.base,
          curve: AppCurves.position,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final today = ref.watch(todayProvider);
    final daily = ref.watch(dailyEntryProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ContentWidth(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.readingSide,
                      Space.s16,
                      Space.readingSide - 4,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatLongDate(today),
                              style: ui.label(color: c.textSecondary, size: 14),
                            ),
                          ),
                          const LanguageToggle(),
                          const SizedBox(width: Space.s8),
                          IconButton(
                            tooltip: 'Search',
                            icon: const Icon(Icons.search_rounded),
                            onPressed: () => openSearch(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _Greeting()),
                  const SliverToBoxAdapter(child: ContinueCard()),
                  SliverToBoxAdapter(
                    child: switch (daily) {
                      AsyncData(:final value) => AnimatedSwitcher(
                        duration: AppDurations.base,
                        child: _DailyVerse(
                          key: ValueKey(value.id),
                          entry: value,
                        ),
                      ),
                      AsyncError(:final error) => Padding(
                        padding: const EdgeInsets.only(top: Space.s48),
                        child: LoadError(
                          error: error,
                          onRetry: () => ref.invalidate(dailyEntryProvider),
                        ),
                      ),
                      // Plain background, no spinner, while parsing (<300 ms).
                      _ => const SizedBox(height: 400),
                    },
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        Space.readingSide,
                        Space.s16,
                        Space.readingSide,
                        0,
                      ),
                      child: FeelingsCard(),
                    ),
                  ),
                  // Room for the Continue button above the nav pill.
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          navBarInset(context) +
                          HomeMetrics.continueHeight +
                          Space.s24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The next step, always in thumb reach (PRD_v5 section 5).
          Positioned(
            left: Space.readingSide,
            right: Space.readingSide,
            bottom: navBarInset(context) - Space.s8,
            child: const ContentWidth(child: ContinueButton()),
          ),
        ],
      ),
    );
  }
}

/// Today's verse as a card (PRD_v7 section 2): the shloka and the
/// translation, then Read in Gita, Purport, favourite and bookmark. The full
/// verse with transliteration is one tap away in the reader.
class _DailyVerse extends ConsumerWidget {
  const _DailyVerse({super.key, required this.entry});

  final VerseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    // Any action on today's verse counts it at once.
    void qualify() => ref.read(readTrackerProvider.notifier).qualify(entry.id);
    final blocks = <Widget>[
      ShlokaView(lines: entry.sanskrit),
      TranslationView(entry: entry),
    ];
    return QualifyingRead(
      verseId: entry.id,
      dwell: ReadRule.homeDwell,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.readingSide,
          Space.s16,
          Space.readingSide,
          0,
        ),
        child: _HomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Space.s8,
                runSpacing: Space.s8,
                children: [
                  const SectionHeader(
                    "TODAY'S VERSE",
                    padding: EdgeInsets.zero,
                  ),
                  ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
                ],
              ),
              const SizedBox(height: Space.s16),
              for (var i = 0; i < blocks.length; i++) ...[
                _Entrance(index: i, child: blocks[i]),
                const SizedBox(height: Space.s16),
              ],
              // Wraps onto two lines at large text sizes.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SaveToggleButton(
                        verseId: entry.id,
                        kind: SaveKind.favourite,
                        onToggled: qualify,
                      ),
                      SaveToggleButton(
                        verseId: entry.id,
                        kind: SaveKind.bookmark,
                        onToggled: qualify,
                      ),
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (entry.hasPurport)
                        TextButton(
                          onPressed: () {
                            qualify();
                            openPurport(context, entry.id);
                          },
                          style: compactButtonStyle(context, filled: false),
                          child: const Text('Purport'),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          qualify();
                          openInReader(context, entry.id);
                        },
                        style: compactButtonStyle(context, filled: false),
                        iconAlignment: IconAlignment.end,
                        icon: Icon(
                          LucideIcons.chevron_right,
                          size: IconSizes.small - 4,
                          color: c.accentText,
                        ),
                        label: const Text('Read in Gita'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The calm card surface Home uses (never glass: reading text sits here).
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(Space.s16), child: child),
      ),
    );
  }
}

/// "Good morning" and a gentle streak chip (no streak: no chip, no nudge).
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final hour = ref.watch(clockProvider)().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final streak = ref.watch(streakStatsProvider).currentStreak;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s4,
        Space.readingSide,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                greeting,
                style: ui.title.copyWith(fontSize: HomeMetrics.greeting),
              ),
            ),
          ),
          if (streak > 0)
            Semantics(
              label: 'Day $streak of your reading streak',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s12,
                  vertical: Space.s4,
                ),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.flame,
                      size: IconSizes.small - 4,
                      color: c.accentText,
                    ),
                    const SizedBox(width: Space.s4),
                    Text(
                      'Day $streak',
                      style: ui.label(size: 13, color: c.accentText),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Continue reading": where the reader stopped, with the chapter's
/// progress (PRD_v7 section 2). Hidden until something has been read.
class ContinueCard extends ConsumerWidget {
  const ContinueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastId = ref.watch(settingsProvider.select((s) => s.lastVerseId));
    if (lastId == null) return const SizedBox.shrink();
    final entry = ref.watch(entryProvider(lastId)).value;
    final index = ref.watch(chaptersIndexProvider).value;
    if (entry == null || index == null) return const SizedBox.shrink();
    final chapter = index.chapters
        .where((ch) => ch.number == entry.chapter)
        .firstOrNull;
    if (chapter == null) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final done = ref
        .watch(readVerseIdsProvider)
        .where((id) => chapterOfId(id) == chapter.number)
        .length
        .clamp(0, chapter.entryCount);
    final title = lang == 'hi' && (chapter.titleHi?.isNotEmpty ?? false)
        ? chapter.titleHi!
        : chapter.titleEn;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s16,
        Space.readingSide,
        0,
      ),
      child: Semantics(
        button: true,
        label:
            'Continue reading. Chapter ${chapter.number}, $title. '
            '$done of ${chapter.entryCount} read. You are at ${entry.label}.',
        excludeSemantics: true,
        child: _HomeCard(
          onTap: () => openInReader(context, lastId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('CONTINUE READING', padding: EdgeInsets.zero),
              const SizedBox(height: Space.s8),
              Text(
                'Chapter ${chapter.number} · $title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ui.label(size: 16),
              ),
              const SizedBox(height: Space.s12),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: chapter.entryCount == 0
                      ? 0
                      : done / chapter.entryCount,
                  minHeight: HomeMetrics.progress,
                  backgroundColor: c.surfaceSoft,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: Space.s8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$done of ${chapter.entryCount} verses',
                      style: ui.body(size: 13),
                    ),
                  ),
                  Text(
                    'You are at ${entry.label}',
                    style: ui.label(size: 13, color: c.accentText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fade in with an 8 px rise, staggered 60 ms. Skipped under reduced motion.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppDurations.slow);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = Motion.of(context);
    if (!motion.allowEntrance) {
      _c.value = 1;
    } else {
      Future.delayed(motion.stagger * widget.index, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppCurves.standard);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// "Continue at 2.48", or "Read today's verse" when nothing is in progress.
class ContinueButton extends ConsumerWidget {
  const ContinueButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastId = ref.watch(settingsProvider.select((s) => s.lastVerseId));
    final last = lastId == null ? null : ref.watch(entryProvider(lastId)).value;
    final daily = ref.watch(dailyEntryProvider).value;
    final target = last ?? daily;
    if (target == null) return const SizedBox.shrink();
    final label = last != null
        ? 'Continue at ${last.label}'
        : "Read today's verse";
    void open() {
      if (last == null) {
        ref.read(readTrackerProvider.notifier).qualify(target.id);
      }
      openInReader(context, target.id);
    }

    // iOS 26+: Apple's clear Liquid Glass button, like the tab bar (owner,
    // 2026-11-22; docs/PRD_v7.md section 4e). Saffron text keeps it the
    // main action.
    if (useNativeGlass(context, ref)) {
      return Center(
        child: NativeGlassButton(
          semanticLabel: label,
          title: label,
          symbol: 'chevron.right',
          symbolTrailing: true,
          foreground: AppColors.of(context).accentText,
          height: HomeMetrics.continueHeight,
          onTap: open,
        ),
      );
    }
    return SizedBox(
      height: HomeMetrics.continueHeight,
      child: FilledButton.icon(
        onPressed: open,
        iconAlignment: IconAlignment.end,
        icon: const Icon(LucideIcons.chevron_right, size: IconSizes.small),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// "How are you feeling?": a few situations from the dataset's themes, and
/// the full situation search behind the card.
class FeelingsCard extends ConsumerWidget {
  const FeelingsCard({super.key});

  /// Theme ids from assets/search/themes.json, shown when present.
  static const themeIds = ['peace', 'stress', 'confusion', 'sadness', 'anger'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final themes = ref.watch(themesProvider).value ?? const [];
    final picks = [
      for (final id in themeIds) ?themes.where((t) => t.id == id).firstOrNull,
    ];
    return Material(
      color: c.surfaceSoft,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: () => openSearch(context),
        child: Padding(
          padding: const EdgeInsets.all(Space.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'How are you feeling?',
                      style: ui.label(size: 17),
                    ),
                  ),
                  Icon(LucideIcons.chevron_right, color: c.textTertiary),
                ],
              ),
              const SizedBox(height: Space.s4),
              Text(
                'Find verses for what you are going through.',
                style: ui.body(size: 14),
              ),
              if (picks.isNotEmpty) ...[
                const SizedBox(height: Space.s12),
                Wrap(
                  spacing: Space.s8,
                  runSpacing: Space.s8,
                  children: [
                    for (final t in picks)
                      ActionChip(
                        label: Text(
                          t.title.of(lang),
                          style: ui.label(size: 14),
                        ),
                        onPressed: () =>
                            openSearch(context, query: t.title.of(lang)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
