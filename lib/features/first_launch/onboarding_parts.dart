import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../premium/sadhak_art.dart';

/// Shared pieces of the guided first launch and the sign-up step, so the
/// whole flow reads as one.

/// "Step 2 of 5" as a row of dots; the current one is a wider pill.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key, required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final motion = Motion.of(context);
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: motion.pageSwap,
              curve: AppCurves.standard,
              margin: const EdgeInsets.symmetric(horizontal: Space.s4 / 2),
              width: i == index
                  ? TrainerMetrics.stepDotActive
                  : TrainerMetrics.stepDot,
              height: TrainerMetrics.stepDot,
              decoration: BoxDecoration(
                color: i <= index ? c.accent : c.hairline,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
        ],
      ),
    );
  }
}

/// The soft saffron aura, mandala and sparks behind the top of a step.
/// Decoration only: no reading text sits on it.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final short =
        MediaQuery.sizeOf(context).height < OnboardingMetrics.shortScreen;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.of(context).sheet,
        curve: AppCurves.standard,
        child: SadhakAmbient(
          height: short
              ? OnboardingMetrics.heroArtShort * 2
              : OnboardingMetrics.heroArt * 2,
        ),
      ),
    );
  }
}

/// The one main action of a step: a tall saffron pill with a soft glow.
class OnboardingCta extends StatelessWidget {
  const OnboardingCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final enabled = onPressed != null && !busy;
    return AnimatedOpacity(
      opacity: onPressed == null ? 0.45 : 1,
      duration: Motion.of(context).crossFade,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.pill),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: p.glow,
                    blurRadius: PaywallMetrics.glowBlur,
                    offset: const Offset(0, Space.s8),
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(OnboardingMetrics.ctaHeight),
            shape: const StadiumBorder(),
            backgroundColor: c.accent,
            foregroundColor: c.onAccent,
            disabledBackgroundColor: c.accent,
            disabledForegroundColor: c.onAccent,
            textStyle: UiStyles(c)
                .label(size: 16)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          child: busy
              ? SizedBox.square(
                  dimension: IconSizes.small,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.onAccent,
                  ),
                )
              : Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Fades and lifts [children] in, one after another, when the step
/// appears. Under reduced motion they are simply there.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: OnboardingMetrics.entrance,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.of(context).allowEntrance) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    // Each child takes half the entrance; starts are spread over the rest.
    final step = n <= 1 ? 0.0 : 0.5 / (n - 1);
    final rise = Motion.of(context).slide(OnboardingMetrics.entranceRise);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (var i = 0; i < n; i++)
          _Rise(
            animation: CurvedAnimation(
              parent: _c,
              curve: Interval(
                i * step,
                (i * step + 0.5).clamp(0.0, 1.0),
                curve: AppCurves.standard,
              ),
            ),
            rise: rise,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _Rise extends AnimatedWidget {
  const _Rise({
    required Animation<double> animation,
    required this.rise,
    required this.child,
  }) : super(listenable: animation);

  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * rise),
        child: child,
      ),
    );
  }
}

/// A big number over a small label ("700 / verses").
class OnboardingStat extends StatelessWidget {
  const OnboardingStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: ui.title.copyWith(
              fontSize: OnboardingMetrics.statNumber,
              color: c.accentText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: Space.s4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ui.body(size: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A row of stats split by hairlines; wraps under large text.
class OnboardingStatRow extends StatelessWidget {
  const OnboardingStatRow({super.key, required this.stats});

  final List<OnboardingStat> stats;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final large = MediaQuery.textScalerOf(context).scale(10) > 14;
    final box = BoxDecoration(
      color: c.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(Radii.card),
      border: Border.all(color: c.hairline),
    );
    if (large) {
      return Container(
        padding: const EdgeInsets.all(Space.s16),
        decoration: box,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.s24,
          runSpacing: Space.s12,
          children: stats,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.s16),
      decoration: box,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: c.hairline),
              Expanded(child: stats[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// An icon in a soft circle, a short title and one line under it.
class OnboardingBenefit extends StatelessWidget {
  const OnboardingBenefit({
    super.key,
    required this.icon,
    required this.title,
    required this.sentence,
  });

  final IconData icon;
  final String title;
  final String sentence;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Semantics(
      label: '$title. $sentence',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: OnboardingMetrics.benefitIcon,
            height: OnboardingMetrics.benefitIcon,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: IconSizes.small, color: c.accentText),
          ),
          const SizedBox(width: Space.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ui
                      .label(size: 15)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Space.s4 / 2),
                Text(sentence, style: ui.body(size: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
