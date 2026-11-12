import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/premium_providers.dart';
import '../../core/config/app_links.dart';
import '../common/common_widgets.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/premium.dart';
import 'sadhak_art.dart';

/// Opens the Sadhak paywall, optionally explaining which locked feature led
/// here. Never opened on launch or on a timer (PRD_v3 section 3).
Future<void> openPaywall(BuildContext context, {PremiumFeature? reason}) =>
    context.push(reason == null ? '/sadhak' : '/sadhak?reason=${reason.name}');

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason});

  final PremiumFeature? reason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: AppDurations.paywallEntrance,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).reduced) {
      _entrance.value = 1;
    } else if (_entrance.value == 0) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = ref.watch(paywallControllerProvider);
    final premium = ref.watch(isPremiumProvider);
    final done = state.status == PaywallStatus.success;
    final motion = Motion.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: motion.pageSwap,
              // Each view fills the screen (never centred and shrunk).
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: done || premium
                  ? _WelcomeView(
                      key: const ValueKey('welcome'),
                      justBought: done,
                      onClose: _close,
                    )
                  : _OfferView(
                      key: const ValueKey('offer'),
                      entrance: _entrance,
                      reason: widget.reason,
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: Space.s8),
                child: Pressable(
                  onTap: _close,
                  semanticLabel: 'Close',
                  child: SizedBox.square(
                    dimension: Touch.minTarget,
                    child: DecoratedBox(
                      // Stays readable over scrolled text.
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.bg.withValues(alpha: 0.86),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: IconSizes.regular,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large text: only the button stays pinned; terms and links scroll.
bool _compactPanel(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.3;

/// Scrolls [content] over the ambient art, whose centre lines up with the
/// hero (the lotus on the offer, the bloom on the welcome).
class _HeroScroll extends StatelessWidget {
  const _HeroScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + Touch.minTarget;
    const heroMin = PaywallMetrics.heroHeight - Touch.minTarget;
    return SingleChildScrollView(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SadhakAmbient(height: (top + heroMin / 2) * 2),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Space.readingSide,
              top,
              Space.readingSide,
              0,
            ),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entrance helper: fade and rise within an interval of the entrance.

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.start,
    required this.child,
  });

  final Animation<double> animation;

  /// 0..1 position in the entrance where this item begins.
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rise = Motion.of(context).slide(PaywallMetrics.entranceRise);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start.clamp(0.0, 0.7),
        (start + 0.35).clamp(0.0, 1.0),
        curve: AppCurves.standard,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, rise * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The offer.

class _OfferView extends ConsumerWidget {
  const _OfferView({super.key, required this.entrance, this.reason});

  final Animation<double> entrance;
  final PremiumFeature? reason;

  static const _benefits = [
    (
      LucideIcons.brain,
      'Learn any shloka by heart',
      'A gentle five-step trainer for all 700 verses.',
    ),
    (
      LucideIcons.repeat,
      'Remember it for life',
      'Spaced reviews bring each verse back just before you forget.',
    ),
    (
      LucideIcons.notebook_pen,
      'Unlimited notes and a journal',
      'Your reflections, kept beside every verse.',
    ),
    (
      LucideIcons.file_down,
      'Your Gita notebook',
      'Export notes, highlights and journal as a PDF to keep.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    final state = ref.watch(paywallControllerProvider);
    final controller = ref.read(paywallControllerProvider.notifier);
    final stagger = Motion.of(context).reduced ? 0.0 : 0.06;

    final compact = _compactPanel(context);
    return Column(
      children: [
        Expanded(
          child: _HeroScroll(
            children: [
              _Reveal(
                animation: entrance,
                start: 0,
                child: _Hero(premium: p, colors: c),
              ),
              if (reason != null) ...[
                const SizedBox(height: Space.s16),
                _Reveal(
                  animation: entrance,
                  start: 0.1,
                  child: Center(child: _ReasonChip(text: reason!.reason)),
                ),
              ],
              const SizedBox(height: Space.s24),
              _Reveal(
                animation: entrance,
                start: 0.14,
                child: Semantics(
                  header: true,
                  child: Text(
                    'Go deeper into the Gita',
                    textAlign: TextAlign.center,
                    style: ui.title,
                  ),
                ),
              ),
              const SizedBox(height: Space.s8),
              _Reveal(
                animation: entrance,
                start: 0.18,
                child: Text(
                  'Carry the verses in your heart, and keep your own '
                  'study beside them.',
                  textAlign: TextAlign.center,
                  style: ui.body(size: 16),
                ),
              ),
              const SizedBox(height: Space.s24),
              for (final (i, (icon, title, sub)) in _benefits.indexed)
                _Reveal(
                  animation: entrance,
                  start: 0.24 + i * stagger,
                  child: _BenefitRow(icon: icon, title: title, sub: sub),
                ),
              const SizedBox(height: Space.s8),
              _Reveal(
                animation: entrance,
                start: 0.24 + _benefits.length * stagger,
                child: const _AlwaysFree(),
              ),
              const SizedBox(height: Space.s24),
              _Reveal(
                animation: entrance,
                start: 0.5,
                child: _Plans(state: state, onSelect: controller.select),
              ),
              if (state.message != null) ...[
                const SizedBox(height: Space.s12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.message!,
                    textAlign: TextAlign.center,
                    style: ui.body(size: 14, color: c.textSecondary),
                  ),
                ),
              ],
              if (compact) ...[
                const SizedBox(height: Space.s16),
                _TermsAndLinks(state: state),
              ],
              const SizedBox(height: Space.s16),
            ],
          ),
        ),
        _Reveal(
          animation: entrance,
          start: 0.6,
          child: _BottomPanel(state: state, compact: compact),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.premium, required this.colors});

  final PremiumColors premium;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final ui = UiStyles(colors);
    // Grows with large text instead of overflowing.
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: PaywallMetrics.heroHeight - Touch.minTarget,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BreathingLotus(),
          const SizedBox(height: Space.s12),
          Semantics(
            label: 'Sadhak',
            excludeSemantics: true,
            child: Shimmer(
              base: colors.accentText,
              highlight: premium.gold,
              child: Text(
                'साधक',
                style: ReadingStyles(colors, 1).sanskrit.copyWith(
                  fontSize: PaywallMetrics.titleSize,
                  height: 1.25,
                ),
              ),
            ),
          ),
          Text(
            'SADHAK',
            style: ui.overline.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The lotus gently grows and settles with a soft glow (still under reduced
/// motion).
class _BreathingLotus extends StatefulWidget {
  const _BreathingLotus();

  @override
  State<_BreathingLotus> createState() => _BreathingLotusState();
}

class _BreathingLotusState extends State<_BreathingLotus>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).reduced) {
      _c
        ..stop()
        ..value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PremiumColors.of(context);
    const size = PaywallMetrics.lotusIcon * 1.6;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = Curves.easeInOut.transform(_c.value);
          return SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // A soft halo that breathes with the lotus.
                OverflowBox(
                  maxWidth: size * 3,
                  maxHeight: size * 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          p.glow.withValues(alpha: 0.5 + 0.3 * v),
                          p.glow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: SizedBox.square(dimension: size * (2.4 + 0.4 * v)),
                  ),
                ),
                Transform.scale(scale: 0.97 + 0.05 * v, child: child),
              ],
            ),
          );
        },
        child: const LotusMark(size: size),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s8,
      ),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.lock,
            size: IconSizes.small - 4,
            color: c.accentText,
          ),
          const SizedBox(width: Space.s8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: UiStyles(c).label(size: 14, color: c.accentText),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: PaywallMetrics.benefitIcon,
              height: PaywallMetrics.benefitIcon,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.goldSoft, c.accentSoft],
                ),
              ),
              child: Icon(icon, size: IconSizes.small, color: c.accentText),
            ),
            const SizedBox(width: Space.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ui.label(size: 16)),
                  const SizedBox(height: 2),
                  Text(sub, style: ui.body(size: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlwaysFree extends StatelessWidget {
  const _AlwaysFree();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.s12),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.input),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.heart_handshake,
            size: IconSizes.small,
            color: c.textSecondary,
          ),
          const SizedBox(width: Space.s12),
          Expanded(
            child: Text(
              'Every verse, translation, purport and word meaning stays free '
              'for everyone.',
              style: UiStyles(c).body(size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plans.

class _Plans extends StatelessWidget {
  const _Plans({required this.state, required this.onSelect});

  final PaywallState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    switch (state.status) {
      case PaywallStatus.loading:
        return const _PlanSkeleton();
      case PaywallStatus.unavailable:
        return Column(
          children: [
            Text(
              'Plans could not be loaded. Check your connection to the store '
              'and try again.',
              textAlign: TextAlign.center,
              style: ui.body(size: 14),
            ),
            const SizedBox(height: Space.s8),
            Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: ref.read(paywallControllerProvider.notifier).load,
                child: const Text('Try again'),
              ),
            ),
          ],
        );
      default:
        final demo = state.plans.any((p) => p.isDemo);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final plan in state.plans) ...[
              _PlanCard(
                plan: plan,
                selected: plan.id == state.selectedId,
                onTap: () => onSelect(plan.id),
              ),
              const SizedBox(height: Space.s12),
            ],
            if (demo)
              Text(
                'Demo prices (debug build). Real prices come from the store.',
                textAlign: TextAlign.center,
                style: ui.body(size: 12, color: c.textTertiary),
              ),
          ],
        );
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SadhakPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    final yearly = plan.kind == PlanKind.yearly;
    final title = yearly ? 'Yearly' : 'Lifetime';
    final badge = yearly ? 'Recommended' : 'One-time';
    final per = yearly ? ' / year' : '';
    final sub = yearly
        ? (plan.perMonth == null
              ? 'Renews every year'
              : 'Just ${plan.perMonth} a month')
        : 'Pay once, keep it for good';
    final duration = Motion.of(context).reduced
        ? AppDurations.instant
        : AppDurations.planSelect;

    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final price = Column(
      crossAxisAlignment: stacked
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          plan.price,
          style: ui.title.copyWith(
            fontSize: 22,
            color: selected ? c.accentText : c.textPrimary,
          ),
        ),
        if (per.isNotEmpty) Text(per.trim(), style: ui.body(size: 12)),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title, ${plan.price}$per, $badge. $sub',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: duration,
          curve: AppCurves.standard,
          constraints: const BoxConstraints(minHeight: Touch.minTarget),
          padding: const EdgeInsets.all(Space.s16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(
              color: selected ? c.accent : c.hairline,
              width: selected ? PaywallMetrics.selectedBorder : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: p.glow,
                      blurRadius: PaywallMetrics.glowBlur,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              _Radio(selected: selected, duration: duration),
              const SizedBox(width: Space.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Space.s8,
                      runSpacing: Space.s4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: ui.label(size: 17)),
                        _Badge(text: badge, strong: yearly),
                      ],
                    ),
                    const SizedBox(height: Space.s4),
                    Text(sub, style: ui.body(size: 14)),
                    // Large text: the price moves under the title.
                    if (stacked) ...[const SizedBox(height: Space.s8), price],
                  ],
                ),
              ),
              if (!stacked) ...[const SizedBox(width: Space.s8), price],
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.duration});

  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedContainer(
      duration: duration,
      width: PaywallMetrics.radioSize,
      height: PaywallMetrics.radioSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.accent : Colors.transparent,
        border: Border.all(
          color: selected ? c.accent : c.textTertiary,
          width: 1.5,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutBack,
        child: Icon(LucideIcons.check, size: 14, color: c.onAccent),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.strong});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s8, vertical: 2),
      decoration: BoxDecoration(
        color: strong ? c.accentSoft : p.goldSoft,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        text,
        style: UiStyles(c).label(size: 12, color: c.accentText),
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget block() => Container(
      height: Touch.minTarget + Space.s32,
      margin: const EdgeInsets.only(bottom: Space.s12),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    );
    return Semantics(
      label: 'Loading plans',
      child: Shimmer(
        base: c.surfaceSoft,
        highlight: c.surface.withValues(alpha: 0.6),
        textMode: false,
        child: Column(children: [block(), block()]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom panel: the one action, honest terms and the links.

class _BottomPanel extends ConsumerWidget {
  const _BottomPanel({required this.state, required this.compact});

  final PaywallState state;

  /// Large text: only the button here; terms and links scroll above.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final controller = ref.read(paywallControllerProvider.notifier);
    final canBuy = state.selected != null && !state.busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Space.readingSide,
            Space.s12,
            Space.readingSide,
            compact ? Space.s12 : Space.s4,
          ),
          child: ContentWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ContinueButton(
                  label: switch (state.status) {
                    PaywallStatus.pending => 'Waiting for confirmation',
                    PaywallStatus.restoring => 'Restoring',
                    _ => 'Continue',
                  },
                  busy: state.busy,
                  onPressed: canBuy ? controller.buy : null,
                ),
                if (!compact) _TermsAndLinks(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Honest renewal terms, then Restore, Terms and Privacy.
class _TermsAndLinks extends ConsumerWidget {
  const _TermsAndLinks({required this.state});

  final PaywallState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final controller = ref.read(paywallControllerProvider.notifier);
    final plan = state.selected;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final store = ios ? 'your App Store settings' : 'Google Play';
    final terms = plan == null
        ? ''
        : plan.kind == PlanKind.yearly
        ? 'Renews every year at ${plan.price} until you cancel. Cancel any '
              'time in $store.'
        : 'One payment of ${plan.price}. No renewal.';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (terms.isNotEmpty) ...[
          const SizedBox(height: Space.s8),
          Text(
            terms,
            textAlign: TextAlign.center,
            style: ui.body(size: 12, color: c.textTertiary),
          ),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: state.busy ? null : controller.restore,
              child: const Text('Restore purchase'),
            ),
            if (AppLinks.termsUrl.isNotEmpty)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(AppLinks.termsUrl)),
                child: const Text('Terms'),
              ),
            if (AppLinks.privacyUrl.isNotEmpty)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(AppLinks.privacyUrl)),
                child: const Text('Privacy'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    this.shimmer = true,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final bool shimmer;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final enabled = widget.onPressed != null;
    final motion = Motion.of(context);
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down && !motion.reduced ? 0.97 : 1,
          duration: AppDurations.instant,
          child: AnimatedOpacity(
            opacity: enabled || widget.busy ? 1 : 0.5,
            duration: AppDurations.fast,
            child: Container(
              height: PaywallMetrics.ctaHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.pill),
                gradient: LinearGradient(colors: [c.accent, p.gold]),
                boxShadow: [
                  BoxShadow(
                    color: p.glow,
                    blurRadius: PaywallMetrics.glowBlur * 0.6,
                    offset: const Offset(0, Space.s8),
                  ),
                ],
              ),
              child: widget.busy
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: IconSizes.small - 2,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.onAccent,
                          ),
                        ),
                        const SizedBox(width: Space.s12),
                        Flexible(child: _label(c)),
                      ],
                    )
                  : _label(c),
            ),
          ),
        ),
      ),
    );
    if (!enabled || !widget.shimmer) return button;
    return Shimmer(
      base: c.accent,
      highlight: Colors.white.withValues(alpha: 0.28),
      textMode: false,
      child: button,
    );
  }

  Widget _label(AppColors c) => Text(
    widget.label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: UiStyles(c).label(size: 17, color: c.onAccent),
  );
}

// ---------------------------------------------------------------------------
// Welcome (after buying, or when Sadhak is already active).

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    super.key,
    required this.justBought,
    required this.onClose,
  });

  final bool justBought;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return _HeroScroll(
      children: [
        // The bloom opens in the centre of the mandala.
        const SizedBox(
          height: PaywallMetrics.heroHeight - Touch.minTarget,
          child: Center(child: LotusBloom()),
        ),
        const SizedBox(height: Space.s24),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            justBought ? 'Welcome, Sadhak' : 'You are a Sadhak',
            textAlign: TextAlign.center,
            style: ui.title,
          ),
        ),
        const SizedBox(height: Space.s8),
        Text(
          justBought
              ? 'Thank you for supporting this quiet, offline Gita. '
                    'Everything in Sadhak is now open to you.'
              : 'Sadhak is active on this account. Thank you for your '
                    'support.',
          textAlign: TextAlign.center,
          style: ui.body(size: 16),
        ),
        const SizedBox(height: Space.s32),
        _ContinueButton(
          label: justBought ? 'Begin' : 'Close',
          busy: false,
          onPressed: onClose,
          shimmer: false,
        ),
        SizedBox(height: Space.s24 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}
