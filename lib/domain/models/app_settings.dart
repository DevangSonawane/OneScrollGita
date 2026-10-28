enum AppThemeMode { system, light, dark }

/// Text-size steps for reading text (Small to Extra large).
const readingScaleSteps = <double>[0.85, 0.92, 1.0, 1.12, 1.25];
const defaultTextScaleStep = 2;

class AppSettings {
  const AppSettings({
    this.languageCode = 'en',
    this.themeMode = AppThemeMode.system,
    this.textScaleStep = defaultTextScaleStep,
    this.lastVerseId,
    this.firstLaunchDone = false,
    this.simplifiedGlass = false,
  });

  final String languageCode;
  final AppThemeMode themeMode;
  final int textScaleStep;
  final String? lastVerseId;
  final bool firstLaunchDone;
  final bool simplifiedGlass;

  double get readingScale => readingScaleSteps[textScaleStep];

  AppSettings copyWith({
    String? languageCode,
    AppThemeMode? themeMode,
    int? textScaleStep,
    String? lastVerseId,
    bool clearLastVerseId = false,
    bool? firstLaunchDone,
    bool? simplifiedGlass,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode ?? this.themeMode,
    textScaleStep: textScaleStep ?? this.textScaleStep,
    lastVerseId: clearLastVerseId ? null : (lastVerseId ?? this.lastVerseId),
    firstLaunchDone: firstLaunchDone ?? this.firstLaunchDone,
    simplifiedGlass: simplifiedGlass ?? this.simplifiedGlass,
  );
}
