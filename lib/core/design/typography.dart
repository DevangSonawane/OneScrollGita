import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class Fonts {
  static const literata = 'Literata';
  static const devanagari = 'NotoSerifDevanagari';
  static const tiro = 'TiroDevanagariSanskrit';
  static const inter = 'Inter';

  /// Chosen Sanskrit face. Compare both on the specimen screen and record
  /// the decision in docs/typography.md.
  static const sanskrit = devanagari;
}

/// Variable fonts: set the weight axis explicitly as well as fontWeight.
TextStyle _weighted(TextStyle s, FontWeight w) => s.copyWith(
  fontWeight: w,
  fontVariations: [FontVariation('wght', w.value.toDouble())],
);

const _devanagariLocale = Locale('hi');

/// Reading styles. [scale] is the reading text-size step (0.85 to 1.25),
/// applied on top of the system text scale.
class ReadingStyles {
  ReadingStyles(this.colors, this.scale);

  final AppColors colors;
  final double scale;

  TextStyle get sanskrit => _weighted(
    TextStyle(
      fontFamily: Fonts.sanskrit,
      fontSize: 26 * scale,
      height: 1.75,
      color: colors.textPrimary,
      locale: _devanagariLocale,
    ),
    FontWeight.w500,
  );

  TextStyle get transliteration => _weighted(
    TextStyle(
      fontFamily: Fonts.literata,
      fontStyle: FontStyle.italic,
      fontSize: 16 * scale,
      height: 1.6,
      color: colors.textSecondary,
    ),
    FontWeight.w400,
  );

  TextStyle translation(String lang) => lang == 'hi'
      ? _weighted(
          TextStyle(
            fontFamily: Fonts.devanagari,
            fontSize: 19 * scale,
            height: 1.7,
            color: colors.textPrimary,
            locale: _devanagariLocale,
          ),
          FontWeight.w400,
        )
      : _weighted(
          TextStyle(
            fontFamily: Fonts.literata,
            fontSize: 19 * scale,
            height: 1.55,
            color: colors.textPrimary,
          ),
          FontWeight.w400,
        );

  TextStyle purport(String lang) => _weighted(
    TextStyle(
      fontFamily: lang == 'hi' ? Fonts.devanagari : Fonts.literata,
      fontSize: 18 * scale,
      height: 1.7,
      color: colors.textPrimary,
      locale: lang == 'hi' ? _devanagariLocale : null,
    ),
    FontWeight.w400,
  );

  TextStyle get purportSanskrit => _weighted(
    TextStyle(
      fontFamily: Fonts.sanskrit,
      fontSize: 20 * scale,
      height: 1.75,
      color: colors.textPrimary,
      locale: _devanagariLocale,
    ),
    FontWeight.w500,
  );
}

/// UI and title styles (not affected by the reading text-size setting).
class UiStyles {
  UiStyles(this.colors);

  final AppColors colors;

  TextStyle get title => _weighted(
    TextStyle(
      fontFamily: Fonts.literata,
      fontSize: 28,
      height: 1.25,
      color: colors.textPrimary,
    ),
    FontWeight.w600,
  );

  TextStyle get emptyTitle => _weighted(
    TextStyle(
      fontFamily: Fonts.literata,
      fontSize: 22,
      height: 1.3,
      color: colors.textPrimary,
    ),
    FontWeight.w600,
  );

  TextStyle get reference => _weighted(
    TextStyle(
      fontFamily: Fonts.inter,
      fontSize: 13,
      letterSpacing: 0.4,
      color: colors.textSecondary,
    ),
    FontWeight.w500,
  );

  TextStyle get overline => _weighted(
    TextStyle(
      fontFamily: Fonts.inter,
      fontSize: 12,
      letterSpacing: 1.0,
      color: colors.accentText,
    ),
    FontWeight.w600,
  );

  TextStyle label({Color? color, double size = 15}) => _weighted(
    TextStyle(
      fontFamily: Fonts.inter,
      fontSize: size,
      height: 1.3,
      color: color ?? colors.textPrimary,
    ),
    FontWeight.w500,
  );

  TextStyle body({Color? color, double size = 15}) => _weighted(
    TextStyle(
      fontFamily: Fonts.inter,
      fontSize: size,
      height: 1.45,
      color: color ?? colors.textSecondary,
    ),
    FontWeight.w400,
  );
}

TextTheme buildTextTheme(AppColors c) {
  final ui = UiStyles(c);
  return TextTheme(
    headlineMedium: ui.title,
    titleLarge: ui.emptyTitle,
    titleMedium: ui.label(size: 16),
    titleSmall: ui.label(size: 14),
    bodyLarge: ui.body(color: c.textPrimary, size: 16),
    bodyMedium: ui.body(size: 15),
    bodySmall: ui.body(size: 13),
    labelLarge: ui.label(size: 15),
    labelMedium: ui.label(size: 13),
    labelSmall: ui.label(size: 12),
  );
}
