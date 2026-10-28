import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/widgets/home_widget_repository.dart';
import '../domain/daily_verse.dart';
import '../domain/models/user_items.dart';
import 'core_providers.dart';
import 'library_providers.dart';
import 'scripture_providers.dart';

final homeWidgetRepositoryProvider = Provider<HomeWidgetRepository>(
  (_) => HomeWidgetRepository(),
);

/// Keeps the Android home-screen widgets up to date: the verse of the day
/// (the next [dailyDays] days, so it changes at midnight without the app)
/// and the recently read verses.
final widgetSyncProvider = Provider<void>((ref) {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final sync = _WidgetSync(ref);
  ref.listen(todayProvider, (_, _) => sync.daily(), fireImmediately: true);
  ref.listen(languageProvider, (_, _) {
    sync.daily();
    sync.history(ref.read(historyProvider).value);
  });
  ref.listen(historyProvider, (_, next) => sync.history(next.value));
});

const dailyDays = 30;
const _historyCount = 4;

class _WidgetSync {
  _WidgetSync(this.ref);

  final Ref ref;
  Future<void>? _dailyRun;

  HomeWidgetRepository get _widgets => ref.read(homeWidgetRepositoryProvider);

  void daily() => _dailyRun = (_dailyRun ?? Future.value()).then(
    (_) => _syncDaily().catchError((Object _) {}),
  );

  Future<void> _syncDaily() async {
    final today = ref.read(todayProvider);
    final lang = ref.read(languageProvider);
    final stamp = '${_date(today)}|$lang|$dailyDays';
    if (await _widgets.dailyStamp() == stamp) return;
    final scripture = ref.read(scriptureRepositoryProvider);
    final total = (await scripture.chapters()).totalEntries;
    final items = <Map<String, String>>[];
    for (var d = 0; d < dailyDays; d++) {
      final day = DateTime(today.year, today.month, today.day + d);
      final entry = await scripture.entryAtGlobalIndex(
        dailyEntryIndex(day, total),
      );
      items.add({
        'date': _date(day),
        'id': entry.id,
        'label': entry.label,
        'text': entry.translation(lang),
      });
    }
    await _widgets.saveDaily(items, stamp);
  }

  Future<void> history(List<SavedItem>? items) async {
    if (items == null) return;
    try {
      final scripture = ref.read(scriptureRepositoryProvider);
      final lang = ref.read(languageProvider);
      final out = <Map<String, String>>[];
      for (final item in items) {
        final entry = await scripture.entryById(item.verseId);
        if (entry == null) continue;
        out.add({
          'id': entry.id,
          'label': entry.label,
          'text': entry.translation(lang),
        });
        if (out.length == _historyCount) break;
      }
      await _widgets.saveHistory(out);
    } catch (_) {
      // A widget that is a little out of date is fine.
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
