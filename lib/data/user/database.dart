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

// v3 (PRD_v3 section 4): the study layer and the shloka trainer. Times are
// epoch milliseconds like v1; review dates are local `YYYY-MM-DD` strings.

@DataClassName('HighlightRow')
class VerseHighlights extends Table {
  TextColumn get verseId => text()();
  TextColumn get color => text()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {verseId};
}

@DataClassName('NoteRow')
class VerseNotes extends Table {
  TextColumn get verseId => text()();
  TextColumn get body => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {verseId};
}

@DataClassName('JournalRow')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get verseId => text().nullable()();
  TextColumn get body => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
}

@DataClassName('ShlokaProgressRow')
class ShlokaProgress extends Table {
  TextColumn get verseId => text()();
  IntColumn get step => integer()();
  TextColumn get status => text()();
  IntColumn get reviewIndex => integer()();
  TextColumn get nextReview => text().nullable()();
  IntColumn get startedAtMs => integer()();
  IntColumn get learnedAtMs => integer().nullable()();
  IntColumn get lastReviewedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {verseId};
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
    VerseHighlights,
    VerseNotes,
    JournalEntries,
    ShlokaProgress,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

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
      if (from < 3) {
        await m.createTable(verseHighlights);
        await m.createTable(verseNotes);
        await m.createTable(journalEntries);
        await m.createTable(shlokaProgress);
      }
    },
  );

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'user_data.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }
}
