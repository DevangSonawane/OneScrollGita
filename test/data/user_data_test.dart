import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/data/user/database.dart';
import 'package:versescroll/data/user/user_data_repository.dart';
import 'package:versescroll/domain/models/app_settings.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('UserDataRepository', () {
    late AppDatabase db;
    late UserDataRepository repo;
    var now = DateTime(2026, 10, 28, 9);

    setUp(() {
      db = AppDatabase.memory();
      now = DateTime(2026, 10, 28, 9);
      repo = UserDataRepository(db, clock: () => now);
    });
    tearDown(() => db.close());

    test('favourites and bookmarks are separate', () async {
      await repo.setFavourite('bg-02-047', true);
      expect((await repo.watchFavourites().first).map((e) => e.verseId), ['bg-02-047']);
      expect(await repo.watchBookmarks().first, isEmpty);
      await repo.setBookmark('bg-02-047', true);
      await repo.setFavourite('bg-02-047', false);
      expect(await repo.watchFavourites().first, isEmpty);
      expect((await repo.watchBookmarks().first).single.verseId, 'bg-02-047');
    });

    test('favourites are newest first and persist the time', () async {
      await repo.setFavourite('bg-01-001', true);
      now = now.add(const Duration(minutes: 1));
      await repo.setFavourite('bg-01-002', true);
      final list = await repo.watchFavourites().first;
      expect(list.map((e) => e.verseId), ['bg-01-002', 'bg-01-001']);
      expect(list.last.at, DateTime(2026, 10, 28, 9));
    });

    test('history dedupes, orders newest first, and is capped at 200', () async {
      for (var i = 1; i <= 205; i++) {
        now = now.add(const Duration(seconds: 1));
        await repo.recordHistory('bg-18-${i.toString().padLeft(3, '0')}');
      }
      now = now.add(const Duration(seconds: 1));
      await repo.recordHistory('bg-18-010'); // revisit
      final list = await repo.watchHistory().first;
      expect(list.length, 200);
      expect(list.first.verseId, 'bg-18-010');
      expect(list.where((e) => e.verseId == 'bg-18-010').length, 1);
      // The oldest ones were dropped.
      expect(list.any((e) => e.verseId == 'bg-18-001'), isFalse);
    });

    test('clear history keeps favourites; reset clears everything', () async {
      await repo.setFavourite('a', true);
      await repo.recordHistory('a');
      await repo.clearHistory();
      expect(await repo.watchHistory().first, isEmpty);
      expect(await repo.watchFavourites().first, isNotEmpty);
      await repo.setBookmark('b', true);
      await repo.resetAll();
      expect(await repo.allReferencedIds(), isEmpty);
    });

    test('orphan purge removes ids not in the dataset', () async {
      await repo.setFavourite('bg-01-001', true);
      await repo.setBookmark('bg-99-001', true);
      await repo.recordHistory('gone');
      final removed = await repo.purgeOrphans((id) async => id == 'bg-01-001');
      expect(removed, 2);
      expect(await repo.allReferencedIds(), {'bg-01-001'});
    });

    test('schema version 1 creates all tables', () async {
      expect(db.schemaVersion, 1);
      expect(db.allTables.map((t) => t.actualTableName).toSet(), {
        'favourites',
        'bookmarks',
        'history',
      });
    });
  });

  group('SettingsRepository', () {
    test('defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsRepository(await SharedPreferences.getInstance()).load();
      expect(s.languageCode, 'en');
      expect(s.themeMode, AppThemeMode.system);
      expect(s.textScaleStep, 2);
      expect(s.lastVerseId, isNull);
      expect(s.firstLaunchDone, isFalse);
    });

    test('invalid stored values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.kLanguage: 'fr',
        SettingsRepository.kTheme: 'purple',
        SettingsRepository.kTextScale: 9,
        SettingsRepository.kLastVerse: 'not-an-id',
        SettingsRepository.kFirstLaunch: 'yes',
      });
      final s = SettingsRepository(await SharedPreferences.getInstance()).load();
      expect(s.languageCode, 'en');
      expect(s.themeMode, AppThemeMode.system);
      expect(s.textScaleStep, 2);
      expect(s.lastVerseId, isNull);
      expect(s.firstLaunchDone, isFalse);
    });

    test('values persist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await repo.setLanguage('hi');
      await repo.setThemeMode(AppThemeMode.dark);
      await repo.setTextScaleStep(4);
      await repo.setLastVerseId('bg-03-012');
      await repo.setFirstLaunchDone(true);
      final s = SettingsRepository(prefs).load();
      expect(s.languageCode, 'hi');
      expect(s.themeMode, AppThemeMode.dark);
      expect(s.textScaleStep, 4);
      expect(s.readingScale, 1.25);
      expect(s.lastVerseId, 'bg-03-012');
      expect(s.firstLaunchDone, isTrue);
      await repo.clearAll();
      expect(SettingsRepository(prefs).load().firstLaunchDone, isFalse);
    });
  });
}
