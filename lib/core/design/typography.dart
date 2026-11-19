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

/// Verse text sizes before the reading scale (PRD_v5 section 3.1). One even
/// ramp, so shloka, transliteration and translation read as one family.
abstract final class ReadingType {
  static const shloka = 22.0;
  static const transliteration = 17.0;
  static const translation = 18.0;
  static const purport = 17.0;
  static const purportShloka = 19.0;
  static const wordMeaning = 16.0;
  static const trainerShloka = 24.0;
  static const trainerTransliteration = 21.0;
}

/// Reading styles. [scale] is the reading text-size step (0.85 to 1.25),
/// applied on top of the system text scale.
class ReadingStyles {
  ReadingStyles(this.colors, this.scale);

  final AppColors colors;
  final double scale;

  TextStyle get sanskrit => _weighted(
    TextStyle(
      fontFamily: Fonts.sanskrit,
      fontSize: ReadingType.shloka * scale,
      height: 1.6,
      color: colors.textPrimary,
      locale: _devanagariLocale,
    ),
    FontWeight.w500,
  );

  TextStyle get transliteration => _weighted(
    TextStyle(
      fontFamily: Fonts.literata,
      fontStyle: FontStyle.italic,
      fontSize: ReadingType.transliteration * scale,
      height: 1.55,
      color: colors.textSecondary,
    ),
    FontWeight.w400,
  );

  TextStyle translation(String lang) => lang == 'hi'
      ? _weighted(
          TextStyle(
            fontFamily: Fonts.devanagari,
            fontSize: ReadingType.translation * scale,
            height: 1.65,
            color: colors.textPrimary,
            locale: _devanagariLocale,
          ),
          FontWeight.w400,
        )
      : _weighted(
          TextStyle(
            fontFamily: Fonts.literata,
            fontSize: ReadingType.translation * scale,
            height: 1.5,
            color: colors.textPrimary,
          ),
          FontWeight.w400,
        );

  TextStyle purport(String lang) => _weighted(
    TextStyle(
      fontFamily: lang == 'hi' ? Fonts.devanagari : Fonts.literata,
      fontSize: ReadingType.purport * scale,
      height: 1.65,
      color: colors.textPrimary,
      locale: lang == 'hi' ? _devanagariLocale : null,
    ),
    FontWeight.w400,
  );

  /// Word-for-word list: the word as the source prints it (IAST italic, or
  /// Devanagari in some Hindi lists).
  TextStyle wordMeaningWord({required bool devanagari}) => devanagari
      ? _weighted(
          TextStyle(
            fontFamily: Fonts.devanagari,
            fontSize: ReadingType.wordMeaning * scale,
            height: 1.6,
            color: colors.textPrimary,
            locale: _devanagariLocale,
          ),
          FontWeight.w500,
        )
      : _weighted(
          TextStyle(
            fontFamily: Fonts.literata,
            fontStyle: FontStyle.italic,
            fontSize: ReadingType.wordMeaning * scale,
            height: 1.55,
            color: colors.textPrimary,
          ),
          FontWeight.w500,
        );

  /// Word-for-word list: the meaning.
  TextStyle wordMeaningText(String lang) => _weighted(
    TextStyle(
      fontFamily: lang == 'hi' ? Fonts.devanagari : Fonts.literata,
      fontSize: ReadingType.wordMeaning * scale,
      height: lang == 'hi' ? 1.6 : 1.55,
      color: colors.textSecondary,
      locale: lang == 'hi' ? _devanagariLocale : null,
    ),
    FontWeight.w400,
  );

  /// Shloka trainer words, larger for memorising.
  TextStyle trainerWord({required bool devanagari}) => devanagari
      ? _weighted(
          TextStyle(
            fontFamily: Fonts.sanskrit,
            fontSize: ReadingType.trainerShloka * scale,
            height: 1.7,
            color: colors.textPrimary,
            locale: _devanagariLocale,
          ),
          FontWeight.w500,
        )
      : _weighted(
          TextStyle(
            fontFamily: Fonts.literata,
            fontStyle: FontStyle.italic,
            fontSize: ReadingType.trainerTransliteration * scale,
            height: 1.6,
            color: colors.textPrimary,
          ),
          FontWeight.w500,
        );

  TextStyle get purportSanskrit => _weighted(
    TextStyle(
      fontFamily: Fonts.sanskrit,
      fontSize: ReadingType.purportShloka * scale,
      height: 1.6,
      color: colors.textPrimary,
      locale: _devanagariLocale,
    ),
    FontWeight.w500,
  );
}

/// Title sizes for display text outside reading (PRD_v5 stage V5-2).
abstract final class TitleSizes {
  /// Welcome screen title.
  static const hero = 38.0;

  /// Notebook PDF cover.
  static const cover = 30.0;

  /// Large section heading (Profile "Your library").
  static const section = 25.0;

  /// Streak number on the Profile card.
  static const stat = 36.0;

  /// Streak number on the completion share image.
  static const shareStat = 96.0;

  /// Choice cards and prices.
  static const card = 22.0;

  /// Small card titles and PDF chapter headings.
  static const cardSmall = 20.0;

  /// PDF verse headings.
  static const caption = 18.0;
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
