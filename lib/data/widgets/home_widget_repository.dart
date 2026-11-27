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
  static const kListen = 'listen_state';

  static const _dailyProvider = 'com.example.versescroll.DailyVerseWidget';
  static const _historyProvider = 'com.example.versescroll.RecentWidget';
  static const _listenProvider = 'com.example.versescroll.ListenWidget';

  /// iOS widget kinds (WidgetKit `kind`).
  static const _dailyIos = 'DailyVerseWidget';
  static const _historyIos = 'RecentWidget';
  static const _listenIos = 'ListenWidget';

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

  /// The Listen widgets (PRD_v11): `{chapter, title, label}` of the last
  /// place listened to. Nothing about purchases: the app decides on tap.
  Future<void> saveListen(Map<String, Object> state) async {
    await _init();
    await HomeWidget.saveWidgetData(kListen, jsonEncode(state));
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _listenProvider,
      iOSName: _listenIos,
    );
  }
}
