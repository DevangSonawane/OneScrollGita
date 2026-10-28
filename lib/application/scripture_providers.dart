import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/daily_verse.dart';
import '../domain/models/chapter.dart';
import '../domain/models/verse_entry.dart';
import 'core_providers.dart';

final chaptersIndexProvider = FutureProvider<ChaptersIndex>(
  (ref) => ref.watch(scriptureRepositoryProvider).chapters(),
);

final chapterEntriesProvider = FutureProvider.autoDispose
    .family<List<VerseEntry>, int>((ref, chapter) async {
      final repo = ref.watch(scriptureRepositoryProvider);
      final entries = await repo.chapterEntries(chapter);
      return entries;
    });

final entryProvider = FutureProvider.autoDispose.family<VerseEntry?, String>(
  (ref, id) => ref.watch(scriptureRepositoryProvider).entryById(id),
);

/// Today's local date. Changes at local midnight and when [refresh] is
/// called (on app resume).
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final now = ref.watch(clockProvider)();
    _schedule(now);
    return DateTime(now.year, now.month, now.day);
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), refresh);
  }

  void refresh() {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    _schedule(now);
    if (today != state) state = today;
  }
}

final dailyEntryProvider = FutureProvider<VerseEntry>((ref) async {
  final day = ref.watch(todayProvider);
  final repo = ref.watch(scriptureRepositoryProvider);
  final index = await repo.chapters();
  final i = dailyEntryIndex(day, index.totalEntries);
  return repo.entryAtGlobalIndex(i);
});
