import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../domain/local_date.dart';
import '../../domain/premium.dart';
import '../../domain/trainer/trainer.dart';
import '../premium/paywall_screen.dart';

void openTrainerHome(BuildContext context) => context.push('/trainer');

/// Opens the trainer on [verseId], or the paywall when it is locked.
void openTrainerFor(BuildContext context, WidgetRef ref, String verseId) {
  final allowed = canUse(
    PremiumFeature.trainerAnyVerse,
    ref.read(entitlementProvider),
    verseId: verseId,
  );
  if (allowed) {
    context.push('/trainer-learn/${Uri.encodeComponent(verseId)}');
  } else {
    openPaywall(context, reason: PremiumFeature.trainerAnyVerse);
  }
}

/// "Learn by heart" under each verse in the reader. Shows the verse's
/// trainer state once it has one.
class LearnByHeartButton extends ConsumerWidget {
  const LearnByHeartButton({super.key, required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final s = ref.watch(shlokaForProvider(verseId));
    final today = dateKey(ref.watch(todayProvider));
    final premium = ref.watch(isPremiumProvider);
    final locked = !premium && !FreeLimits.trainerVerses.contains(verseId);
    final (IconData icon, String label) = switch (s?.status) {
      null => (LucideIcons.brain, 'Learn by heart'),
      ShlokaStatus.learning => (
        LucideIcons.brain,
        'Continue learning · step ${s!.step} of 5',
      ),
      ShlokaStatus.learned when s!.isDue(today) => (
        LucideIcons.repeat,
        'Review due',
      ),
      ShlokaStatus.learned => (LucideIcons.check, 'Learned'),
      ShlokaStatus.mastered => (LucideIcons.sparkles, 'Mastered'),
    };
    return TextButton.icon(
      style: compactButtonStyle(context, filled: false),
      onPressed: () => s?.status == ShlokaStatus.learned && s!.isDue(today)
          ? context.push('/trainer-review')
          : s != null && s.status != ShlokaStatus.learning
          ? openTrainerHome(context)
          : openTrainerFor(context, ref, verseId),
      icon: Icon(
        locked && s == null ? LucideIcons.lock : icon,
        size: IconSizes.small - 2,
        color: c.accentText,
      ),
      label: Text(label),
    );
  }
}
