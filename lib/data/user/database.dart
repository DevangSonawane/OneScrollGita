import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('FavouriteRow')
class Favourites extends Table {
  TextColumn get verseId => text()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {verseId};
}

@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  TextColumn get verseId => text()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {verseId};
}

@DataClassName('HistoryRow')
class History extends Table {
  TextColumn get verseId => text()();
  IntColumn get lastReadAtMs => integer()();

  @override
  Set<Column> get primaryKey => {verseId};
}

// v2 (PRD_v2 section 3). Dates are local `YYYY-MM-DD` strings.

/// One row per local day that had a qualifying read.
@DataClassName('ReadDayRow')
class ReadDays extends Table {
  TextColumn get date => text()();
  IntColumn get verseCount => integer()();
  TextColumn get firstReadAt => text()();

  @override
  Set<Column> get primaryKey => {date};
}

/// Distinct verses that qualified on a day.
@DataClassName('ReadDayVerseRow')
class ReadDayVerses extends Table {
  TextColumn get date => text()();
  TextColumn get verseId => text()();

  @override
  Set<Column> get primaryKey => {date, verseId};
}

/// Keeps a day's notification message stable across reschedules.
@DataClassName('NotifAssignmentRow')
class NotifAssignments extends Table {
  TextColumn get date => text()();
  TextColumn get slot => text()();
  TextColumn get messageId => text()();
  TextColumn get verseId => text().nullable()();

  @override
  Set<Column> get primaryKey => {date, slot};
}

@DataClassName('SearchHistoryRow')
class SearchHistory extends Table {
  TextColumn get query => text()();
  TextColumn get lastUsedAt => text()();

  @override
  Set<Column> get primaryKey => {query};
}

@DriftDatabase(
  tables: [
    Favourites,
    Bookmarks,
    History,
    ReadDays,
    ReadDayVerses,
    NotifAssignments,
    SearchHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Each step has a test in test/data/migration_test.dart.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(readDays);
        await m.createTable(readDayVerses);
        await m.createTable(notifAssignments);
        await m.createTable(searchHistory);
      }
    },
  );

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'user_data.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }
}
