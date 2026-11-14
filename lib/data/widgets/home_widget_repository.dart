import 'dart:convert';

import 'package:home_widget/home_widget.dart';

/// Writes what the home-screen widgets show. The widgets are native
/// (Android: android/app/src/main/kotlin/.../VerseWidgets.kt, iOS:
/// ios/VerseWidgets/VerseWidgets.swift) and read these keys. On iOS the data
/// goes through the shared App Group.
class HomeWidgetRepository {
  static const appGroupId = 'group.com.onescrollgita.app';
  static const kDaily = 'daily_verses';
  static const kDailyStamp = 'daily_verses_stamp';
  static const kHistory = 'history_items';

  static const _dailyProvider = 'com.example.versescroll.DailyVerseWidget';
  static const _historyProvider = 'com.example.versescroll.RecentWidget';

  /// iOS widget kinds (WidgetKit `kind`).
  static const _dailyIos = 'DailyVerseWidget';
  static const _historyIos = 'RecentWidget';

  Future<void>? _ready;

  /// Points home_widget at the App Group before the first read or write.
  Future<void> _init() => _ready ??= HomeWidget.setAppGroupId(appGroupId);

  /// What the daily list was built for (`firstDate|lang|count`).
  Future<String?> dailyStamp() async {
    await _init();
    return HomeWidget.getWidgetData<String>(kDailyStamp);
  }

  /// [items]: one per day, `{date: yyyy-MM-dd, id, label, text}`.
  Future<void> saveDaily(List<Map<String, String>> items, String stamp) async {
    await _init();
    await HomeWidget.saveWidgetData(kDaily, jsonEncode(items));
    await HomeWidget.saveWidgetData(kDailyStamp, stamp);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _dailyProvider,
      iOSName: _dailyIos,
    );
  }

  /// [items]: newest first, `{id, label, text}`.
  Future<void> saveHistory(List<Map<String, String>> items) async {
    await _init();
    await HomeWidget.saveWidgetData(kHistory, jsonEncode(items));
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _historyProvider,
      iOSName: _historyIos,
    );
  }
}
