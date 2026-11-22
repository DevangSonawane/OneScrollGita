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

/// What "Learn by heart" shows for a verse: its icon, label and whether
/// it is locked for free users. Shared by the button and the native menu.
({IconData icon, String label, bool locked}) learnByHeartState(
  WidgetRef ref,
  String verseId,
) {
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
  return (icon: icon, label: label, locked: locked && s == null);
}

/// What tapping "Learn by heart" does for a verse.
void openLearnByHeart(BuildContext context, WidgetRef ref, String verseId) {
  final s = ref.read(shlokaForProvider(verseId));
  final today = dateKey(ref.read(todayProvider));
  if (s?.status == ShlokaStatus.learned && s!.isDue(today)) {
    context.push('/trainer-review');
  } else if (s != null && s.status != ShlokaStatus.learning) {
    openTrainerHome(context);
  } else {
    openTrainerFor(context, ref, verseId);
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
    final state = learnByHeartState(ref, verseId);
    return TextButton.icon(
      style: compactButtonStyle(context, filled: false),
      onPressed: () => openLearnByHeart(context, ref, verseId),
      icon: Icon(
        state.locked ? LucideIcons.lock : state.icon,
        size: IconSizes.small - 2,
        color: c.accentText,
      ),
      label: Text(state.label),
    );
  }
}
