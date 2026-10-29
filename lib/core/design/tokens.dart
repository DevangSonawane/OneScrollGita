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
abstract final class NavBarMetrics {
  static const height = 52.0;
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
