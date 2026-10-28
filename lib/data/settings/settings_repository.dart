import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/verse_navigation.dart';

/// Small settings in shared_preferences. Invalid or unknown stored values
/// fall back to defaults.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const kLanguage = 'languageCode';
  static const kTheme = 'themeMode';
  static const kTextScale = 'textScaleStep';
  static const kLastVerse = 'lastVerseId';
  static const kFirstLaunch = 'firstLaunchDone';
  static const kSimplifiedGlass = 'simplifiedGlass';

  AppSettings load() {
    const d = AppSettings();
    final lang = _get<String>(kLanguage);
    final theme = _get<String>(kTheme);
    final step = _get<int>(kTextScale);
    final last = _get<String>(kLastVerse);
    return AppSettings(
      languageCode: lang == 'en' || lang == 'hi' ? lang! : d.languageCode,
      themeMode: AppThemeMode.values
          .where((m) => m.name == theme)
          .firstOrNull ??
          d.themeMode,
      textScaleStep: step != null && step >= 0 && step < readingScaleSteps.length
          ? step
          : d.textScaleStep,
      lastVerseId: last != null && parseVerseId(last) != null ? last : null,
      firstLaunchDone: _get<bool>(kFirstLaunch) ?? false,
      simplifiedGlass: _get<bool>(kSimplifiedGlass) ?? false,
    );
  }

  T? _get<T>(String key) {
    final v = _prefs.get(key);
    return v is T ? v : null;
  }

  Future<void> setLanguage(String code) => _prefs.setString(kLanguage, code);
  Future<void> setThemeMode(AppThemeMode m) => _prefs.setString(kTheme, m.name);
  Future<void> setTextScaleStep(int s) => _prefs.setInt(kTextScale, s);
  Future<void> setFirstLaunchDone(bool v) => _prefs.setBool(kFirstLaunch, v);
  Future<void> setSimplifiedGlass(bool v) =>
      _prefs.setBool(kSimplifiedGlass, v);

  Future<void> setLastVerseId(String? id) => id == null
      ? _prefs.remove(kLastVerse)
      : _prefs.setString(kLastVerse, id);

  Future<void> clearAll() async {
    for (final k in const [
      kLanguage,
      kTheme,
      kTextScale,
      kLastVerse,
      kFirstLaunch,
      kSimplifiedGlass,
    ]) {
      await _prefs.remove(k);
    }
  }
}
