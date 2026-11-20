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
import '../../domain/shravan.dart';
import 'figure_art.dart';
import 'sadhak_art.dart';

/// Opens the Sadhak paywall, optionally explaining which locked feature led
/// here. Never opened on launch or on a timer (PRD_v3 section 3).
Future<void> openPaywall(BuildContext context, {PremiumFeature? reason}) =>
    context.push(reason == null ? '/sadhak' : '/sadhak?reason=${reason.name}');

/// Opens the Shravan (audio) paywall.
Future<void> openShravanPaywall(
  BuildContext context, {
  ListenFeature? reason,
}) => context.push(
  reason == null ? '/shravan' : '/shravan?reason=${reason.name}',
);

/// What one paywall sells: the same screen serves Sadhak and Shravan.
class PaywallOffer {
  const PaywallOffer({
    required this.package,
    required this.name,
    required this.devanagari,
    required this.headline,
    required this.subline,
    required this.benefits,
    required this.welcome,
    required this.pose,
  });

  /// The figure at the top of the paywall (PRD_v6 section 3).
  final FigurePose pose;

  final Package package;
  final String name;
  final String devanagari;
  final String headline;
  final String subline;
  final List<(IconData, String, String)> benefits;
  final String welcome;

  static const sadhak = PaywallOffer(
    package: Package.sadhak,
    name: 'Sadhak',
    devanagari: 'साधक',
    headline: 'Go deeper into the Gita',
    subline:
        'Carry the verses in your heart, and keep your own study beside them.',
    benefits: [
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
    ],
    welcome: 'Thank you for supporting this quiet Gita.',
    pose: FigurePose.reading,
  );

  static const shravan = PaywallOffer(
    package: Package.shravan,
    name: 'Shravan',
    devanagari: 'श्रवण',
    headline: 'Hear the Gita',
    subline: 'Let the verses be recited to you, wherever you are.',
    benefits: [
      (
        LucideIcons.headphones,
        'Every chapter, narrated',
        'Listen to each chapter told from beginning to end.',
      ),
      (
        LucideIcons.audio_lines,
        'Shlokas recited',
        'Hear each verse chanted in Sanskrit, verse by verse.',
      ),
      (
        LucideIcons.lock,
        'Plays with the screen off',
        'Keep listening from the lock screen or your earphones.',
      ),
      (
        LucideIcons.moon,
        'Sleep timer and repeat',
        'Fall asleep to a chapter, or repeat one verse to learn it.',
      ),
    ],
    welcome: 'Thank you for supporting this Gita.',
    pose: FigurePose.listening,
  );
}

class _OfferScope extends InheritedWidget {
  const _OfferScope({required this.offer, required super.child});

  final PaywallOffer offer;

  @override
  bool updateShouldNotify(_OfferScope old) => old.offer != offer;
}

PaywallOffer _offerOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_OfferScope>()?.offer ??
    PaywallOffer.sadhak;

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    this.reason,
    this.offer = PaywallOffer.sadhak,
    this.reasonText,
  });

  final PremiumFeature? reason;
  final PaywallOffer offer;

  /// The one-line reason, when it does not come from a [PremiumFeature].
  final String? reasonText;

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
    final offer = widget.offer;
    final state = ref.watch(paywallControllerProvider(offer.package));
    final premium =
        ref.watch(entitlementOf(offer.package)) == Entitlement.premium;
    final done = state.status == PaywallStatus.success;
    final motion = Motion.of(context);

    return _OfferScope(
      offer: offer,
      child: Scaffold(
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
                        reason: widget.reasonText ?? widget.reason?.reason,
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
      ),
    );
  }
}

/// Large text: only the button stays pinned; terms and links scroll.
bool _compactPanel(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.3;

/// One screen without scrolling when it fits (PRD_v6 section 3): the figure
/// takes whatever height is left, between [FigureMetrics.minHeight] and
/// [FigureMetrics.maxHeight]. Scrolls only when it cannot fit (large text,
/// very small phones), so layouts still survive text scale 2.0.
class _FitScroll extends StatelessWidget {
  const _FitScroll({
    required this.figure,
    required this.children,
    this.figureMin = FigureMetrics.minHeight,
  });

  final Widget figure;
  final List<Widget> children;
  final double figureMin;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + Touch.minTarget;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Space.readingSide,
                top - Space.s16,
                Space.readingSide,
                Space.s8,
              ),
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: figureMin),
                        child: figure,
                      ),
                    ),
                    ...children,
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
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    final offer = _offerOf(context);
    final benefits = offer.benefits;
    final state = ref.watch(paywallControllerProvider(offer.package));
    final controller = ref.read(
      paywallControllerProvider(offer.package).notifier,
    );
    final stagger = Motion.of(context).reduced ? 0.0 : 0.06;

    final compact = _compactPanel(context);
    // Short phones (iPhone SE): smaller figure, no subline, benefits in a
    // 2 x 2 grid, so the offer still fits one screen.
    final short =
        MediaQuery.sizeOf(context).height < PaywallMetrics.shortScreen;
    final benefitRows = [
      for (final (i, (icon, title, sub)) in benefits.indexed)
        _Reveal(
          animation: entrance,
          start: 0.24 + i * stagger,
          child: _BenefitRow(icon: icon, title: title, sub: sub),
        ),
    ];
    return Column(
      children: [
        Expanded(
          child: _FitScroll(
            figureMin: short
                ? FigureMetrics.minHeightShort
                : FigureMetrics.minHeight,
            figure: _Reveal(
              animation: entrance,
              start: 0,
              child: SeekerFigure(pose: offer.pose),
            ),
            children: [
              _Reveal(
                animation: entrance,
                start: 0.06,
                child: _Hero(premium: p, colors: c, short: short),
              ),
              if (reason != null) ...[
                const SizedBox(height: Space.s8),
                _Reveal(
                  animation: entrance,
                  start: 0.1,
                  child: Center(child: _ReasonChip(text: reason!)),
                ),
              ],
              SizedBox(height: short ? Space.s4 : Space.s12),
              _Reveal(
                animation: entrance,
                start: 0.14,
                child: Semantics(
                  header: true,
                  child: Text(
                    offer.headline,
                    textAlign: TextAlign.center,
                    style: ui.title.copyWith(fontSize: PaywallMetrics.headline),
                  ),
                ),
              ),
              if (!short) ...[
                const SizedBox(height: Space.s4),
                _Reveal(
                  animation: entrance,
                  start: 0.18,
                  child: Text(
                    offer.subline,
                    textAlign: TextAlign.center,
                    style: ui.body(size: 14),
                  ),
                ),
              ],
              SizedBox(height: short ? Space.s12 : Space.s16),
              if (short)
                for (var i = 0; i < benefitRows.length; i += 2)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: benefitRows[i]),
                      const SizedBox(width: Space.s8),
                      Expanded(
                        child: i + 1 < benefitRows.length
                            ? benefitRows[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
              else
                ...benefitRows,
              const SizedBox(height: Space.s4),
              _Reveal(
                animation: entrance,
                start: 0.24 + benefits.length * stagger,
                child: const _AlwaysFree(),
              ),
              SizedBox(height: short ? Space.s8 : Space.s16),
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

/// The package name: Devanagari with a soft shimmer, then the Latin name.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.premium,
    required this.colors,
    this.short = false,
  });

  final PremiumColors premium;
  final AppColors colors;

  /// Short phones: the Latin name is left out (the headline follows).
  final bool short;

  @override
  Widget build(BuildContext context) {
    final ui = UiStyles(colors);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: _offerOf(context).name,
          excludeSemantics: true,
          child: Shimmer(
            base: colors.accentText,
            highlight: premium.gold,
            child: Text(
              _offerOf(context).devanagari,
              style: ReadingStyles(colors, 1).sanskrit.copyWith(
                fontSize: PaywallMetrics.nameSize,
                height: 1.2,
              ),
            ),
          ),
        ),
        if (!short)
          Text(
            _offerOf(context).name.toUpperCase(),
            style: ui.overline.copyWith(color: colors.textSecondary),
          ),
      ],
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

/// One line per benefit on the paywall (PRD_v6 section 3). The longer
/// description stays available to screen readers.
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
    return Semantics(
      label: '$title. $sub',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s8),
        child: Row(
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
              child: Icon(icon, size: IconSizes.small - 4, color: c.accentText),
            ),
            const SizedBox(width: Space.s12),
            Expanded(child: Text(title, style: ui.label(size: 15))),
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
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s8,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.input),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.heart_handshake,
            size: IconSizes.small - 2,
            color: c.textSecondary,
          ),
          const SizedBox(width: Space.s12),
          Expanded(
            child: Text(
              'Every verse, translation, purport and word meaning stays free '
              'for everyone.',
              style: UiStyles(c).body(size: 12.5),
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
                onPressed: ref
                    .read(
                      paywallControllerProvider(_offerOf(context).package)
                          .notifier,
                    )
                    .load,
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
              const SizedBox(height: Space.s8),
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
    final trial = plan.trial;
    final sub = yearly
        ? (trial != null
              ? '${trial.label}, then ${plan.price} a year'
              : plan.perMonth == null
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
            fontSize: PaywallMetrics.price,
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
          padding: const EdgeInsets.symmetric(
            horizontal: Space.s16,
            vertical: Space.s12,
          ),
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
                        Text(title, style: ui.label(size: 16)),
                        _Badge(text: badge, strong: yearly),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(sub, style: ui.body(size: 13)),
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
    final controller = ref.read(
      paywallControllerProvider(_offerOf(context).package).notifier,
    );
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
            Space.s8,
            Space.readingSide,
            compact ? Space.s8 : 0,
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
                    _ when state.selected?.trial != null => 'Start free trial',
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
    final controller = ref.read(
      paywallControllerProvider(_offerOf(context).package).notifier,
    );
    final plan = state.selected;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final store = ios ? 'your App Store settings' : 'Google Play';
    final terms = plan == null
        ? ''
        : plan.kind == PlanKind.yearly && plan.trial != null
        ? '${plan.trial!.label}, then ${plan.price} a year until you '
              'cancel. Cancel before the trial ends in $store and you will '
              'not be charged.'
        : plan.kind == PlanKind.yearly
        ? 'Renews every year at ${plan.price} until you cancel. Cancel any '
              'time in $store.'
        : 'One payment of ${plan.price}. No renewal.';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (terms.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          Text(
            terms,
            textAlign: TextAlign.center,
            style: ui.body(size: 11.5, color: c.textTertiary),
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
    return _FitScroll(
      figure: SeekerFigure(pose: _offerOf(context).pose, animate: false),
      children: [
        const SizedBox(height: Space.s16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            justBought
                ? 'Welcome to ${_offerOf(context).name}'
                : '${_offerOf(context).name} is active',
            textAlign: TextAlign.center,
            style: ui.title,
          ),
        ),
        const SizedBox(height: Space.s8),
        Text(
          justBought
              ? '${_offerOf(context).welcome} Everything in '
                    '${_offerOf(context).name} is now open to you.'
              : '${_offerOf(context).name} is active on this account. '
                    'Thank you for your support.',
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
