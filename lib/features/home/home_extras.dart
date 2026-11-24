import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_providers.dart';
import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/search_providers.dart';
import '../../core/config/audio_config.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/premium.dart';
import '../common/common_widgets.dart';
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

/// The owner's banner artwork (2026-11-24), cropped from
/// assets/sadhak_banners.png and assets/shravan_banners.png.
abstract final class BannerAssets {
  static const sadhak = 'assets/banners/sadhak.jpg';
  static const shravan = 'assets/banners/shravan.jpg';
}

class PlanBanners extends ConsumerStatefulWidget {
  const PlanBanners({super.key});

  static const sadhakKey = ValueKey('bannerSadhak');
  static const shravanKey = ValueKey('bannerShravan');

  @override
  ConsumerState<PlanBanners> createState() => _PlanBannersState();
}

class _PlanBannersState extends ConsumerState<PlanBanners> {
  final _controller = PageController(viewportFraction: BannerMetrics.viewport);
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
    final sadhak = ref.watch(isPremiumProvider);
    final shravan =
        ref.watch(shravanEntitlementProvider) == Entitlement.premium;
    final banners = <Widget>[
      _Banner(
        key: PlanBanners.sadhakKey,
        image: BannerAssets.sadhak,
        semanticLabel: sadhak
            ? 'Sadhak. Study. Reflect. Open the shloka trainer.'
            : 'Sadhak. Study. Reflect. See the Sadhak plan.',
        onTap: () => sadhak ? openTrainerHome(context) : openPaywall(context),
      ),
      if (AudioConfig.enabled)
        _Banner(
          key: PlanBanners.shravanKey,
          image: BannerAssets.shravan,
          semanticLabel: shravan
              ? 'Shravan. Listen to the Gita. Open Listen.'
              : 'Shravan. Listen to the Gita. See the Shravan plan.',
          onTap: () =>
              shravan ? context.go('/listen') : openShravanPaywall(context),
        ),
    ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            // The artwork keeps its own shape; text scaling does not apply.
            height:
                (box.maxWidth * BannerMetrics.viewport - Space.s8) /
                BannerMetrics.aspect,
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
                      child: b,
                    ),
                ],
              ),
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

/// One plan banner: the owner's artwork (assets/banners), tappable as a
/// whole. The words are part of the picture, so the label carries them.
class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.image,
    required this.semanticLabel,
    required this.onTap,
  });

  final String image;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      radius: Radii.card,
      semanticLabel: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: Elevation.soft(c),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card),
          child: ExcludeSemantics(
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feelings: wide cards with a 3D icon and the word under it, swiped by hand.

/// The owner's 3D feeling icons (2026-11-24), trimmed from assets/3dicons.
abstract final class FeelingArt {
  static const peace = 'assets/feelings/peace.png';
  static const stress = 'assets/feelings/stress.png';
  static const confusion = 'assets/feelings/confusion.png';
  static const anger = 'assets/feelings/anger.png';
  static const motivation = 'assets/feelings/motivation.png';
}

/// One feeling: the dataset theme it opens, a short word and its 3D icon.
/// The short words are written content: reviewed:false until the owner
/// checks them (docs/review-needed.md).
typedef Feeling = ({String themeId, String word, String art});

/// Only the feelings with artwork; the header's "See all" opens the rest.
const List<Feeling> homeFeelings = [
  (themeId: 'peace', word: 'Peace', art: FeelingArt.peace),
  (themeId: 'stress', word: 'Stress', art: FeelingArt.stress),
  (themeId: 'confusion', word: 'Confusion', art: FeelingArt.confusion),
  (themeId: 'anger', word: 'Anger', art: FeelingArt.anger),
  (themeId: 'motivation', word: 'Motivation', art: FeelingArt.motivation),
];

class FeelingCards extends ConsumerWidget {
  const FeelingCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final themes = ref.watch(themesProvider).value ?? const [];
    final items = [
      for (final f in homeFeelings)
        if (themes.where((t) => t.id == f.themeId).firstOrNull case final t?)
          (feeling: f, query: t.title.of(lang), hindi: lang == 'hi'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    // The word grows with the text size; the icon keeps its size.
    final scale = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: FeelingMetrics.maxTextScale)
        .scale(1);
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
              FeelingMetrics.height +
              FeelingMetrics.word * (scale - 1) * 1.3 +
              Space.s8,
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
              return MediaQuery.withClampedTextScaling(
                maxScaleFactor: FeelingMetrics.maxTextScale,
                child: _FeelingCard(
                  // Hindi readers see the dataset's Hindi theme title.
                  word: it.hindi ? it.query : it.feeling.word,
                  art: it.feeling.art,
                  onTap: () => openSearch(context, query: it.query),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A wide card: the 3D icon on the left, the word below it.
class _FeelingCard extends StatelessWidget {
  const _FeelingCard({
    required this.word,
    required this.art,
    required this.onTap,
  });

  final String word;
  final String art;
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
        width: FeelingMetrics.width,
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
            SizedBox.square(
              dimension: FeelingMetrics.icon,
              child: Image.asset(art, fit: BoxFit.contain),
            ),
            Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ui
                  .label(size: FeelingMetrics.word)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
