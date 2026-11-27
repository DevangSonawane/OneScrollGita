import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/widgets/home_widget_repository.dart';
import '../domain/verse_navigation.dart';
import '../domain/daily_verse.dart';
import '../domain/models/user_items.dart';
import 'audio_providers.dart';
import 'core_providers.dart';
import 'library_providers.dart';
import 'scripture_providers.dart';

final homeWidgetRepositoryProvider = Provider<HomeWidgetRepository>(
  (_) => HomeWidgetRepository(),
);

/// Keeps the home-screen widgets (Android and iOS) up to date: the verse of the day
/// (the next [dailyDays] days, so it changes at midnight without the app)
/// and the recently read verses.
final widgetSyncProvider = Provider<void>((ref) {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  final sync = _WidgetSync(ref);
  ref.listen(todayProvider, (_, _) => sync.daily(), fireImmediately: true);
  ref.listen(languageProvider, (_, _) {
    sync.daily();
    sync.history(ref.read(historyProvider).value);
    sync.listen();
  });
  // The Listen widgets (PRD_v11) show where listening stopped.
  ref.listen(
    audioControllerProvider.select((s) => s.track?.verseId),
    (_, _) => sync.listen(),
    fireImmediately: true,
  );
  ref.listen(
    historyProvider,
    (_, next) => sync.history(next.value),
    fireImmediately: true,
  );
  // "Continue reading" starts at the exact place the reader stopped
  // (PRD_v6 section 5), which can change without a new history entry.
  ref.listen(
    settingsProvider.select((s) => s.lastVerseId),
    (_, _) => sync.history(ref.read(historyProvider).value),
  );
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
      // The resume position first, then recent history without repeats.
      final resume = ref.read(settingsProvider).lastVerseId;
      final ids = <String>{?resume, for (final i in items) i.verseId};
      for (final id in ids) {
        final entry = await scripture.entryById(id);
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

  String? _listenSent;

  /// The last place listened to (or chapter 1): chapter, its title in the
  /// reading language (from the dataset) and the verse label.
  Future<void> listen() async {
    try {
      // What is loaded now (the saved place can lag a moment behind),
      // else where listening last stopped.
      final now = ref.read(audioControllerProvider);
      final saved = ref.read(audioControllerProvider.notifier).lastPlace;
      final live = now.kind == AudioKind.chapter && now.track != null;
      final verseId = live ? now.track!.verseId : saved?.verseId;
      final lang = ref.read(languageProvider);
      final v = verseId == null ? null : parseVerseId(verseId);
      final chapter = v?.chapter ?? saved?.chapter ?? 1;
      final index = await ref.read(scriptureRepositoryProvider).chapters();
      final state = <String, Object>{
        'chapter': chapter,
        'title': index.chapter(chapter).title(lang),
        'label': v == null
            ? ''
            : formatLabel(v.chapter, v.verseStart, v.verseEnd),
        'lang': lang,
      };
      final key = state.toString();
      if (key == _listenSent) return;
      _listenSent = key;
      await _widgets.saveListen(state);
    } catch (_) {
      // A widget that is a little out of date is fine.
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
