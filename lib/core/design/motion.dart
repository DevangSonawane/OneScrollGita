import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Single place that decides durations and whether to slide or only fade,
/// honouring the system "reduce motion" setting.
class Motion {
  const Motion._(this.reduced);

  final bool reduced;

  static Motion of(BuildContext context) =>
      Motion._(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// Slides and springs become short fades under reduced motion.
  Duration get pageSwap => reduced ? AppDurations.fast : AppDurations.base;
  Duration get crossFade => AppDurations.fast;
  Duration get sheet => reduced ? AppDurations.fast : AppDurations.slow;
  Duration get savePulse => reduced ? AppDurations.instant : AppDurations.savePulse;
  Duration get navHide => AppDurations.navHide;
  Duration get stagger => reduced ? Duration.zero : AppDurations.stagger;

  /// Distance for slide-in effects (0 when reduced).
  double slide(double px) => reduced ? 0 : px;

  bool get allowNavHide => !reduced;
  bool get allowEntrance => !reduced;
}
