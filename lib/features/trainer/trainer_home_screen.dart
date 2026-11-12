import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/local_date.dart';
import '../../domain/premium.dart';
import '../../domain/trainer/trainer.dart';
import '../common/common_widgets.dart';
import '../premium/sadhak_art.dart';
import 'trainer_entry.dart';

/// The shloka trainer's home: due reviews, verses in progress and the
/// verses already learned.
class TrainerHomeScreen extends ConsumerWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final all = ref.watch(shlokaProgressProvider).value ?? const [];
    final entitlement = ref.watch(entitlementProvider);
    final due = ref
        .watch(dueReviewsProvider)
        .where(
          (s) => canUse(
            PremiumFeature.trainerReviews,
            entitlement,
            verseId: s.verseId,
          ),
        )
        .toList();
    final learning = all
        .where((s) => s.status == ShlokaStatus.learning)
        .toList();
    final learned = all
        .where((s) => s.status != ShlokaStatus.learning)
        .toList();
    final mastered = learned
        .where((s) => s.status == ShlokaStatus.mastered)
        .length;
    final suggestions = [
      for (final id in FreeLimits.trainerVerses)
        if (!all.any((s) => s.verseId == id)) id,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shloka trainer'),
        leading: LucideBackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.s32),
            children: [
              _Header(
                learned: learned.length,
                mastered: mastered,
                inProgress: learning.length,
              ),
              if (due.isNotEmpty) ...[
                const SizedBox(height: Space.s16),
                _DueCard(count: due.length),
              ],
              if (learning.isNotEmpty) ...[
                const SectionHeader('IN PROGRESS'),
                for (final s in learning)
                  _ShlokaTile(
                    state: s,
                    subtitle:
                        'Step ${s.step} of 5 · ${TrainerStep.of(s.step).title}',
                    onTap: () => openTrainerFor(context, ref, s.verseId),
                  ),
              ],
              if (learned.isNotEmpty) ...[
                const SectionHeader('MY SHLOKAS'),
                for (final s in learned)
                  _ShlokaTile(
                    state: s,
                    subtitle: s.status == ShlokaStatus.mastered
                        ? 'Mastered'
                        : 'Next review ${_friendlyDate(s.nextReview!, ref)}',
                    onTap: () => openInReader(context, s.verseId),
                  ),
              ],
              if (suggestions.isNotEmpty) ...[
                SectionHeader(all.isEmpty ? 'START HERE' : 'FREE TO LEARN'),
                for (final id in suggestions)
                  _ShlokaTile(
                    verseId: id,
                    subtitle: 'Free',
                    onTap: () => openTrainerFor(context, ref, id),
                  ),
              ],
              const SizedBox(height: Space.s24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.readingSide,
                ),
                child: Text(
                  'To learn any other verse, open it in the Gita and tap '
                  '"Learn by heart".',
                  textAlign: TextAlign.center,
                  style: ui.body(size: 14),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/gita'),
                  child: const Text('Open the Gita'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _friendlyDate(String key, WidgetRef ref) {
    final today = dateKey(ref.read(todayProvider));
    final d = daysBetween(today, key);
    if (d <= 0) return 'today';
    if (d == 1) return 'tomorrow';
    return 'in $d days';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.learned,
    required this.mastered,
    required this.inProgress,
  });

  final int learned;
  final int mastered;
  final int inProgress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    Widget stat(int n, String label) => Expanded(
      child: Semantics(
        label: '$n $label',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              '$n',
              style: ui.title.copyWith(
                fontSize: StreakMetrics.bigNumber * 0.7,
                color: c.accentText,
              ),
            ),
            Text(label, style: ui.body(size: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s8,
        Space.readingSide,
        0,
      ),
      padding: const EdgeInsets.all(Space.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.cardTop, p.cardBottom],
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const LotusMark(size: PaywallMetrics.lotusIcon),
          const SizedBox(height: Space.s8),
          Text(
            'Carry the verses in your heart',
            textAlign: TextAlign.center,
            style: ui.label(size: 16, color: c.accentText),
          ),
          const SizedBox(height: Space.s16),
          Row(
            children: [
              stat(learned, 'learned'),
              stat(mastered, 'mastered'),
              stat(inProgress, 'in progress'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      padding: const EdgeInsets.all(Space.s16),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.repeat, color: c.accentText),
          const SizedBox(width: Space.s12),
          Expanded(
            child: Text(
              count == 1
                  ? '1 verse is ready for review'
                  : '$count verses are ready for review',
              style: ui.label(color: c.accentText),
            ),
          ),
          const SizedBox(width: Space.s8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
            ),
            onPressed: () => context.push('/trainer-review'),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

class _ShlokaTile extends ConsumerWidget {
  const _ShlokaTile({
    required this.subtitle,
    required this.onTap,
    this.state,
    this.verseId,
  });

  final ShlokaState? state;
  final String? verseId;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = state?.verseId ?? verseId!;
    final entry = ref.watch(entryProvider(id)).value;
    final index = ref.watch(chaptersIndexProvider).value;
    final lang = ref.watch(languageProvider);
    if (entry == null || index == null) return const SizedBox.shrink();
    return VerseListTile(
      reference: entry.label,
      chapterTitle: '${index.chapter(entry.chapter).title(lang)} · $subtitle',
      preview: entry.transliteration.join(' '),
      onTap: onTap,
    );
  }
}
