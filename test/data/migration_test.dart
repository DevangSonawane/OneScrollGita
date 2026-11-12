import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/user/activity_repository.dart';
import 'package:versescroll/data/user/database.dart';
import 'package:versescroll/data/user/study_repository.dart';
import 'package:versescroll/domain/models/study_items.dart';

void main() {
  test('schema v1 database upgrades to v3 and keeps v1 data', () async {
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
    expect(v.data.values.first, 3);
  });

  test(
    'schema v2 database upgrades to v3, keeps v2 data, study layer works',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final sql in const [
              'CREATE TABLE favourites (verse_id TEXT NOT NULL PRIMARY KEY, created_at_ms INTEGER NOT NULL)',
              'CREATE TABLE bookmarks (verse_id TEXT NOT NULL PRIMARY KEY, created_at_ms INTEGER NOT NULL)',
              'CREATE TABLE history (verse_id TEXT NOT NULL PRIMARY KEY, last_read_at_ms INTEGER NOT NULL)',
              'CREATE TABLE read_days (date TEXT NOT NULL PRIMARY KEY, verse_count INTEGER NOT NULL, first_read_at TEXT NOT NULL)',
              'CREATE TABLE read_day_verses (date TEXT NOT NULL, verse_id TEXT NOT NULL, PRIMARY KEY (date, verse_id))',
              'CREATE TABLE notif_assignments (date TEXT NOT NULL, slot TEXT NOT NULL, message_id TEXT NOT NULL, verse_id TEXT NULL, PRIMARY KEY (date, slot))',
              'CREATE TABLE search_history ("query" TEXT NOT NULL PRIMARY KEY, last_used_at TEXT NOT NULL)',
              "INSERT INTO read_days VALUES ('2026-11-10', 3, '2026-11-10T08:00:00')",
              'PRAGMA user_version = 2',
            ]) {
              raw.execute(sql);
            }
          },
        ),
      );
      addTearDown(db.close);
      final days = await ActivityRepository(db).readDays();
      expect(days.single.verseCount, 3);
      final study = StudyRepository(db, clock: () => DateTime(2026, 11, 12));
      await study.setHighlight('bg-02-047', HighlightColor.leaf);
      await study.saveNote('bg-02-047', 'Act without attachment.');
      expect(
        (await study.watchHighlights().first).single.color,
        HighlightColor.leaf,
      );
      expect((await study.note('bg-02-047'))!.body, 'Act without attachment.');
      final v = await db.customSelect('PRAGMA user_version').getSingle();
      expect(v.data.values.first, 3);
    },
  );

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
