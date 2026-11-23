import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_providers.dart';
import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/search_providers.dart';
import '../../core/config/audio_config.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tactile.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/premium.dart';
import '../common/common_widgets.dart';
import '../premium/figure_art.dart';
import '../premium/paywall_screen.dart';
import '../trainer/trainer_entry.dart';

/// "Hi, Devang" with "How are you?" under it (owner, 2026-11-23). The name
/// is the account's first name; without one it is "Hi there".
class HomeGreeting extends ConsumerWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final name = ref.watch(currentUserProvider)?.name?.trim() ?? '';
    final first = name.isEmpty ? null : name.split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s24,
        Space.readingSide,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              first == null ? 'Hi there' : 'Hi, $first',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ui.title.copyWith(fontSize: HomeMetrics.greeting),
            ),
          ),
          const SizedBox(height: Space.s4),
          Text('How are you?', style: ui.body(size: 16)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan banners: Sadhak and Shravan, sliding by themselves.

class PlanBanners extends ConsumerStatefulWidget {
  const PlanBanners({super.key});

  static const sadhakKey = ValueKey('bannerSadhak');
  static const shravanKey = ValueKey('bannerShravan');

  @override
  ConsumerState<PlanBanners> createState() => _PlanBannersState();
}

class _PlanBannersState extends ConsumerState<PlanBanners> {
  final _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;
  bool _touching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the banners stay put and only move when swiped.
    if (Motion.of(context).reduced) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(BannerMetrics.interval, (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || _touching || !_controller.hasClients) return;
    final count = _count;
    if (count < 2) return;
    _controller.animateToPage(
      (_page + 1) % count,
      duration: BannerMetrics.slide,
      curve: AppCurves.position,
    );
  }

  int get _count => AudioConfig.enabled ? 2 : 1;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final sadhak = ref.watch(isPremiumProvider);
    final shravan =
        ref.watch(shravanEntitlementProvider) == Entitlement.premium;
    final banners = <Widget>[
      _Banner(
        key: PlanBanners.sadhakKey,
        badge: 'SADHAK',
        title: sadhak ? 'Keep learning by heart' : 'Learn shlokas by heart',
        line: sadhak
            ? 'Open the shloka trainer.'
            : 'Trainer, notes, highlights and your notebook.',
        action: sadhak ? 'Open' : 'Explore',
        top: p.cardTop,
        bottom: p.cardBottom,
        text: c.textPrimary,
        textSoft: c.textSecondary,
        accent: c.accent,
        onAccent: c.onAccent,
        art: const SeekerFigure(pose: FigurePose.reading),
        onTap: () => sadhak ? openTrainerHome(context) : openPaywall(context),
      ),
      if (AudioConfig.enabled)
        _Banner(
          key: PlanBanners.shravanKey,
          badge: 'SHRAVAN',
          title: shravan ? 'Listen today' : 'Hear every shloka',
          line: shravan
              ? 'Pick up where you left off.'
              : 'Sanskrit recitation with the translation.',
          action: shravan ? 'Listen' : 'Explore',
          top: ShravanBannerColors.top,
          bottom: ShravanBannerColors.bottom,
          text: ShravanBannerColors.text,
          textSoft: ShravanBannerColors.textSoft,
          accent: p.gold,
          onAccent: ShravanBannerColors.top,
          art: const SeekerFigure(pose: FigurePose.listening),
          onTap: () =>
              shravan ? context.go('/listen') : openShravanPaywall(context),
        ),
    ];
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: BannerMetrics.maxTextScale)
              .scale(BannerMetrics.height),
          child: Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) => _touching = false,
            onPointerCancel: (_) => _touching = false,
            child: PageView(
              controller: _controller,
              padEnds: true,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final b in banners)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s4),
                    // Banner text grows up to 1.3x, so the card keeps its
                    // shape; the paywall behind it follows the full size.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: BannerMetrics.maxTextScale,
                      child: b,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: Space.s8),
          Semantics(
            label: 'Banner ${_page + 1} of ${banners.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: Motion.of(context).crossFade,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _page
                        ? TrainerMetrics.stepDotActive - 6
                        : TrainerMetrics.stepDot - 2,
                    height: TrainerMetrics.stepDot - 2,
                    decoration: BoxDecoration(
                      color: i == _page ? c.accent : c.hairline,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.badge,
    required this.title,
    required this.line,
    required this.action,
    required this.top,
    required this.bottom,
    required this.text,
    required this.textSoft,
    required this.accent,
    required this.onAccent,
    required this.art,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String line;
  final String action;
  final Color top;
  final Color bottom;
  final Color text;
  final Color textSoft;
  final Color accent;
  final Color onAccent;
  final Widget art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Pressable(
      onTap: onTap,
      radius: Radii.card,
      semanticLabel: '$badge. $title. $line',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
          ),
          boxShadow: [
            BoxShadow(
              color: bottom.withValues(alpha: 0.35),
              blurRadius: Space.s16,
              offset: const Offset(0, Space.s8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -Space.s8,
              bottom: -Space.s8,
              width: BannerMetrics.art,
              height: BannerMetrics.art + Space.s16,
              child: art,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s16,
                Space.s16,
                BannerMetrics.art - Space.s16,
                Space.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge, style: ui.overline.copyWith(color: accent)),
                  const SizedBox(height: Space.s4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ui.title.copyWith(
                      fontSize: BannerMetrics.title,
                      height: 1.15,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: Space.s4),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ui.body(size: 13, color: textSoft),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.s12,
                      vertical: Space.s4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            action,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ui.label(size: 13, color: onAccent),
                          ),
                        ),
                        const SizedBox(width: Space.s4),
                        Icon(
                          LucideIcons.arrow_right,
                          size: IconSizes.small - 6,
                          color: onAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feelings: short words with a raised icon, swiped by hand.

/// One feeling: the dataset theme it opens, a short word and an icon.
/// The short words are written content: reviewed:false until the owner
/// checks them (docs/review-needed.md).
typedef Feeling = ({String themeId, String word, IconData icon});

const List<Feeling> homeFeelings = [
  (themeId: 'peace', word: 'Peace', icon: LucideIcons.leaf),
  (themeId: 'stress', word: 'Stress', icon: LucideIcons.wind),
  (themeId: 'confusion', word: 'Confusion', icon: LucideIcons.signpost),
  (themeId: 'sadness', word: 'Sadness', icon: LucideIcons.cloud_rain),
  (themeId: 'anger', word: 'Anger', icon: LucideIcons.flame),
  (themeId: 'fear', word: 'Fear', icon: LucideIcons.shield),
  (themeId: 'loneliness', word: 'Lonely', icon: LucideIcons.users),
  (themeId: 'motivation', word: 'Motivation', icon: LucideIcons.zap),
  (themeId: 'grief', word: 'Grief', icon: LucideIcons.heart_crack),
  (themeId: 'doubt', word: 'Doubt', icon: LucideIcons.circle_question_mark),
];

class FeelingCards extends ConsumerWidget {
  const FeelingCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final themes = ref.watch(themesProvider).value ?? const [];
    final palettes = FeelingPalette.of(context);
    final items = [
      for (final f in homeFeelings)
        if (themes.where((t) => t.id == f.themeId).firstOrNull case final t?)
          (feeling: f, query: t.title.of(lang), hindi: lang == 'hi'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Find a verse for',
                  style: ui
                      .label(size: 17)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => openSearch(context),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height:
              BannerMetrics.feelingCardHeight * scale.clamp(1, 1.6) +
              TactileMetrics.depth * 3,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.readingSide,
              vertical: Space.s4,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.s12),
            itemBuilder: (context, i) {
              final it = items[i];
              return _FeelingCard(
                // Hindi readers see the dataset's Hindi theme title.
                word: it.hindi ? it.query : it.feeling.word,
                icon: it.feeling.icon,
                palette: palettes[i % palettes.length],
                onTap: () => openSearch(context, query: it.query),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeelingCard extends StatelessWidget {
  const _FeelingCard({
    required this.word,
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final String word;
  final IconData icon;
  final FeelingPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Pressable(
      onTap: onTap,
      radius: Radii.card,
      semanticLabel: 'Verses for $word',
      child: Container(
        width: BannerMetrics.feelingCardWidth,
        padding: const EdgeInsets.all(Space.s12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon3D(icon: icon, palette: palette),
            Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ui.label(size: 15).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
