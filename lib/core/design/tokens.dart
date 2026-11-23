import 'package:flutter/material.dart';

/// Colour tokens (PRD section 4). Some starting values were adjusted so every
/// text/background pair passes the contrast test in test/design/.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceSoft,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentSoft,
    required this.danger,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color surfaceSoft;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color accentSoft;
  final Color danger;
  final Color shadow;

  static const light = AppColors(
    bg: Color(0xFFFBF8F3),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF4EFE7),
    hairline: Color(0xFFE8E1D6),
    textPrimary: Color(0xFF232120),
    textSecondary: Color(0xFF5F5850), // was #6B645C
    textTertiary: Color(0xFF706960), // was #9A9288 (2.9:1)
    accent: Color(0xFFD2691E),
    onAccent: Color(0xFF1F130A),
    accentText: Color(0xFFA04A12), // was #A94E14 (4.45:1 on accentSoft)
    accentSoft: Color(0xFFF6E3D2),
    danger: Color(0xFFB3261E),
    shadow: Color(0x14000000), // 8% black
  );

  static const dark = AppColors(
    bg: Color(0xFF14110F),
    surface: Color(0xFF1D1915),
    surfaceSoft: Color(0xFF26211C),
    hairline: Color(0xFF342E27),
    textPrimary: Color(0xFFEDE6DC),
    textSecondary: Color(0xFFB5ACA0),
    textTertiary: Color(0xFF9A9184), // was #8A8277
    accent: Color(0xFFE39A5E),
    onAccent: Color(0xFF14110F),
    accentText: Color(0xFFE39A5E),
    accentSoft: Color(0xFF3A2A1E),
    danger: Color(0xFFF2B8B5),
    shadow: Color(0x66000000), // 40% black
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceSoft: l(surfaceSoft, other.surfaceSoft),
      hairline: l(hairline, other.hairline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentText: l(accentText, other.accentText),
      accentSoft: l(accentSoft, other.accentSoft),
      danger: l(danger, other.danger),
      shadow: l(shadow, other.shadow),
    );
  }
}

abstract final class Space {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  /// Side padding of reading screens on phones.
  static const readingSide = 24.0;

  /// Reading column max width (also tablets).
  static const contentMaxWidth = 600.0;

  /// Horizontal dead zone at the reader edges (Android back gesture).
  static const edgeDeadZone = 16.0;

  static const paragraph = 14.0;
}

abstract final class Radii {
  static const chip = 8.0;
  static const input = 12.0;
  static const card = 20.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

abstract final class IconSizes {
  static const small = 20.0;
  static const regular = 24.0;
  static const large = 28.0;
}

abstract final class Touch {
  static const minTarget = 48.0;
  static const pillHeight = 44.0;
}

abstract final class AppDurations {
  static const instant = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
  static const navHide = Duration(milliseconds: 200);
  static const savePulse = Duration(milliseconds: 200);
  static const droplet = Duration(milliseconds: 380);
  static const stagger = Duration(milliseconds: 60);
  static const positionDebounce = Duration(milliseconds: 600);
  static const historyDwell = Duration(seconds: 2);
  static const undo = Duration(seconds: 5);

  /// "Good work" popup auto-dismiss (PRD_v2 section 4).
  static const streakPopup = Duration(seconds: 4);

  /// Search typing debounce (PRD_v2 section 10).
  static const searchDebounce = Duration(milliseconds: 250);

  // Sadhak paywall (all ambient loops stop under reduced motion).
  static const paywallEntrance = Duration(milliseconds: 1400);
  static const auraCycle = Duration(seconds: 24);
  static const mandalaTurn = Duration(seconds: 120);
  static const sparkRise = Duration(seconds: 11);
  static const shimmer = Duration(milliseconds: 3200);
  static const bloom = Duration(milliseconds: 1600);
  static const planSelect = Duration(milliseconds: 280);

  // Study layer and trainer.
  static const noteAutosave = Duration(milliseconds: 600);
  static const wordReveal = Duration(milliseconds: 220);

  // Shravan player.
  static const soundWave = Duration(milliseconds: 900);
  static const breathe = Duration(milliseconds: 4200);
}

abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const position = Curves.easeInOutCubic;
}

abstract final class Elevation {
  static List<BoxShadow> soft(AppColors c) => [
    BoxShadow(color: c.shadow, offset: const Offset(0, 8), blurRadius: 24),
  ];
}

/// Floating glass menu (reader overflow).
abstract final class GlassMenuMetrics {
  static const width = 232.0;
  static const rowHeight = 52.0;
  static const gap = 8.0;

  /// Scale the menu grows from when it opens (1 under reduced motion).
  static const openScale = 0.92;
}

/// Streak card and share card sizes.
abstract final class StreakMetrics {
  static const dot = 10.0;
  static const bigNumber = 44.0;

  /// 1080 x 1350 at pixel ratio 3.
  static const shareCardSize = Size(360, 450);
}

/// Navigation pill geometry.
/// "Go to verse" sheet (PRD_v7 section 3).
abstract final class GoToMetrics {
  static const tileWidth = 132.0;
  static const tileHeight = 104.0;
  static const chip = 56.0;
}

/// Home (PRD_v5 section 5).
abstract final class HomeMetrics {
  static const greeting = 26.0;
  static const progress = 6.0;

  /// The Continue button above the nav pill.
  static const continueHeight = 52.0;
}

/// Reader page behaviour.
abstract final class ReaderMetrics {
  /// Deliberate over-pull, from a drag that starts at a long verse's edge,
  /// that turns the page. Momentum from a flick never turns it.
  static const pullToTurn = 40.0;

  /// A flick at the edge this fast (logical px/s) turns even when short.
  static const flickVelocity = 700.0;

  /// The least pull past the edge a quick flick needs.
  static const flickPull = 8.0;

  /// A release at least this fast (px/s) counts as a swipe to the next or
  /// previous verse; slower releases settle by position.
  static const snapVelocity = 550.0;

  /// A swipe must move the text at least this far (px) to turn a verse.
  static const swipeMinDistance = 24.0;

  /// How close to an edge still counts as "at the edge".
  static const edgeSlop = 2.0;

  /// Height of the "more below" fade above the nav area.
  static const moreFade = 72.0;
}

abstract final class NavBarMetrics {
  /// Taller since v7: each tab shows its name under the icon.
  static const height = 58.0;
  static const icon = 22.0;
  static const labelSize = 11.0;
  static const maxWidth = 300.0;
  static const sideMargin = 20.0;
  static const bottomGap = 8.0;
  static const minTabWidth = 48.0;
}

/// Every tunable of the glass look in one place, light and dark.
@immutable
class GlassTokens {
  const GlassTokens({
    required this.refractionHeight,
    required this.refractionAmount,
    required this.frost,
    required this.tintOpacity,
    required this.highlight,
    required this.borderOpacity,
    required this.frostedBlur,
    required this.lightFrost,
    required this.lightTintOpacity,
  });

  final double refractionHeight;
  final double refractionAmount;
  final double frost;

  /// Fraction of `surface` mixed into the glass so labels stay readable.
  final double tintOpacity;
  final double highlight;
  final double borderOpacity;

  /// Blur sigma of the frosted (BackdropFilter) fallback.
  final double frostedBlur;

  /// "Light" glass used for the reader top row and purport controls.
  final double lightFrost;
  final double lightTintOpacity;

  static const light = GlassTokens(
    refractionHeight: 18,
    refractionAmount: 48,
    frost: 6,
    tintOpacity: 0.62,
    highlight: 0.8,
    borderOpacity: 0.5,
    frostedBlur: 20,
    lightFrost: 4,
    lightTintOpacity: 0.55,
  );

  static const dark = GlassTokens(
    refractionHeight: 18,
    refractionAmount: 48,
    frost: 7,
    tintOpacity: 0.66,
    highlight: 0.6,
    borderOpacity: 0.35,
    frostedBlur: 20,
    lightFrost: 5,
    lightTintOpacity: 0.6,
  );

  static GlassTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Sadhak (premium) look: warm gold on the existing saffron palette.
/// Decorative colours only; text keeps the AppColors text tokens.
@immutable
class PremiumColors {
  const PremiumColors({
    required this.gold,
    required this.goldSoft,
    required this.glow,
    required this.auraA,
    required this.auraB,
    required this.cardTop,
    required this.cardBottom,
  });

  final Color gold;
  final Color goldSoft;

  /// Soft saffron glow behind the selected plan and the lotus.
  final Color glow;

  /// The two drifting light sources of the hero aura.
  final Color auraA;
  final Color auraB;

  /// The Profile "Sadhak" card gradient.
  final Color cardTop;
  final Color cardBottom;

  static const light = PremiumColors(
    gold: Color(0xFFC08A2C),
    goldSoft: Color(0xFFF3E3BF),
    glow: Color(0x40E58A3C),
    auraA: Color(0x66F2B26B),
    auraB: Color(0x4DE9C78A),
    cardTop: Color(0xFFF8E7D2),
    cardBottom: Color(0xFFF2D9BC),
  );

  static const dark = PremiumColors(
    gold: Color(0xFFE2B866),
    goldSoft: Color(0xFF3A2D18),
    glow: Color(0x40E39A5E),
    auraA: Color(0x40E39A5E),
    auraB: Color(0x33D9B26A),
    cardTop: Color(0xFF2E2219),
    cardBottom: Color(0xFF221A14),
  );

  static PremiumColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Sadhak paywall geometry.
/// The paywall figure (PRD_v6 section 3).
abstract final class FigureMetrics {
  /// One breath; the reading figure turns a page at the end of each.
  static const cycle = Duration(milliseconds: 6400);
  static const minHeight = 96.0;
  static const minHeightShort = 56.0;
  static const maxHeight = 230.0;
  static const motes = 7;
  static const waves = 3;
}

abstract final class PaywallMetrics {
  /// One-screen paywall sizes (PRD_v6 section 3).
  static const nameSize = 30.0;
  static const headline = 23.0;
  static const price = 19.0;

  /// Below this screen height the paywall uses its compact layout.
  static const shortScreen = 740.0;
  static const heroHeight = 280.0;
  static const mandalaSize = 260.0;
  static const lotusIcon = 44.0;
  static const titleSize = 52.0;
  static const ctaHeight = 56.0;
  static const benefitIcon = 30.0;
  static const radioSize = 22.0;
  static const sparkCount = 22;
  static const selectedBorder = 2.0;
  static const glowBlur = 28.0;
  static const entranceRise = 18.0;
  static const bloomPetals = 8;
  static const bloomSize = 180.0;
}

/// Guided first launch and the sign-up step (owner, 2026-11-22).
abstract final class OnboardingMetrics {
  /// Step titles and the app name on the first step.
  static const title = 24.0;
  static const heroTitle = 32.0;
  static const ctaHeight = 52.0;
  static const providerHeight = 52.0;
  static const providerLogo = 20.0;
  static const heroArt = 220.0;
  static const heroArtShort = 150.0;
  static const lotus = 52.0;
  static const lotusSmall = 48.0;
  static const statNumber = 22.0;
  static const benefitIcon = 40.0;
  static const dayNumber = 72.0;
  static const entranceRise = 14.0;

  /// Below this height the hero art shrinks.
  static const shortScreen = 720.0;

  /// The feature demos (scrolling, Sadhak, Shravan).
  static const demoCard = 340.0;
  static const playButton = 68.0;
  static const playRing = 3.0;
  static const blankMinWidth = 44.0;
  static const hintBounce = Duration(milliseconds: 1400);

  /// The whole staggered entrance of one step.
  static const entrance = Duration(milliseconds: 900);
}

/// Chunky 3D buttons and icon tiles (owner, 2026-11-23).
abstract final class TactileMetrics {
  /// How far the face sits above its base; it sinks to 0 when pressed.
  static const depth = 4.0;
  static const radius = 14.0;
  static const press = Duration(milliseconds: 70);
  static const shake = Duration(milliseconds: 360);
  static const iconTile = 56.0;
  static const iconGlyph = 28.0;
}

/// Feeling cards on Home: one gentle hue per card, top and bottom of the
/// icon tile's gradient.
@immutable
class FeelingPalette {
  const FeelingPalette(this.top, this.bottom);

  final Color top;
  final Color bottom;

  static const light = [
    FeelingPalette(Color(0xFFFFD59E), Color(0xFFF29A4A)), // saffron
    FeelingPalette(Color(0xFFB9E4F7), Color(0xFF4FA3D9)), // sky
    FeelingPalette(Color(0xFFD9C9F5), Color(0xFF8E6BD6)), // lilac
    FeelingPalette(Color(0xFFC6EBC9), Color(0xFF52B06A)), // leaf
    FeelingPalette(Color(0xFFFFC9C4), Color(0xFFE2675B)), // rose
    FeelingPalette(Color(0xFFFFE9A8), Color(0xFFE0B23A)), // gold
  ];

  static const dark = [
    FeelingPalette(Color(0xFFF2B26B), Color(0xFFB8621E)),
    FeelingPalette(Color(0xFF7CC3E8), Color(0xFF2E6F9E)),
    FeelingPalette(Color(0xFFB29BE6), Color(0xFF5E43A3)),
    FeelingPalette(Color(0xFF8FD39C), Color(0xFF2F7A44)),
    FeelingPalette(Color(0xFFF29A90), Color(0xFFA8433A)),
    FeelingPalette(Color(0xFFF2D27A), Color(0xFFA67E1E)),
  ];

  static List<FeelingPalette> of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// The Shravan banner on Home: a deep night-blue card with light text,
/// the same in light and dark mode (text on it is at least 4.5:1).
abstract final class ShravanBannerColors {
  static const top = Color(0xFF2B2350);
  static const bottom = Color(0xFF4B3B7F);
  static const text = Color(0xFFFFFFFF);
  static const textSoft = Color(0xCCFFFFFF);
}

/// Home's auto-scrolling plan banners.
abstract final class BannerMetrics {
  static const height = 156.0;
  static const art = 112.0;
  static const interval = Duration(seconds: 4);
  static const slide = Duration(milliseconds: 600);
  static const maxTextScale = 1.3;
  static const title = 19.0;
  static const feelingCardWidth = 112.0;
  static const feelingCardHeight = 120.0;
}

/// Third-party brand marks, used only inside their own logos and buttons
/// (Sign in with Apple and Google branding guidelines).
abstract final class BrandColors {
  static const appleBlack = Color(0xFF000000);
  static const appleWhite = Color(0xFFFFFFFF);
  static const googleBlue = Color(0xFF4285F4);
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC05);
  static const googleGreen = Color(0xFF34A853);

  /// Google's light button: white fill, #747775 stroke, #1F1F1F text.
  static const googleLightFill = Color(0xFFFFFFFF);
  static const googleLightStroke = Color(0xFF747775);
  static const googleLightText = Color(0xFF1F1F1F);

  /// Google's dark button: #131314 fill, #8E918F stroke, #E3E3E3 text.
  static const googleDarkFill = Color(0xFF131314);
  static const googleDarkStroke = Color(0xFF8E918F);
  static const googleDarkText = Color(0xFFE3E3E3);
}

/// Highlight colours: a soft band behind the translation (text keeps
/// `textPrimary`, at least 4.5:1, see test/design/contrast_test.dart) and a
/// stronger swatch for pickers and list markers.
@immutable
class HighlightColors {
  const HighlightColors(this.bands, this.swatches);

  /// saffron, leaf, sky, lotus (in `HighlightColor` order).
  final List<Color> bands;
  final List<Color> swatches;

  static const light = HighlightColors(
    [
      Color(0xFFFBE3CC),
      Color(0xFFDDEFD9),
      Color(0xFFDCE9F7),
      Color(0xFFF6DDE8),
    ],
    [
      Color(0xFFD2691E),
      Color(0xFF4F8A4B),
      Color(0xFF3D7CC0),
      Color(0xFFC0577F),
    ],
  );

  static const dark = HighlightColors(
    [
      Color(0xFF43301F),
      Color(0xFF26372A),
      Color(0xFF22313F),
      Color(0xFF3E2633),
    ],
    [
      Color(0xFFE39A5E),
      Color(0xFF8CC487),
      Color(0xFF86B4E8),
      Color(0xFFE59AB8),
    ],
  );

  static HighlightColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Shloka trainer geometry.
abstract final class TrainerMetrics {
  /// Words in the 3D word bank under the verse.
  static const bankWord = 17.0;

  static const blankMinWidth = 36.0;
  static const blankHeight = 30.0;
  static const stepDot = 8.0;
  static const stepDotActive = 22.0;
}

/// Shravan audio: Listen pill, mini player and full player.
/// Verse share image.
abstract final class ShareCardMetrics {
  /// Verse text relative to the reader ramp (shloka 22 -> 20).
  static const verseTextFactor = 20 / 22;
}

abstract final class PlayerMetrics {
  /// Verse text in the player, relative to the reader (keeps the ramp).
  static const verseTextFactor = 0.86;

  /// The Listen pill: icon only on narrow screens, icon + label otherwise.
  static const pillCompact = 64.0;
  static const pillWide = 116.0;
  static const pillGap = 8.0;

  /// Wide pill only when the screen is at least this wide.
  static const wideFrom = 380.0;

  static const miniHeight = 64.0;
  static const miniTile = 44.0;
  static const miniGap = 8.0;
  static const progressLine = 2.0;

  static const art = 180.0;
  static const artNumeral = 48.0;
  static const playButton = 60.0;
  static const scrubberHeight = 24.0;
  static const tickHeight = 8.0;
  static const chapterTile = 40.0;
  static const waveBar = 3.0;
  static const waveHeight = 18.0;
}
