import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/scripture_providers.dart';
import '../../application/streak_providers.dart';
import '../../core/design/copy_on_tap.dart' show showToast;
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import 'completion_share.dart';

/// Shows the "Good work" popup above the nav pill (PRD_v2 section 4). A
/// small solid card that never blocks swiping or scrolling.
class StreakPopupHost extends ConsumerStatefulWidget {
  const StreakPopupHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StreakPopupHost> createState() => _StreakPopupHostState();
}

class _StreakPopupHostState extends ConsumerState<StreakPopupHost> {
  Timer? _timer;
  StreakPopupData? _shown;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(streakPopupProvider, (_, next) {
      _timer?.cancel();
      if (next == null) {
        if (mounted) setState(() => _visible = false);
        return;
      }
      HapticFeedback.lightImpact();
      setState(() {
        _shown = next;
        _visible = true;
      });
      _timer = Timer(AppDurations.streakPopup, _dismiss);
    });
  }

  void _dismiss() => ref.read(streakPopupProvider.notifier).dismiss();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final bottom =
        MediaQuery.paddingOf(context).bottom +
        NavBarMetrics.bottomGap +
        NavBarMetrics.height +
        Space.s12;
    final data = _shown;
    return Stack(
      children: [
        widget.child,
        if (data != null)
          Positioned(
            left: NavBarMetrics.sideMargin,
            right: NavBarMetrics.sideMargin,
            bottom: bottom,
            child: IgnorePointer(
              ignoring: !_visible,
              child: AnimatedSlide(
                offset: _visible || motion.reduced
                    ? Offset.zero
                    : const Offset(0, 0.3),
                duration: motion.sheet,
                curve: AppCurves.standard,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: motion.crossFade,
                  onEnd: () {
                    if (!_visible && mounted) setState(() => _shown = null);
                  },
                  child: _PopupCard(
                    data: data,
                    onTap: _dismiss,
                    onShare: () async {
                      _dismiss();
                      try {
                        await shareCompletion(
                          context,
                          data.stats,
                          ref.read(todayProvider),
                        );
                      } catch (_) {
                        if (context.mounted) {
                          showToast(
                            context,
                            'Could not share. Please try again.',
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PopupCard extends StatelessWidget {
  const _PopupCard({
    required this.data,
    required this.onTap,
    required this.onShare,
  });

  final StreakPopupData data;
  final VoidCallback onTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: NavBarMetrics.maxWidth),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(Radii.card),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  Space.s16,
                  Space.s12,
                  Space.s8,
                  Space.s12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.card),
                  border: Border.all(color: c.hairline),
                  boxShadow: Elevation.soft(c),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.streakLine,
                            style: ui.label(size: 13, color: c.accentText),
                          ),
                          const SizedBox(height: 2),
                          Text(data.title, style: ui.label(size: 16)),
                          const SizedBox(height: 2),
                          Text(data.body, style: ui.body(size: 14)),
                        ],
                      ),
                    ),
                    TextButton(onPressed: onShare, child: const Text('Share')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
