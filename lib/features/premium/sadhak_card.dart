import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/premium_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import 'paywall_screen.dart';
import 'sadhak_art.dart';

/// The Sadhak entry in Profile: a warm gradient card. Opens the paywall, or
/// the "You are a Sadhak" view when the plan is active.
class SadhakCard extends ConsumerWidget {
  const SadhakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    final premium = ref.watch(isPremiumProvider);
    final subtitle = premium
        ? 'Active. Thank you for your support.'
        : 'Learn shlokas by heart and keep your own study notebook.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      child: Pressable(
        onTap: () => openPaywall(context),
        radius: Radii.card,
        semanticLabel: 'Sadhak. $subtitle',
        child: Container(
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
          child: Row(
            children: [
              const LotusMark(size: PaywallMetrics.lotusIcon),
              const SizedBox(width: Space.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Space.s8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Sadhak',
                          style: ui.title.copyWith(
                            fontSize: 20,
                            color: c.accentText,
                          ),
                        ),
                        Text(
                          'साधक',
                          style: ReadingStyles(c, 1).sanskrit.copyWith(
                            fontSize: 16,
                            color: c.accentText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s4),
                    Text(subtitle, style: ui.body(size: 14)),
                  ],
                ),
              ),
              const SizedBox(width: Space.s8),
              Icon(
                premium ? LucideIcons.check : LucideIcons.chevron_right,
                size: IconSizes.small,
                color: c.accentText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
