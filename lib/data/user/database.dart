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

@DriftDatabase(tables: [Favourites, Bookmarks, History])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Add steps here when schemaVersion changes, with a migration test.
  );

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'user_data.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }
}
