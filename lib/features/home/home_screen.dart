import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../application/scripture_providers.dart';
import '../../application/streak_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/read_rule.dart';
import '../common/common_widgets.dart';
import '../common/qualifying_read.dart';
import '../common/save_toggle_button.dart';
import 'home_extras.dart';

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
                  // Owner, 2026-11-23: a greeting, the plan banners, today's
                  // verse and the feeling cards. No date, language, search,
                  // streak chip or Continue reading here.
                  const SliverToBoxAdapter(child: HomeGreeting()),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: Space.s16),
                      child: PlanBanners(),
                    ),
                  ),
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
                      padding: EdgeInsets.only(top: Space.s24),
                      child: FeelingCards(),
                    ),
                  ),
                  // Room above the nav pill.
                  SliverToBoxAdapter(
                    child: SizedBox(height: navBarInset(context) + Space.s24),
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
  const _HomeCard({required this.child});

  final Widget child;

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
      child: Padding(padding: const EdgeInsets.all(Space.s16), child: child),
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
