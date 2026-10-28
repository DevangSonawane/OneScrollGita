import 'package:drift/drift.dart';

import '../../domain/models/user_items.dart';
import 'database.dart';

/// Favourites, bookmarks and reading history in SQLite.
class UserDataRepository {
  UserDataRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const historyCap = 200;

  final AppDatabase _db;
  final DateTime Function() _clock;

  Stream<List<SavedItem>> watchFavourites() {
    final q = _db.select(_db.favourites)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          SavedItem(
            verseId: r.verseId,
            at: DateTime.fromMillisecondsSinceEpoch(r.createdAtMs),
          ),
      ],
    );
  }

  Stream<List<SavedItem>> watchBookmarks() {
    final q = _db.select(_db.bookmarks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          SavedItem(
            verseId: r.verseId,
            at: DateTime.fromMillisecondsSinceEpoch(r.createdAtMs),
          ),
      ],
    );
  }

  Stream<List<SavedItem>> watchHistory() {
    final q = _db.select(_db.history)
      ..orderBy([(t) => OrderingTerm.desc(t.lastReadAtMs)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          SavedItem(
            verseId: r.verseId,
            at: DateTime.fromMillisecondsSinceEpoch(r.lastReadAtMs),
          ),
      ],
    );
  }

  Future<void> setFavourite(String id, bool value, {DateTime? at}) => value
      ? _db
            .into(_db.favourites)
            .insertOnConflictUpdate(
              FavouritesCompanion.insert(
                verseId: id,
                createdAtMs: (at ?? _clock()).millisecondsSinceEpoch,
              ),
            )
      : (_db.delete(_db.favourites)..where((t) => t.verseId.equals(id))).go();

  Future<void> setBookmark(String id, bool value, {DateTime? at}) => value
      ? _db
            .into(_db.bookmarks)
            .insertOnConflictUpdate(
              BookmarksCompanion.insert(
                verseId: id,
                createdAtMs: (at ?? _clock()).millisecondsSinceEpoch,
              ),
            )
      : (_db.delete(_db.bookmarks)..where((t) => t.verseId.equals(id))).go();

  /// One row per verse; the newest visit wins; capped at [historyCap].
  Future<void> recordHistory(String id) => _db.transaction(() async {
    await _db
        .into(_db.history)
        .insertOnConflictUpdate(
          HistoryCompanion.insert(
            verseId: id,
            lastReadAtMs: _clock().millisecondsSinceEpoch,
          ),
        );
    await _db.customStatement(
      'DELETE FROM history WHERE verse_id NOT IN '
      '(SELECT verse_id FROM history ORDER BY last_read_at_ms DESC LIMIT ?)',
      [historyCap],
    );
  });

  Future<void> clearHistory() => _db.delete(_db.history).go();

  Future<void> resetAll() => _db.transaction(() async {
    await _db.delete(_db.favourites).go();
    await _db.delete(_db.bookmarks).go();
    await _db.delete(_db.history).go();
  });

  /// Every verse id referenced by user data.
  Future<Set<String>> allReferencedIds() async {
    final ids = <String>{};
    ids.addAll((await _db.select(_db.favourites).get()).map((r) => r.verseId));
    ids.addAll((await _db.select(_db.bookmarks).get()).map((r) => r.verseId));
    ids.addAll((await _db.select(_db.history).get()).map((r) => r.verseId));
    return ids;
  }

  /// Removes rows whose ids no longer exist in the dataset.
  Future<int> purgeOrphans(Future<bool> Function(String id) exists) async {
    final orphans = <String>[];
    for (final id in await allReferencedIds()) {
      if (!await exists(id)) orphans.add(id);
    }
    if (orphans.isEmpty) return 0;
    await _db.transaction(() async {
      await (_db.delete(_db.favourites)..where((t) => t.verseId.isIn(orphans)))
          .go();
      await (_db.delete(_db.bookmarks)..where((t) => t.verseId.isIn(orphans)))
          .go();
      await (_db.delete(_db.history)..where((t) => t.verseId.isIn(orphans)))
          .go();
    });
    return orphans.length;
  }
}
