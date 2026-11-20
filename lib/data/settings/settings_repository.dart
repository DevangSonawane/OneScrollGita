import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/local_date.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/reminder_settings.dart';
import '../../domain/premium.dart';
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

  /// v5: the first-launch answer ("What brings you to the Gita?").
  static const kFirstIntent = 'firstIntent';
  static const kSimplifiedGlass = 'simplifiedGlass';

  /// v9: show the sign-up page once after first launch (new installs only).
  static const kAccountStepPending = 'accountStepPending';

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

  // v3 (PRD_v3 section 4). Not cleared by "Reset all saved data": the store
  // holds the purchase, and "Restore purchase" always brings it back.
  static const kEntitlementCache = 'entitlementCache';
  static const kEntitlementCheckedAt = 'entitlementCheckedAt';

  /// Shloka trainer script: `latin` (default) or `devanagari`.
  static const kTrainerScript = 'trainerScript';

  /// Shravan: where the listener stopped (`chapter|verseId`).
  static const kLastAudioPlace = 'lastAudioPlace';

  /// Debug builds only ("Pretend premium"); ignored in release.
  static const kPretendPremium = 'debugPretendPremium';

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
    kTrainerScript,
    kLastAudioPlace,
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
      accountStepPending: _get<bool>(kAccountStepPending) ?? false,
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

  Entitlement get entitlementCache =>
      _get<String>(kEntitlementCache) == Entitlement.premium.name
      ? Entitlement.premium
      : Entitlement.free;

  DateTime? get entitlementCheckedAt =>
      DateTime.tryParse(_get<String>(kEntitlementCheckedAt) ?? '');

  Future<void> setEntitlementCache(Entitlement e, DateTime at) async {
    await _prefs.setString(kEntitlementCache, e.name);
    await _prefs.setString(kEntitlementCheckedAt, at.toIso8601String());
  }

  bool get trainerDevanagari => _get<String>(kTrainerScript) == 'devanagari';

  Future<void> setTrainerDevanagari(bool v) =>
      _prefs.setString(kTrainerScript, v ? 'devanagari' : 'latin');

  String? get lastAudioPlace => _get<String>(kLastAudioPlace);

  Future<void> setLastAudioPlace(String v) =>
      _prefs.setString(kLastAudioPlace, v);

  // Shravan (PRD_v4): its own purchase, same rules as Sadhak.
  static const kShravanCache = 'shravanEntitlementCache';
  static const kShravanCheckedAt = 'shravanEntitlementCheckedAt';
  static const kPretendShravan = 'debugPretendShravan';

  /// The cached purchase for [p] (kept by "Reset all saved data").
  Entitlement cacheFor(Package p) => p == Package.sadhak
      ? entitlementCache
      : (_get<String>(kShravanCache) == Entitlement.premium.name
            ? Entitlement.premium
            : Entitlement.free);

  Future<void> setCacheFor(Package p, Entitlement e, DateTime at) async {
    if (p == Package.sadhak) return setEntitlementCache(e, at);
    await _prefs.setString(kShravanCache, e.name);
    await _prefs.setString(kShravanCheckedAt, at.toIso8601String());
  }

  bool pretendFor(Package p) => p == Package.sadhak
      ? pretendPremium
      : (_get<bool>(kPretendShravan) ?? false);

  Future<void> setPretendFor(Package p, bool v) => p == Package.sadhak
      ? setPretendPremium(v)
      : _prefs.setBool(kPretendShravan, v);

  bool get pretendPremium => _get<bool>(kPretendPremium) ?? false;

  Future<void> setPretendPremium(bool v) => _prefs.setBool(kPretendPremium, v);

  T? _get<T>(String key) {
    final v = _prefs.get(key);
    return v is T ? v : null;
  }

  Future<void> setLanguage(String code) => _prefs.setString(kLanguage, code);
  Future<void> setThemeMode(AppThemeMode m) => _prefs.setString(kTheme, m.name);
  Future<void> setTextScaleStep(int s) => _prefs.setInt(kTextScale, s);
  Future<void> setFirstLaunchDone(bool v) => _prefs.setBool(kFirstLaunch, v);
  String? get firstIntent => _get<String>(kFirstIntent);
  Future<void> setFirstIntent(String v) => _prefs.setString(kFirstIntent, v);
  Future<void> setSimplifiedGlass(bool v) =>
      _prefs.setBool(kSimplifiedGlass, v);
  Future<void> setAccountStepPending(bool v) =>
      _prefs.setBool(kAccountStepPending, v);

  Future<void> setLastVerseId(String? id) =>
      id == null ? _prefs.remove(kLastVerse) : _prefs.setString(kLastVerse, id);

  Future<void> clearAll() async {
    for (final k in const [
      kLanguage,
      kTheme,
      kTextScale,
      kLastVerse,
      kFirstLaunch,
      kFirstIntent,
      kSimplifiedGlass,
      kAccountStepPending,
      ..._v2Keys,
    ]) {
      await _prefs.remove(k);
    }
  }
}
