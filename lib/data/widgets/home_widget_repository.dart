import 'dart:convert';

import 'package:home_widget/home_widget.dart';

/// Writes what the Android home-screen widgets show. The widgets are native
/// (android/app/src/main/kotlin/.../widgets) and read these keys.
class HomeWidgetRepository {
  static const kDaily = 'daily_verses';
  static const kDailyStamp = 'daily_verses_stamp';
  static const kHistory = 'history_items';

  static const _dailyProvider = 'com.example.versescroll.DailyVerseWidget';
  static const _historyProvider = 'com.example.versescroll.RecentWidget';

  /// What the daily list was built for (`firstDate|lang|count`).
  Future<String?> dailyStamp() =>
      HomeWidget.getWidgetData<String>(kDailyStamp);

  /// [items]: one per day, `{date: yyyy-MM-dd, id, label, text}`.
  Future<void> saveDaily(List<Map<String, String>> items, String stamp) async {
    await HomeWidget.saveWidgetData(kDaily, jsonEncode(items));
    await HomeWidget.saveWidgetData(kDailyStamp, stamp);
    await HomeWidget.updateWidget(qualifiedAndroidName: _dailyProvider);
  }

  /// [items]: newest first, `{id, label, text}`.
  Future<void> saveHistory(List<Map<String, String>> items) async {
    await HomeWidget.saveWidgetData(kHistory, jsonEncode(items));
    await HomeWidget.updateWidget(qualifiedAndroidName: _historyProvider);
  }
}
