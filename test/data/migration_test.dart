import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/user/activity_repository.dart';
import 'package:versescroll/data/user/database.dart';

void main() {
  test('schema v1 database upgrades to v2 and keeps v1 data', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE favourites (verse_id TEXT NOT NULL PRIMARY KEY, created_at_ms INTEGER NOT NULL)',
          );
          raw.execute(
            'CREATE TABLE bookmarks (verse_id TEXT NOT NULL PRIMARY KEY, created_at_ms INTEGER NOT NULL)',
          );
          raw.execute(
            'CREATE TABLE history (verse_id TEXT NOT NULL PRIMARY KEY, last_read_at_ms INTEGER NOT NULL)',
          );
          raw.execute("INSERT INTO favourites VALUES ('bg-02-047', 1)");
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);
    final favs = await db.select(db.favourites).get();
    expect(favs.single.verseId, 'bg-02-047');

    final repo = ActivityRepository(db, clock: () => DateTime(2026, 3, 10));
    expect(await repo.recordQualifyingRead('2026-03-10', 'bg-02-047'), isTrue);
    expect(await repo.recordQualifyingRead('2026-03-10', 'bg-02-047'), isFalse);
    expect(await repo.recordQualifyingRead('2026-03-10', 'bg-02-048'), isFalse);
    final days = await repo.readDays();
    expect(days.single.verseCount, 2);
    await repo.addSearch('anger');
    expect(await repo.watchSearchHistory().first, ['anger']);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.data.values.first, 2);
  });

  test('reset clears v2 tables; search history capped at 20', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    var t = DateTime(2026, 3, 10);
    final repo = ActivityRepository(
      db,
      clock: () => t = t.add(const Duration(seconds: 1)),
    );
    for (var i = 0; i < 25; i++) {
      await repo.addSearch('q$i');
    }
    final history = await repo.watchSearchHistory().first;
    expect(history.length, ActivityRepository.searchHistoryCap);
    expect(history.first, 'q24');
    await repo.recordQualifyingRead('2026-03-10', 'bg-01-001');
    await repo.resetAll();
    expect(await repo.readDays(), isEmpty);
    expect(await repo.watchSearchHistory().first, isEmpty);
  });
}
