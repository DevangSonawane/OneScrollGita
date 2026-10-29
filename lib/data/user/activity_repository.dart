import 'package:drift/drift.dart';

import '../../domain/local_date.dart';
import '../../domain/streak.dart';
import 'database.dart';

/// v2 user data: read days (streak), notification assignments and search
/// history. Kept apart from favourites/bookmarks/history.
class ActivityRepository {
  ActivityRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const searchHistoryCap = 20;

  final AppDatabase _db;
  final DateTime Function() _clock;

  // Read days ---------------------------------------------------------------

  Stream<List<ReadDay>> watchReadDays() => _db
      .select(_db.readDays)
      .watch()
      .map((rows) => [for (final r in rows) ReadDay(r.date, r.verseCount)]);

  Future<List<ReadDay>> readDays() async => [
    for (final r in await _db.select(_db.readDays).get())
      ReadDay(r.date, r.verseCount),
  ];

  /// Records a qualifying read of [verseId] on [date]. Returns true when
  /// this made [date] count for the first time.
  Future<bool> recordQualifyingRead(
    String date,
    String verseId,
  ) => _db.transaction(() async {
    final seen =
        await (_db.select(_db.readDayVerses)
              ..where((t) => t.date.equals(date) & t.verseId.equals(verseId)))
            .getSingleOrNull();
    if (seen != null) return false;
    await _db
        .into(_db.readDayVerses)
        .insert(ReadDayVersesCompanion.insert(date: date, verseId: verseId));
    final day = await (_db.select(
      _db.readDays,
    )..where((t) => t.date.equals(date))).getSingleOrNull();
    if (day == null) {
      await _db
          .into(_db.readDays)
          .insert(
            ReadDaysCompanion.insert(
              date: date,
              verseCount: 1,
              firstReadAt: _clock().toIso8601String(),
            ),
          );
      return true;
    }
    await (_db.update(_db.readDays)..where((t) => t.date.equals(date))).write(
      ReadDaysCompanion(verseCount: Value(day.verseCount + 1)),
    );
    return false;
  });

  // Notification assignments ------------------------------------------------

  Future<List<NotifAssignmentRow>> assignmentsSince(String date) => (_db.select(
    _db.notifAssignments,
  )..where((t) => t.date.isBiggerOrEqualValue(date))).get();

  Future<void> saveAssignments(Iterable<NotifAssignmentRow> rows) =>
      _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.notifAssignments, rows.toList());
      });

  /// Drops assignments older than [keepFrom] (they only matter for the
  /// 60-day no-repeat window).
  Future<void> pruneAssignments(String keepFrom) => (_db.delete(
    _db.notifAssignments,
  )..where((t) => t.date.isSmallerThanValue(keepFrom))).go();

  // Search history ----------------------------------------------------------

  Stream<List<String>> watchSearchHistory() {
    final q = _db.select(_db.searchHistory)
      ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]);
    return q.watch().map((rows) => [for (final r in rows) r.query]);
  }

  Future<void> addSearch(String query) => _db.transaction(() async {
    await _db
        .into(_db.searchHistory)
        .insertOnConflictUpdate(
          SearchHistoryCompanion.insert(
            query: query,
            lastUsedAt: _clock().toIso8601String(),
          ),
        );
    await _db.customStatement(
      'DELETE FROM search_history WHERE "query" NOT IN '
      '(SELECT "query" FROM search_history ORDER BY last_used_at DESC LIMIT ?)',
      [searchHistoryCap],
    );
  });

  Future<void> clearSearchHistory() => _db.delete(_db.searchHistory).go();

  /// Reset all saved data (PRD_v2 section 3).
  Future<void> resetAll() => _db.transaction(() async {
    await _db.delete(_db.readDays).go();
    await _db.delete(_db.readDayVerses).go();
    await _db.delete(_db.notifAssignments).go();
    await _db.delete(_db.searchHistory).go();
  });
}

/// Today's local date key from [clock].
String todayKey(DateTime Function() clock) => dateKey(clock());
