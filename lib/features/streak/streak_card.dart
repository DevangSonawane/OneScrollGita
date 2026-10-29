import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/scripture_providers.dart';
import '../../application/streak_providers.dart';
import '../../core/design/copy_on_tap.dart' show showToast;
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import 'completion_share.dart';

/// Calm streak card at the top of Profile (PRD_v2 section 4). No red, no
/// warnings.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final s = ref.watch(streakStatsProvider);
    final empty = s.totalDays == 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      padding: const EdgeInsets.all(Space.s12),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: empty
          ? Text('Read one verse to begin your streak.', style: ui.body())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Touch.minTarget),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${s.currentStreak}',
                            style: ui.title.copyWith(
                              fontSize: 36,
                              height: 1,
                              color: c.accentText,
                            ),
                          ),
                          const SizedBox(width: Space.s8),
                          Expanded(
                            child: Text(
                              'day streak',
                              style: ui.label(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.s8),
                      _SevenDots(days: s.lastSevenDays),
                      const SizedBox(height: Space.s8),
                      Wrap(
                        spacing: Space.s16,
                        runSpacing: Space.s4,
                        children: [
                          Text(
                            'Longest ${s.longestStreak}',
                            style: ui.body(size: 13),
                          ),
                          Text(
                            s.totalDays == 1
                                ? '1 day read'
                                : '${s.totalDays} days read',
                            style: ui.body(size: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Builder(
                    builder: (b) => IconButton(
                      tooltip: 'Share streak',
                      onPressed: () => _share(b, ref),
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        size: IconSizes.small,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _share(BuildContext buttonContext, WidgetRef ref) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await shareCompletion(
        buttonContext,
        ref.read(streakStatsProvider),
        ref.read(todayProvider),
        origin: origin,
      );
    } catch (_) {
      if (buttonContext.mounted) {
        showToast(buttonContext, 'Could not share. Please try again.');
      }
    }
  }
}

class _SevenDots extends StatelessWidget {
  const _SevenDots({required this.days});

  final List<bool> days;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final read = days.where((d) => d).length;
    return Semantics(
      label: 'Read on $read of the last 7 days',
      excludeSemantics: true,
      child: Row(
        children: [
          for (final d in days)
            Container(
              width: StreakMetrics.dot,
              height: StreakMetrics.dot,
              margin: const EdgeInsets.only(right: Space.s8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d ? c.accent : Colors.transparent,
                border: Border.all(
                  color: d ? c.accent : c.hairline,
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
