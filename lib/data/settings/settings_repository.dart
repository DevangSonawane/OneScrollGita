import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/local_date.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/reminder_settings.dart';
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

  // v2 (PRD_v2 section 3).
  static const kRemindersEnabled = 'remindersEnabled';
  static const kReminderTime = 'reminderTime';
  static const kStreakNudgeEnabled = 'streakNudgeEnabled';
  static const kStreakNudgeTime = 'streakNudgeTime';
  static const kVerseNotifsEnabled = 'verseNotifsEnabled';
  static const kLastScheduleRebuildAt = 'lastScheduleRebuildAt';
  static const kStreakPopupShownDate = 'streakPopupShownDate';
  static const kMilestonesShown = 'milestonesShown';

  /// Last local date the app was opened (for the notification back-off).
  static const kLastOpenedDate = 'lastOpenedDate';

  static const _v2Keys = [
    kRemindersEnabled,
    kReminderTime,
    kStreakNudgeEnabled,
    kStreakNudgeTime,
    kVerseNotifsEnabled,
    kLastScheduleRebuildAt,
    kStreakPopupShownDate,
    kMilestonesShown,
    kLastOpenedDate,
  ];

  AppSettings load() {
    const d = AppSettings();
    final lang = _get<String>(kLanguage);
    final theme = _get<String>(kTheme);
    final step = _get<int>(kTextScale);
    final last = _get<String>(kLastVerse);
    return AppSettings(
      languageCode: lang == 'en' || lang == 'hi' ? lang! : d.languageCode,
      themeMode:
          AppThemeMode.values.where((m) => m.name == theme).firstOrNull ??
          d.themeMode,
      textScaleStep:
          step != null && step >= 0 && step < readingScaleSteps.length
          ? step
          : d.textScaleStep,
      lastVerseId: last != null && parseVerseId(last) != null ? last : null,
      firstLaunchDone: _get<bool>(kFirstLaunch) ?? false,
      simplifiedGlass: _get<bool>(kSimplifiedGlass) ?? false,
    );
  }

  ReminderSettings loadReminders() {
    const d = ReminderSettings();
    return ReminderSettings(
      remindersEnabled: _get<bool>(kRemindersEnabled) ?? d.remindersEnabled,
      reminderTime:
          TimeOfDayHm.tryParse(_get<String>(kReminderTime)) ?? d.reminderTime,
      streakNudgeEnabled:
          _get<bool>(kStreakNudgeEnabled) ?? d.streakNudgeEnabled,
      streakNudgeTime:
          TimeOfDayHm.tryParse(_get<String>(kStreakNudgeTime)) ??
          d.streakNudgeTime,
      verseNotifsEnabled:
          _get<bool>(kVerseNotifsEnabled) ?? d.verseNotifsEnabled,
    );
  }

  Future<void> saveReminders(ReminderSettings r) async {
    await _prefs.setBool(kRemindersEnabled, r.remindersEnabled);
    await _prefs.setString(kReminderTime, r.reminderTime.hm);
    await _prefs.setBool(kStreakNudgeEnabled, r.streakNudgeEnabled);
    await _prefs.setString(kStreakNudgeTime, r.streakNudgeTime.hm);
    await _prefs.setBool(kVerseNotifsEnabled, r.verseNotifsEnabled);
  }

  String? get streakPopupShownDate {
    final v = _get<String>(kStreakPopupShownDate);
    return v != null && parseDateKey(v) != null ? v : null;
  }

  Future<void> setStreakPopupShownDate(String date) =>
      _prefs.setString(kStreakPopupShownDate, date);

  Set<int> get milestonesShown {
    final v = _prefs.get(kMilestonesShown);
    if (v is! List) return {};
    return {for (final s in v) ?int.tryParse('$s')};
  }

  Future<void> addMilestoneShown(int n) =>
      _prefs.setStringList(kMilestonesShown, [
        for (final m in {...milestonesShown, n}) '$m',
      ]);

  String? get lastOpenedDate {
    final v = _get<String>(kLastOpenedDate);
    return v != null && parseDateKey(v) != null ? v : null;
  }

  Future<void> setLastOpenedDate(String date) =>
      _prefs.setString(kLastOpenedDate, date);

  DateTime? get lastScheduleRebuildAt =>
      DateTime.tryParse(_get<String>(kLastScheduleRebuildAt) ?? '');

  Future<void> setLastScheduleRebuildAt(DateTime at) =>
      _prefs.setString(kLastScheduleRebuildAt, at.toIso8601String());

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

  Future<void> setLastVerseId(String? id) =>
      id == null ? _prefs.remove(kLastVerse) : _prefs.setString(kLastVerse, id);

  Future<void> clearAll() async {
    for (final k in const [
      kLanguage,
      kTheme,
      kTextScale,
      kLastVerse,
      kFirstLaunch,
      kSimplifiedGlass,
      ..._v2Keys,
    ]) {
      await _prefs.remove(k);
    }
  }
}
