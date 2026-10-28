import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/scripture_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/verse_entry.dart';
import '../common/common_widgets.dart';
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
        _scroll.animateTo(0, duration: AppDurations.base, curve: AppCurves.position);
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
      body: SafeArea(
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
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: switch (daily) {
                  AsyncData(:final value) => AnimatedSwitcher(
                    duration: AppDurations.base,
                    child: _DailyVerse(key: ValueKey(value.id), entry: value),
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
              // A hairline sets "Continue" apart from today's verse.
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Space.readingSide,
                    Space.s24,
                    Space.readingSide,
                    Space.s8,
                  ),
                  child: Divider(),
                ),
              ),
              const SliverToBoxAdapter(child: ContinueRow()),
              SliverToBoxAdapter(child: SizedBox(height: navBarInset(context))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyVerse extends StatelessWidget {
  const _DailyVerse({super.key, required this.entry});

  final VerseEntry entry;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[
      ShlokaView(lines: entry.sanskrit),
      TransliterationView(lines: entry.transliteration),
      TranslationView(entry: entry),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s32),
          const SectionHeader("TODAY'S VERSE", padding: EdgeInsets.zero),
          const SizedBox(height: Space.s32),
          for (var i = 0; i < blocks.length; i++) ...[
            _Entrance(index: i, child: blocks[i]),
            const SizedBox(height: Space.s32),
          ],
          Center(
            child: ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
          ),
          const SizedBox(height: Space.s24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.s8,
            runSpacing: Space.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => openInReader(context, entry.id),
                style: compactButtonStyle(context),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Read in Gita'),
              ),
              if (entry.hasPurport)
                TextButton(
                  onPressed: () => openPurport(context, entry.id),
                  style: compactButtonStyle(context, filled: false),
                  child: const Text('Purport'),
                ),
            ],
          ),
          const SizedBox(height: Space.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SaveToggleButton(verseId: entry.id, kind: SaveKind.favourite),
              SaveToggleButton(verseId: entry.id, kind: SaveKind.bookmark),
            ],
          ),
        ],
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
