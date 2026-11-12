// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FavouritesTable extends Favourites
    with TableInfo<$FavouritesTable, FavouriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [verseId, createdAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavouriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  FavouriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavouriteRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $FavouritesTable createAlias(String alias) {
    return $FavouritesTable(attachedDatabase, alias);
  }
}

class FavouriteRow extends DataClass implements Insertable<FavouriteRow> {
  final String verseId;
  final int createdAtMs;
  const FavouriteRow({required this.verseId, required this.createdAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  FavouritesCompanion toCompanion(bool nullToAbsent) {
    return FavouritesCompanion(
      verseId: Value(verseId),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory FavouriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavouriteRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  FavouriteRow copyWith({String? verseId, int? createdAtMs}) => FavouriteRow(
    verseId: verseId ?? this.verseId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  FavouriteRow copyWithCompanion(FavouritesCompanion data) {
    return FavouriteRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavouriteRow(')
          ..write('verseId: $verseId, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(verseId, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavouriteRow &&
          other.verseId == this.verseId &&
          other.createdAtMs == this.createdAtMs);
}

class FavouritesCompanion extends UpdateCompanion<FavouriteRow> {
  final Value<String> verseId;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const FavouritesCompanion({
    this.verseId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavouritesCompanion.insert({
    required String verseId,
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       createdAtMs = Value(createdAtMs);
  static Insertable<FavouriteRow> custom({
    Expression<String>? verseId,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavouritesCompanion copyWith({
    Value<String>? verseId,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return FavouritesCompanion(
      verseId: verseId ?? this.verseId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouritesCompanion(')
          ..write('verseId: $verseId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [verseId, createdAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final String verseId;
  final int createdAtMs;
  const BookmarkRow({required this.verseId, required this.createdAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      verseId: Value(verseId),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  BookmarkRow copyWith({String? verseId, int? createdAtMs}) => BookmarkRow(
    verseId: verseId ?? this.verseId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('verseId: $verseId, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(verseId, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.verseId == this.verseId &&
          other.createdAtMs == this.createdAtMs);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<String> verseId;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.verseId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String verseId,
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       createdAtMs = Value(createdAtMs);
  static Insertable<BookmarkRow> custom({
    Expression<String>? verseId,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? verseId,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      verseId: verseId ?? this.verseId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('verseId: $verseId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryTable extends History with TableInfo<$HistoryTable, HistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadAtMsMeta = const VerificationMeta(
    'lastReadAtMs',
  );
  @override
  late final GeneratedColumn<int> lastReadAtMs = GeneratedColumn<int>(
    'last_read_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [verseId, lastReadAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('last_read_at_ms')) {
      context.handle(
        _lastReadAtMsMeta,
        lastReadAtMs.isAcceptableOrUnknown(
          data['last_read_at_ms']!,
          _lastReadAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastReadAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  HistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      lastReadAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_at_ms'],
      )!,
    );
  }

  @override
  $HistoryTable createAlias(String alias) {
    return $HistoryTable(attachedDatabase, alias);
  }
}

class HistoryRow extends DataClass implements Insertable<HistoryRow> {
  final String verseId;
  final int lastReadAtMs;
  const HistoryRow({required this.verseId, required this.lastReadAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['last_read_at_ms'] = Variable<int>(lastReadAtMs);
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(
      verseId: Value(verseId),
      lastReadAtMs: Value(lastReadAtMs),
    );
  }

  factory HistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      lastReadAtMs: serializer.fromJson<int>(json['lastReadAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'lastReadAtMs': serializer.toJson<int>(lastReadAtMs),
    };
  }

  HistoryRow copyWith({String? verseId, int? lastReadAtMs}) => HistoryRow(
    verseId: verseId ?? this.verseId,
    lastReadAtMs: lastReadAtMs ?? this.lastReadAtMs,
  );
  HistoryRow copyWithCompanion(HistoryCompanion data) {
    return HistoryRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      lastReadAtMs: data.lastReadAtMs.present
          ? data.lastReadAtMs.value
          : this.lastReadAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRow(')
          ..write('verseId: $verseId, ')
          ..write('lastReadAtMs: $lastReadAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(verseId, lastReadAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryRow &&
          other.verseId == this.verseId &&
          other.lastReadAtMs == this.lastReadAtMs);
}

class HistoryCompanion extends UpdateCompanion<HistoryRow> {
  final Value<String> verseId;
  final Value<int> lastReadAtMs;
  final Value<int> rowid;
  const HistoryCompanion({
    this.verseId = const Value.absent(),
    this.lastReadAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryCompanion.insert({
    required String verseId,
    required int lastReadAtMs,
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       lastReadAtMs = Value(lastReadAtMs);
  static Insertable<HistoryRow> custom({
    Expression<String>? verseId,
    Expression<int>? lastReadAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (lastReadAtMs != null) 'last_read_at_ms': lastReadAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryCompanion copyWith({
    Value<String>? verseId,
    Value<int>? lastReadAtMs,
    Value<int>? rowid,
  }) {
    return HistoryCompanion(
      verseId: verseId ?? this.verseId,
      lastReadAtMs: lastReadAtMs ?? this.lastReadAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (lastReadAtMs.present) {
      map['last_read_at_ms'] = Variable<int>(lastReadAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('verseId: $verseId, ')
          ..write('lastReadAtMs: $lastReadAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadDaysTable extends ReadDays
    with TableInfo<$ReadDaysTable, ReadDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseCountMeta = const VerificationMeta(
    'verseCount',
  );
  @override
  late final GeneratedColumn<int> verseCount = GeneratedColumn<int>(
    'verse_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstReadAtMeta = const VerificationMeta(
    'firstReadAt',
  );
  @override
  late final GeneratedColumn<String> firstReadAt = GeneratedColumn<String>(
    'first_read_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, verseCount, firstReadAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('verse_count')) {
      context.handle(
        _verseCountMeta,
        verseCount.isAcceptableOrUnknown(data['verse_count']!, _verseCountMeta),
      );
    } else if (isInserting) {
      context.missing(_verseCountMeta);
    }
    if (data.containsKey('first_read_at')) {
      context.handle(
        _firstReadAtMeta,
        firstReadAt.isAcceptableOrUnknown(
          data['first_read_at']!,
          _firstReadAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstReadAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  ReadDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadDayRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      verseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse_count'],
      )!,
      firstReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_read_at'],
      )!,
    );
  }

  @override
  $ReadDaysTable createAlias(String alias) {
    return $ReadDaysTable(attachedDatabase, alias);
  }
}

class ReadDayRow extends DataClass implements Insertable<ReadDayRow> {
  final String date;
  final int verseCount;
  final String firstReadAt;
  const ReadDayRow({
    required this.date,
    required this.verseCount,
    required this.firstReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['verse_count'] = Variable<int>(verseCount);
    map['first_read_at'] = Variable<String>(firstReadAt);
    return map;
  }

  ReadDaysCompanion toCompanion(bool nullToAbsent) {
    return ReadDaysCompanion(
      date: Value(date),
      verseCount: Value(verseCount),
      firstReadAt: Value(firstReadAt),
    );
  }

  factory ReadDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadDayRow(
      date: serializer.fromJson<String>(json['date']),
      verseCount: serializer.fromJson<int>(json['verseCount']),
      firstReadAt: serializer.fromJson<String>(json['firstReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'verseCount': serializer.toJson<int>(verseCount),
      'firstReadAt': serializer.toJson<String>(firstReadAt),
    };
  }

  ReadDayRow copyWith({String? date, int? verseCount, String? firstReadAt}) =>
      ReadDayRow(
        date: date ?? this.date,
        verseCount: verseCount ?? this.verseCount,
        firstReadAt: firstReadAt ?? this.firstReadAt,
      );
  ReadDayRow copyWithCompanion(ReadDaysCompanion data) {
    return ReadDayRow(
      date: data.date.present ? data.date.value : this.date,
      verseCount: data.verseCount.present
          ? data.verseCount.value
          : this.verseCount,
      firstReadAt: data.firstReadAt.present
          ? data.firstReadAt.value
          : this.firstReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadDayRow(')
          ..write('date: $date, ')
          ..write('verseCount: $verseCount, ')
          ..write('firstReadAt: $firstReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, verseCount, firstReadAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadDayRow &&
          other.date == this.date &&
          other.verseCount == this.verseCount &&
          other.firstReadAt == this.firstReadAt);
}

class ReadDaysCompanion extends UpdateCompanion<ReadDayRow> {
  final Value<String> date;
  final Value<int> verseCount;
  final Value<String> firstReadAt;
  final Value<int> rowid;
  const ReadDaysCompanion({
    this.date = const Value.absent(),
    this.verseCount = const Value.absent(),
    this.firstReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadDaysCompanion.insert({
    required String date,
    required int verseCount,
    required String firstReadAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       verseCount = Value(verseCount),
       firstReadAt = Value(firstReadAt);
  static Insertable<ReadDayRow> custom({
    Expression<String>? date,
    Expression<int>? verseCount,
    Expression<String>? firstReadAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (verseCount != null) 'verse_count': verseCount,
      if (firstReadAt != null) 'first_read_at': firstReadAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadDaysCompanion copyWith({
    Value<String>? date,
    Value<int>? verseCount,
    Value<String>? firstReadAt,
    Value<int>? rowid,
  }) {
    return ReadDaysCompanion(
      date: date ?? this.date,
      verseCount: verseCount ?? this.verseCount,
      firstReadAt: firstReadAt ?? this.firstReadAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (verseCount.present) {
      map['verse_count'] = Variable<int>(verseCount.value);
    }
    if (firstReadAt.present) {
      map['first_read_at'] = Variable<String>(firstReadAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadDaysCompanion(')
          ..write('date: $date, ')
          ..write('verseCount: $verseCount, ')
          ..write('firstReadAt: $firstReadAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadDayVersesTable extends ReadDayVerses
    with TableInfo<$ReadDayVersesTable, ReadDayVerseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadDayVersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, verseId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_day_verses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadDayVerseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, verseId};
  @override
  ReadDayVerseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadDayVerseRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
    );
  }

  @override
  $ReadDayVersesTable createAlias(String alias) {
    return $ReadDayVersesTable(attachedDatabase, alias);
  }
}

class ReadDayVerseRow extends DataClass implements Insertable<ReadDayVerseRow> {
  final String date;
  final String verseId;
  const ReadDayVerseRow({required this.date, required this.verseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['verse_id'] = Variable<String>(verseId);
    return map;
  }

  ReadDayVersesCompanion toCompanion(bool nullToAbsent) {
    return ReadDayVersesCompanion(date: Value(date), verseId: Value(verseId));
  }

  factory ReadDayVerseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadDayVerseRow(
      date: serializer.fromJson<String>(json['date']),
      verseId: serializer.fromJson<String>(json['verseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'verseId': serializer.toJson<String>(verseId),
    };
  }

  ReadDayVerseRow copyWith({String? date, String? verseId}) => ReadDayVerseRow(
    date: date ?? this.date,
    verseId: verseId ?? this.verseId,
  );
  ReadDayVerseRow copyWithCompanion(ReadDayVersesCompanion data) {
    return ReadDayVerseRow(
      date: data.date.present ? data.date.value : this.date,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadDayVerseRow(')
          ..write('date: $date, ')
          ..write('verseId: $verseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, verseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadDayVerseRow &&
          other.date == this.date &&
          other.verseId == this.verseId);
}

class ReadDayVersesCompanion extends UpdateCompanion<ReadDayVerseRow> {
  final Value<String> date;
  final Value<String> verseId;
  final Value<int> rowid;
  const ReadDayVersesCompanion({
    this.date = const Value.absent(),
    this.verseId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadDayVersesCompanion.insert({
    required String date,
    required String verseId,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       verseId = Value(verseId);
  static Insertable<ReadDayVerseRow> custom({
    Expression<String>? date,
    Expression<String>? verseId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (verseId != null) 'verse_id': verseId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadDayVersesCompanion copyWith({
    Value<String>? date,
    Value<String>? verseId,
    Value<int>? rowid,
  }) {
    return ReadDayVersesCompanion(
      date: date ?? this.date,
      verseId: verseId ?? this.verseId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadDayVersesCompanion(')
          ..write('date: $date, ')
          ..write('verseId: $verseId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotifAssignmentsTable extends NotifAssignments
    with TableInfo<$NotifAssignmentsTable, NotifAssignmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotifAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [date, slot, messageId, verseId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notif_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotifAssignmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, slot};
  @override
  NotifAssignmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotifAssignmentRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      ),
    );
  }

  @override
  $NotifAssignmentsTable createAlias(String alias) {
    return $NotifAssignmentsTable(attachedDatabase, alias);
  }
}

class NotifAssignmentRow extends DataClass
    implements Insertable<NotifAssignmentRow> {
  final String date;
  final String slot;
  final String messageId;
  final String? verseId;
  const NotifAssignmentRow({
    required this.date,
    required this.slot,
    required this.messageId,
    this.verseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['slot'] = Variable<String>(slot);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || verseId != null) {
      map['verse_id'] = Variable<String>(verseId);
    }
    return map;
  }

  NotifAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return NotifAssignmentsCompanion(
      date: Value(date),
      slot: Value(slot),
      messageId: Value(messageId),
      verseId: verseId == null && nullToAbsent
          ? const Value.absent()
          : Value(verseId),
    );
  }

  factory NotifAssignmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotifAssignmentRow(
      date: serializer.fromJson<String>(json['date']),
      slot: serializer.fromJson<String>(json['slot']),
      messageId: serializer.fromJson<String>(json['messageId']),
      verseId: serializer.fromJson<String?>(json['verseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'slot': serializer.toJson<String>(slot),
      'messageId': serializer.toJson<String>(messageId),
      'verseId': serializer.toJson<String?>(verseId),
    };
  }

  NotifAssignmentRow copyWith({
    String? date,
    String? slot,
    String? messageId,
    Value<String?> verseId = const Value.absent(),
  }) => NotifAssignmentRow(
    date: date ?? this.date,
    slot: slot ?? this.slot,
    messageId: messageId ?? this.messageId,
    verseId: verseId.present ? verseId.value : this.verseId,
  );
  NotifAssignmentRow copyWithCompanion(NotifAssignmentsCompanion data) {
    return NotifAssignmentRow(
      date: data.date.present ? data.date.value : this.date,
      slot: data.slot.present ? data.slot.value : this.slot,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotifAssignmentRow(')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('messageId: $messageId, ')
          ..write('verseId: $verseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, slot, messageId, verseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotifAssignmentRow &&
          other.date == this.date &&
          other.slot == this.slot &&
          other.messageId == this.messageId &&
          other.verseId == this.verseId);
}

class NotifAssignmentsCompanion extends UpdateCompanion<NotifAssignmentRow> {
  final Value<String> date;
  final Value<String> slot;
  final Value<String> messageId;
  final Value<String?> verseId;
  final Value<int> rowid;
  const NotifAssignmentsCompanion({
    this.date = const Value.absent(),
    this.slot = const Value.absent(),
    this.messageId = const Value.absent(),
    this.verseId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotifAssignmentsCompanion.insert({
    required String date,
    required String slot,
    required String messageId,
    this.verseId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       slot = Value(slot),
       messageId = Value(messageId);
  static Insertable<NotifAssignmentRow> custom({
    Expression<String>? date,
    Expression<String>? slot,
    Expression<String>? messageId,
    Expression<String>? verseId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (slot != null) 'slot': slot,
      if (messageId != null) 'message_id': messageId,
      if (verseId != null) 'verse_id': verseId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotifAssignmentsCompanion copyWith({
    Value<String>? date,
    Value<String>? slot,
    Value<String>? messageId,
    Value<String?>? verseId,
    Value<int>? rowid,
  }) {
    return NotifAssignmentsCompanion(
      date: date ?? this.date,
      slot: slot ?? this.slot,
      messageId: messageId ?? this.messageId,
      verseId: verseId ?? this.verseId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotifAssignmentsCompanion(')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('messageId: $messageId, ')
          ..write('verseId: $verseId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory
    with TableInfo<$SearchHistoryTable, SearchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<String> lastUsedAt = GeneratedColumn<String>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  SearchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryRow(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryRow extends DataClass
    implements Insertable<SearchHistoryRow> {
  final String query;
  final String lastUsedAt;
  const SearchHistoryRow({required this.query, required this.lastUsedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['last_used_at'] = Variable<String>(lastUsedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(
      query: Value(query),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory SearchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryRow(
      query: serializer.fromJson<String>(json['query']),
      lastUsedAt: serializer.fromJson<String>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'lastUsedAt': serializer.toJson<String>(lastUsedAt),
    };
  }

  SearchHistoryRow copyWith({String? query, String? lastUsedAt}) =>
      SearchHistoryRow(
        query: query ?? this.query,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );
  SearchHistoryRow copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryRow(
      query: data.query.present ? data.query.value : this.query,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRow(')
          ..write('query: $query, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryRow &&
          other.query == this.query &&
          other.lastUsedAt == this.lastUsedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryRow> {
  final Value<String> query;
  final Value<String> lastUsedAt;
  final Value<int> rowid;
  const SearchHistoryCompanion({
    this.query = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    required String query,
    required String lastUsedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<SearchHistoryRow> custom({
    Expression<String>? query,
    Expression<String>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryCompanion copyWith({
    Value<String>? query,
    Value<String>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return SearchHistoryCompanion(
      query: query ?? this.query,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<String>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('query: $query, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VerseHighlightsTable extends VerseHighlights
    with TableInfo<$VerseHighlightsTable, HighlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VerseHighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [verseId, color, updatedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verse_highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<HighlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  HighlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HighlightRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $VerseHighlightsTable createAlias(String alias) {
    return $VerseHighlightsTable(attachedDatabase, alias);
  }
}

class HighlightRow extends DataClass implements Insertable<HighlightRow> {
  final String verseId;
  final String color;
  final int updatedAtMs;
  const HighlightRow({
    required this.verseId,
    required this.color,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['color'] = Variable<String>(color);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  VerseHighlightsCompanion toCompanion(bool nullToAbsent) {
    return VerseHighlightsCompanion(
      verseId: Value(verseId),
      color: Value(color),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory HighlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HighlightRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      color: serializer.fromJson<String>(json['color']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'color': serializer.toJson<String>(color),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  HighlightRow copyWith({String? verseId, String? color, int? updatedAtMs}) =>
      HighlightRow(
        verseId: verseId ?? this.verseId,
        color: color ?? this.color,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      );
  HighlightRow copyWithCompanion(VerseHighlightsCompanion data) {
    return HighlightRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      color: data.color.present ? data.color.value : this.color,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HighlightRow(')
          ..write('verseId: $verseId, ')
          ..write('color: $color, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(verseId, color, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighlightRow &&
          other.verseId == this.verseId &&
          other.color == this.color &&
          other.updatedAtMs == this.updatedAtMs);
}

class VerseHighlightsCompanion extends UpdateCompanion<HighlightRow> {
  final Value<String> verseId;
  final Value<String> color;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const VerseHighlightsCompanion({
    this.verseId = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VerseHighlightsCompanion.insert({
    required String verseId,
    required String color,
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       color = Value(color),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<HighlightRow> custom({
    Expression<String>? verseId,
    Expression<String>? color,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (color != null) 'color': color,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VerseHighlightsCompanion copyWith({
    Value<String>? verseId,
    Value<String>? color,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return VerseHighlightsCompanion(
      verseId: verseId ?? this.verseId,
      color: color ?? this.color,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VerseHighlightsCompanion(')
          ..write('verseId: $verseId, ')
          ..write('color: $color, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VerseNotesTable extends VerseNotes
    with TableInfo<$VerseNotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VerseNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    verseId,
    body,
    createdAtMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verse_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $VerseNotesTable createAlias(String alias) {
    return $VerseNotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String verseId;
  final String body;
  final int createdAtMs;
  final int updatedAtMs;
  const NoteRow({
    required this.verseId,
    required this.body,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['body'] = Variable<String>(body);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  VerseNotesCompanion toCompanion(bool nullToAbsent) {
    return VerseNotesCompanion(
      verseId: Value(verseId),
      body: Value(body),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      body: serializer.fromJson<String>(json['body']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'body': serializer.toJson<String>(body),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  NoteRow copyWith({
    String? verseId,
    String? body,
    int? createdAtMs,
    int? updatedAtMs,
  }) => NoteRow(
    verseId: verseId ?? this.verseId,
    body: body ?? this.body,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  NoteRow copyWithCompanion(VerseNotesCompanion data) {
    return NoteRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      body: data.body.present ? data.body.value : this.body,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('verseId: $verseId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(verseId, body, createdAtMs, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.verseId == this.verseId &&
          other.body == this.body &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class VerseNotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> verseId;
  final Value<String> body;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const VerseNotesCompanion({
    this.verseId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VerseNotesCompanion.insert({
    required String verseId,
    required String body,
    required int createdAtMs,
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       body = Value(body),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<NoteRow> custom({
    Expression<String>? verseId,
    Expression<String>? body,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (body != null) 'body': body,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VerseNotesCompanion copyWith({
    Value<String>? verseId,
    Value<String>? body,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return VerseNotesCompanion(
      verseId: verseId ?? this.verseId,
      body: body ?? this.body,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VerseNotesCompanion(')
          ..write('verseId: $verseId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    verseId,
    body,
    createdAtMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalRow extends DataClass implements Insertable<JournalRow> {
  final int id;
  final String? verseId;
  final String body;
  final int createdAtMs;
  final int updatedAtMs;
  const JournalRow({
    required this.id,
    this.verseId,
    required this.body,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || verseId != null) {
      map['verse_id'] = Variable<String>(verseId);
    }
    map['body'] = Variable<String>(body);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      verseId: verseId == null && nullToAbsent
          ? const Value.absent()
          : Value(verseId),
      body: Value(body),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory JournalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalRow(
      id: serializer.fromJson<int>(json['id']),
      verseId: serializer.fromJson<String?>(json['verseId']),
      body: serializer.fromJson<String>(json['body']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'verseId': serializer.toJson<String?>(verseId),
      'body': serializer.toJson<String>(body),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  JournalRow copyWith({
    int? id,
    Value<String?> verseId = const Value.absent(),
    String? body,
    int? createdAtMs,
    int? updatedAtMs,
  }) => JournalRow(
    id: id ?? this.id,
    verseId: verseId.present ? verseId.value : this.verseId,
    body: body ?? this.body,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  JournalRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalRow(
      id: data.id.present ? data.id.value : this.id,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      body: data.body.present ? data.body.value : this.body,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalRow(')
          ..write('id: $id, ')
          ..write('verseId: $verseId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, verseId, body, createdAtMs, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalRow &&
          other.id == this.id &&
          other.verseId == this.verseId &&
          other.body == this.body &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalRow> {
  final Value<int> id;
  final Value<String?> verseId;
  final Value<String> body;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.verseId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.verseId = const Value.absent(),
    required String body,
    required int createdAtMs,
    required int updatedAtMs,
  }) : body = Value(body),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<JournalRow> custom({
    Expression<int>? id,
    Expression<String>? verseId,
    Expression<String>? body,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (verseId != null) 'verse_id': verseId,
      if (body != null) 'body': body,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<String?>? verseId,
    Value<String>? body,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      verseId: verseId ?? this.verseId,
      body: body ?? this.body,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('verseId: $verseId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

class $ShlokaProgressTable extends ShlokaProgress
    with TableInfo<$ShlokaProgressTable, ShlokaProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShlokaProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewIndexMeta = const VerificationMeta(
    'reviewIndex',
  );
  @override
  late final GeneratedColumn<int> reviewIndex = GeneratedColumn<int>(
    'review_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextReviewMeta = const VerificationMeta(
    'nextReview',
  );
  @override
  late final GeneratedColumn<String> nextReview = GeneratedColumn<String>(
    'next_review',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learnedAtMsMeta = const VerificationMeta(
    'learnedAtMs',
  );
  @override
  late final GeneratedColumn<int> learnedAtMs = GeneratedColumn<int>(
    'learned_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReviewedAtMsMeta = const VerificationMeta(
    'lastReviewedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastReviewedAtMs = GeneratedColumn<int>(
    'last_reviewed_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    verseId,
    step,
    status,
    reviewIndex,
    nextReview,
    startedAtMs,
    learnedAtMs,
    lastReviewedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shloka_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShlokaProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('review_index')) {
      context.handle(
        _reviewIndexMeta,
        reviewIndex.isAcceptableOrUnknown(
          data['review_index']!,
          _reviewIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewIndexMeta);
    }
    if (data.containsKey('next_review')) {
      context.handle(
        _nextReviewMeta,
        nextReview.isAcceptableOrUnknown(data['next_review']!, _nextReviewMeta),
      );
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('learned_at_ms')) {
      context.handle(
        _learnedAtMsMeta,
        learnedAtMs.isAcceptableOrUnknown(
          data['learned_at_ms']!,
          _learnedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed_at_ms')) {
      context.handle(
        _lastReviewedAtMsMeta,
        lastReviewedAtMs.isAcceptableOrUnknown(
          data['last_reviewed_at_ms']!,
          _lastReviewedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  ShlokaProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShlokaProgressRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reviewIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_index'],
      )!,
      nextReview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_review'],
      ),
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      learnedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_at_ms'],
      ),
      lastReviewedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_at_ms'],
      ),
    );
  }

  @override
  $ShlokaProgressTable createAlias(String alias) {
    return $ShlokaProgressTable(attachedDatabase, alias);
  }
}

class ShlokaProgressRow extends DataClass
    implements Insertable<ShlokaProgressRow> {
  final String verseId;
  final int step;
  final String status;
  final int reviewIndex;
  final String? nextReview;
  final int startedAtMs;
  final int? learnedAtMs;
  final int? lastReviewedAtMs;
  const ShlokaProgressRow({
    required this.verseId,
    required this.step,
    required this.status,
    required this.reviewIndex,
    this.nextReview,
    required this.startedAtMs,
    this.learnedAtMs,
    this.lastReviewedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['step'] = Variable<int>(step);
    map['status'] = Variable<String>(status);
    map['review_index'] = Variable<int>(reviewIndex);
    if (!nullToAbsent || nextReview != null) {
      map['next_review'] = Variable<String>(nextReview);
    }
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || learnedAtMs != null) {
      map['learned_at_ms'] = Variable<int>(learnedAtMs);
    }
    if (!nullToAbsent || lastReviewedAtMs != null) {
      map['last_reviewed_at_ms'] = Variable<int>(lastReviewedAtMs);
    }
    return map;
  }

  ShlokaProgressCompanion toCompanion(bool nullToAbsent) {
    return ShlokaProgressCompanion(
      verseId: Value(verseId),
      step: Value(step),
      status: Value(status),
      reviewIndex: Value(reviewIndex),
      nextReview: nextReview == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReview),
      startedAtMs: Value(startedAtMs),
      learnedAtMs: learnedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(learnedAtMs),
      lastReviewedAtMs: lastReviewedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAtMs),
    );
  }

  factory ShlokaProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShlokaProgressRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      step: serializer.fromJson<int>(json['step']),
      status: serializer.fromJson<String>(json['status']),
      reviewIndex: serializer.fromJson<int>(json['reviewIndex']),
      nextReview: serializer.fromJson<String?>(json['nextReview']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      learnedAtMs: serializer.fromJson<int?>(json['learnedAtMs']),
      lastReviewedAtMs: serializer.fromJson<int?>(json['lastReviewedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'step': serializer.toJson<int>(step),
      'status': serializer.toJson<String>(status),
      'reviewIndex': serializer.toJson<int>(reviewIndex),
      'nextReview': serializer.toJson<String?>(nextReview),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'learnedAtMs': serializer.toJson<int?>(learnedAtMs),
      'lastReviewedAtMs': serializer.toJson<int?>(lastReviewedAtMs),
    };
  }

  ShlokaProgressRow copyWith({
    String? verseId,
    int? step,
    String? status,
    int? reviewIndex,
    Value<String?> nextReview = const Value.absent(),
    int? startedAtMs,
    Value<int?> learnedAtMs = const Value.absent(),
    Value<int?> lastReviewedAtMs = const Value.absent(),
  }) => ShlokaProgressRow(
    verseId: verseId ?? this.verseId,
    step: step ?? this.step,
    status: status ?? this.status,
    reviewIndex: reviewIndex ?? this.reviewIndex,
    nextReview: nextReview.present ? nextReview.value : this.nextReview,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    learnedAtMs: learnedAtMs.present ? learnedAtMs.value : this.learnedAtMs,
    lastReviewedAtMs: lastReviewedAtMs.present
        ? lastReviewedAtMs.value
        : this.lastReviewedAtMs,
  );
  ShlokaProgressRow copyWithCompanion(ShlokaProgressCompanion data) {
    return ShlokaProgressRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      step: data.step.present ? data.step.value : this.step,
      status: data.status.present ? data.status.value : this.status,
      reviewIndex: data.reviewIndex.present
          ? data.reviewIndex.value
          : this.reviewIndex,
      nextReview: data.nextReview.present
          ? data.nextReview.value
          : this.nextReview,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      learnedAtMs: data.learnedAtMs.present
          ? data.learnedAtMs.value
          : this.learnedAtMs,
      lastReviewedAtMs: data.lastReviewedAtMs.present
          ? data.lastReviewedAtMs.value
          : this.lastReviewedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShlokaProgressRow(')
          ..write('verseId: $verseId, ')
          ..write('step: $step, ')
          ..write('status: $status, ')
          ..write('reviewIndex: $reviewIndex, ')
          ..write('nextReview: $nextReview, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('learnedAtMs: $learnedAtMs, ')
          ..write('lastReviewedAtMs: $lastReviewedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    verseId,
    step,
    status,
    reviewIndex,
    nextReview,
    startedAtMs,
    learnedAtMs,
    lastReviewedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShlokaProgressRow &&
          other.verseId == this.verseId &&
          other.step == this.step &&
          other.status == this.status &&
          other.reviewIndex == this.reviewIndex &&
          other.nextReview == this.nextReview &&
          other.startedAtMs == this.startedAtMs &&
          other.learnedAtMs == this.learnedAtMs &&
          other.lastReviewedAtMs == this.lastReviewedAtMs);
}

class ShlokaProgressCompanion extends UpdateCompanion<ShlokaProgressRow> {
  final Value<String> verseId;
  final Value<int> step;
  final Value<String> status;
  final Value<int> reviewIndex;
  final Value<String?> nextReview;
  final Value<int> startedAtMs;
  final Value<int?> learnedAtMs;
  final Value<int?> lastReviewedAtMs;
  final Value<int> rowid;
  const ShlokaProgressCompanion({
    this.verseId = const Value.absent(),
    this.step = const Value.absent(),
    this.status = const Value.absent(),
    this.reviewIndex = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.learnedAtMs = const Value.absent(),
    this.lastReviewedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShlokaProgressCompanion.insert({
    required String verseId,
    required int step,
    required String status,
    required int reviewIndex,
    this.nextReview = const Value.absent(),
    required int startedAtMs,
    this.learnedAtMs = const Value.absent(),
    this.lastReviewedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       step = Value(step),
       status = Value(status),
       reviewIndex = Value(reviewIndex),
       startedAtMs = Value(startedAtMs);
  static Insertable<ShlokaProgressRow> custom({
    Expression<String>? verseId,
    Expression<int>? step,
    Expression<String>? status,
    Expression<int>? reviewIndex,
    Expression<String>? nextReview,
    Expression<int>? startedAtMs,
    Expression<int>? learnedAtMs,
    Expression<int>? lastReviewedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (step != null) 'step': step,
      if (status != null) 'status': status,
      if (reviewIndex != null) 'review_index': reviewIndex,
      if (nextReview != null) 'next_review': nextReview,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (learnedAtMs != null) 'learned_at_ms': learnedAtMs,
      if (lastReviewedAtMs != null) 'last_reviewed_at_ms': lastReviewedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShlokaProgressCompanion copyWith({
    Value<String>? verseId,
    Value<int>? step,
    Value<String>? status,
    Value<int>? reviewIndex,
    Value<String?>? nextReview,
    Value<int>? startedAtMs,
    Value<int?>? learnedAtMs,
    Value<int?>? lastReviewedAtMs,
    Value<int>? rowid,
  }) {
    return ShlokaProgressCompanion(
      verseId: verseId ?? this.verseId,
      step: step ?? this.step,
      status: status ?? this.status,
      reviewIndex: reviewIndex ?? this.reviewIndex,
      nextReview: nextReview ?? this.nextReview,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      learnedAtMs: learnedAtMs ?? this.learnedAtMs,
      lastReviewedAtMs: lastReviewedAtMs ?? this.lastReviewedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reviewIndex.present) {
      map['review_index'] = Variable<int>(reviewIndex.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<String>(nextReview.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (learnedAtMs.present) {
      map['learned_at_ms'] = Variable<int>(learnedAtMs.value);
    }
    if (lastReviewedAtMs.present) {
      map['last_reviewed_at_ms'] = Variable<int>(lastReviewedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShlokaProgressCompanion(')
          ..write('verseId: $verseId, ')
          ..write('step: $step, ')
          ..write('status: $status, ')
          ..write('reviewIndex: $reviewIndex, ')
          ..write('nextReview: $nextReview, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('learnedAtMs: $learnedAtMs, ')
          ..write('lastReviewedAtMs: $lastReviewedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  late final $ReadDaysTable readDays = $ReadDaysTable(this);
  late final $ReadDayVersesTable readDayVerses = $ReadDayVersesTable(this);
  late final $NotifAssignmentsTable notifAssignments = $NotifAssignmentsTable(
    this,
  );
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final $VerseHighlightsTable verseHighlights = $VerseHighlightsTable(
    this,
  );
  late final $VerseNotesTable verseNotes = $VerseNotesTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $ShlokaProgressTable shlokaProgress = $ShlokaProgressTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    favourites,
    bookmarks,
    history,
    readDays,
    readDayVerses,
    notifAssignments,
    searchHistory,
    verseHighlights,
    verseNotes,
    journalEntries,
    shlokaProgress,
  ];
}

typedef $$FavouritesTableCreateCompanionBuilder = FavouritesCompanion Function({
  required String verseId,
  required int createdAtMs,
  Value<int> rowid,
});
typedef $$FavouritesTableUpdateCompanionBuilder = FavouritesCompanion Function({
  Value<String> verseId,
  Value<int> createdAtMs,
  Value<int> rowid,
});

class $$FavouritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavouritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavouritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$FavouritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavouritesTable,
          FavouriteRow,
          $$FavouritesTableFilterComposer,
          $$FavouritesTableOrderingComposer,
          $$FavouritesTableAnnotationComposer,
          $$FavouritesTableCreateCompanionBuilder,
          $$FavouritesTableUpdateCompanionBuilder,
          (
            FavouriteRow,
            BaseReferences<_$AppDatabase, $FavouritesTable, FavouriteRow>,
          ),
          FavouriteRow,
          PrefetchHooks Function()
        > {
  $$FavouritesTableTableManager(_$AppDatabase db, $FavouritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion(
                verseId: verseId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion.insert(
                verseId: verseId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavouritesTable, FavouriteRow>(table),
                  BaseReferences<_$AppDatabase, $FavouritesTable, FavouriteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavouritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavouritesTable,
      FavouriteRow,
      $$FavouritesTableFilterComposer,
      $$FavouritesTableOrderingComposer,
      $$FavouritesTableAnnotationComposer,
      $$FavouritesTableCreateCompanionBuilder,
      $$FavouritesTableUpdateCompanionBuilder,
      (
        FavouriteRow,
        BaseReferences<_$AppDatabase, $FavouritesTable, FavouriteRow>,
      ),
      FavouriteRow,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  required String verseId,
  required int createdAtMs,
  Value<int> rowid,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> verseId,
  Value<int> createdAtMs,
  Value<int> rowid,
});

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (
            BookmarkRow,
            BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
          ),
          BookmarkRow,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                verseId: verseId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                verseId: verseId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, BookmarkRow>(table),
                  BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (
        BookmarkRow,
        BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
      ),
      BookmarkRow,
      PrefetchHooks Function()
    >;
typedef $$HistoryTableCreateCompanionBuilder = HistoryCompanion Function({
  required String verseId,
  required int lastReadAtMs,
  Value<int> rowid,
});
typedef $$HistoryTableUpdateCompanionBuilder = HistoryCompanion Function({
  Value<String> verseId,
  Value<int> lastReadAtMs,
  Value<int> rowid,
});

class $$HistoryTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadAtMs => $composableBuilder(
    column: $table.lastReadAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadAtMs => $composableBuilder(
    column: $table.lastReadAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<int> get lastReadAtMs => $composableBuilder(
    column: $table.lastReadAtMs,
    builder: (column) => column,
  );
}

class $$HistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryTable,
          HistoryRow,
          $$HistoryTableFilterComposer,
          $$HistoryTableOrderingComposer,
          $$HistoryTableAnnotationComposer,
          $$HistoryTableCreateCompanionBuilder,
          $$HistoryTableUpdateCompanionBuilder,
          (
            HistoryRow,
            BaseReferences<_$AppDatabase, $HistoryTable, HistoryRow>,
          ),
          HistoryRow,
          PrefetchHooks Function()
        > {
  $$HistoryTableTableManager(_$AppDatabase db, $HistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<int> lastReadAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion(
                verseId: verseId,
                lastReadAtMs: lastReadAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required int lastReadAtMs,
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion.insert(
                verseId: verseId,
                lastReadAtMs: lastReadAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryTable, HistoryRow>(table),
                  BaseReferences<_$AppDatabase, $HistoryTable, HistoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryTable,
      HistoryRow,
      $$HistoryTableFilterComposer,
      $$HistoryTableOrderingComposer,
      $$HistoryTableAnnotationComposer,
      $$HistoryTableCreateCompanionBuilder,
      $$HistoryTableUpdateCompanionBuilder,
      (HistoryRow, BaseReferences<_$AppDatabase, $HistoryTable, HistoryRow>),
      HistoryRow,
      PrefetchHooks Function()
    >;
typedef $$ReadDaysTableCreateCompanionBuilder = ReadDaysCompanion Function({
  required String date,
  required int verseCount,
  required String firstReadAt,
  Value<int> rowid,
});
typedef $$ReadDaysTableUpdateCompanionBuilder = ReadDaysCompanion Function({
  Value<String> date,
  Value<int> verseCount,
  Value<String> firstReadAt,
  Value<int> rowid,
});

class $$ReadDaysTableFilterComposer
    extends Composer<_$AppDatabase, $ReadDaysTable> {
  $$ReadDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verseCount => $composableBuilder(
    column: $table.verseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadDaysTable> {
  $$ReadDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verseCount => $composableBuilder(
    column: $table.verseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadDaysTable> {
  $$ReadDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get verseCount => $composableBuilder(
    column: $table.verseCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => column,
  );
}

class $$ReadDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadDaysTable,
          ReadDayRow,
          $$ReadDaysTableFilterComposer,
          $$ReadDaysTableOrderingComposer,
          $$ReadDaysTableAnnotationComposer,
          $$ReadDaysTableCreateCompanionBuilder,
          $$ReadDaysTableUpdateCompanionBuilder,
          (
            ReadDayRow,
            BaseReferences<_$AppDatabase, $ReadDaysTable, ReadDayRow>,
          ),
          ReadDayRow,
          PrefetchHooks Function()
        > {
  $$ReadDaysTableTableManager(_$AppDatabase db, $ReadDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> verseCount = const Value.absent(),
                Value<String> firstReadAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadDaysCompanion(
                date: date,
                verseCount: verseCount,
                firstReadAt: firstReadAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int verseCount,
                required String firstReadAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadDaysCompanion.insert(
                date: date,
                verseCount: verseCount,
                firstReadAt: firstReadAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadDaysTable, ReadDayRow>(table),
                  BaseReferences<_$AppDatabase, $ReadDaysTable, ReadDayRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadDaysTable,
      ReadDayRow,
      $$ReadDaysTableFilterComposer,
      $$ReadDaysTableOrderingComposer,
      $$ReadDaysTableAnnotationComposer,
      $$ReadDaysTableCreateCompanionBuilder,
      $$ReadDaysTableUpdateCompanionBuilder,
      (ReadDayRow, BaseReferences<_$AppDatabase, $ReadDaysTable, ReadDayRow>),
      ReadDayRow,
      PrefetchHooks Function()
    >;
typedef $$ReadDayVersesTableCreateCompanionBuilder =
    ReadDayVersesCompanion Function({
      required String date,
      required String verseId,
      Value<int> rowid,
    });
typedef $$ReadDayVersesTableUpdateCompanionBuilder =
    ReadDayVersesCompanion Function({
      Value<String> date,
      Value<String> verseId,
      Value<int> rowid,
    });

class $$ReadDayVersesTableFilterComposer
    extends Composer<_$AppDatabase, $ReadDayVersesTable> {
  $$ReadDayVersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadDayVersesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadDayVersesTable> {
  $$ReadDayVersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadDayVersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadDayVersesTable> {
  $$ReadDayVersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);
}

class $$ReadDayVersesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadDayVersesTable,
          ReadDayVerseRow,
          $$ReadDayVersesTableFilterComposer,
          $$ReadDayVersesTableOrderingComposer,
          $$ReadDayVersesTableAnnotationComposer,
          $$ReadDayVersesTableCreateCompanionBuilder,
          $$ReadDayVersesTableUpdateCompanionBuilder,
          (
            ReadDayVerseRow,
            BaseReferences<_$AppDatabase, $ReadDayVersesTable, ReadDayVerseRow>,
          ),
          ReadDayVerseRow,
          PrefetchHooks Function()
        > {
  $$ReadDayVersesTableTableManager(_$AppDatabase db, $ReadDayVersesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadDayVersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadDayVersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadDayVersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> verseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadDayVersesCompanion(
                date: date,
                verseId: verseId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String verseId,
                Value<int> rowid = const Value.absent(),
              }) => ReadDayVersesCompanion.insert(
                date: date,
                verseId: verseId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadDayVersesTable, ReadDayVerseRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReadDayVersesTable,
                    ReadDayVerseRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadDayVersesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadDayVersesTable,
      ReadDayVerseRow,
      $$ReadDayVersesTableFilterComposer,
      $$ReadDayVersesTableOrderingComposer,
      $$ReadDayVersesTableAnnotationComposer,
      $$ReadDayVersesTableCreateCompanionBuilder,
      $$ReadDayVersesTableUpdateCompanionBuilder,
      (
        ReadDayVerseRow,
        BaseReferences<_$AppDatabase, $ReadDayVersesTable, ReadDayVerseRow>,
      ),
      ReadDayVerseRow,
      PrefetchHooks Function()
    >;
typedef $$NotifAssignmentsTableCreateCompanionBuilder =
    NotifAssignmentsCompanion Function({
      required String date,
      required String slot,
      required String messageId,
      Value<String?> verseId,
      Value<int> rowid,
    });
typedef $$NotifAssignmentsTableUpdateCompanionBuilder =
    NotifAssignmentsCompanion Function({
      Value<String> date,
      Value<String> slot,
      Value<String> messageId,
      Value<String?> verseId,
      Value<int> rowid,
    });

class $$NotifAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $NotifAssignmentsTable> {
  $$NotifAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotifAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotifAssignmentsTable> {
  $$NotifAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotifAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotifAssignmentsTable> {
  $$NotifAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);
}

class $$NotifAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotifAssignmentsTable,
          NotifAssignmentRow,
          $$NotifAssignmentsTableFilterComposer,
          $$NotifAssignmentsTableOrderingComposer,
          $$NotifAssignmentsTableAnnotationComposer,
          $$NotifAssignmentsTableCreateCompanionBuilder,
          $$NotifAssignmentsTableUpdateCompanionBuilder,
          (
            NotifAssignmentRow,
            BaseReferences<
              _$AppDatabase,
              $NotifAssignmentsTable,
              NotifAssignmentRow
            >,
          ),
          NotifAssignmentRow,
          PrefetchHooks Function()
        > {
  $$NotifAssignmentsTableTableManager(
    _$AppDatabase db,
    $NotifAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotifAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotifAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotifAssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String?> verseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotifAssignmentsCompanion(
                date: date,
                slot: slot,
                messageId: messageId,
                verseId: verseId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String slot,
                required String messageId,
                Value<String?> verseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotifAssignmentsCompanion.insert(
                date: date,
                slot: slot,
                messageId: messageId,
                verseId: verseId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotifAssignmentsTable, NotifAssignmentRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $NotifAssignmentsTable,
                    NotifAssignmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotifAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotifAssignmentsTable,
      NotifAssignmentRow,
      $$NotifAssignmentsTableFilterComposer,
      $$NotifAssignmentsTableOrderingComposer,
      $$NotifAssignmentsTableAnnotationComposer,
      $$NotifAssignmentsTableCreateCompanionBuilder,
      $$NotifAssignmentsTableUpdateCompanionBuilder,
      (
        NotifAssignmentRow,
        BaseReferences<
          _$AppDatabase,
          $NotifAssignmentsTable,
          NotifAssignmentRow
        >,
      ),
      NotifAssignmentRow,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder =
    SearchHistoryCompanion Function({
      required String query,
      required String lastUsedAt,
      Value<int> rowid,
    });
typedef $$SearchHistoryTableUpdateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<String> query,
      Value<String> lastUsedAt,
      Value<int> rowid,
    });

class $$SearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryTable,
          SearchHistoryRow,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (
            SearchHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryTable,
              SearchHistoryRow
            >,
          ),
          SearchHistoryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(_$AppDatabase db, $SearchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<String> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryCompanion(
                query: query,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                required String lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryCompanion.insert(
                query: query,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchHistoryTable, SearchHistoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SearchHistoryTable,
                    SearchHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryTable,
      SearchHistoryRow,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (
        SearchHistoryRow,
        BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryRow>,
      ),
      SearchHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$VerseHighlightsTableCreateCompanionBuilder =
    VerseHighlightsCompanion Function({
      required String verseId,
      required String color,
      required int updatedAtMs,
      Value<int> rowid,
    });
typedef $$VerseHighlightsTableUpdateCompanionBuilder =
    VerseHighlightsCompanion Function({
      Value<String> verseId,
      Value<String> color,
      Value<int> updatedAtMs,
      Value<int> rowid,
    });

class $$VerseHighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $VerseHighlightsTable> {
  $$VerseHighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VerseHighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $VerseHighlightsTable> {
  $$VerseHighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VerseHighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VerseHighlightsTable> {
  $$VerseHighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$VerseHighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VerseHighlightsTable,
          HighlightRow,
          $$VerseHighlightsTableFilterComposer,
          $$VerseHighlightsTableOrderingComposer,
          $$VerseHighlightsTableAnnotationComposer,
          $$VerseHighlightsTableCreateCompanionBuilder,
          $$VerseHighlightsTableUpdateCompanionBuilder,
          (
            HighlightRow,
            BaseReferences<_$AppDatabase, $VerseHighlightsTable, HighlightRow>,
          ),
          HighlightRow,
          PrefetchHooks Function()
        > {
  $$VerseHighlightsTableTableManager(
    _$AppDatabase db,
    $VerseHighlightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VerseHighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VerseHighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VerseHighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerseHighlightsCompanion(
                verseId: verseId,
                color: color,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required String color,
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => VerseHighlightsCompanion.insert(
                verseId: verseId,
                color: color,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VerseHighlightsTable, HighlightRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $VerseHighlightsTable,
                    HighlightRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VerseHighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VerseHighlightsTable,
      HighlightRow,
      $$VerseHighlightsTableFilterComposer,
      $$VerseHighlightsTableOrderingComposer,
      $$VerseHighlightsTableAnnotationComposer,
      $$VerseHighlightsTableCreateCompanionBuilder,
      $$VerseHighlightsTableUpdateCompanionBuilder,
      (
        HighlightRow,
        BaseReferences<_$AppDatabase, $VerseHighlightsTable, HighlightRow>,
      ),
      HighlightRow,
      PrefetchHooks Function()
    >;
typedef $$VerseNotesTableCreateCompanionBuilder = VerseNotesCompanion Function({
  required String verseId,
  required String body,
  required int createdAtMs,
  required int updatedAtMs,
  Value<int> rowid,
});
typedef $$VerseNotesTableUpdateCompanionBuilder = VerseNotesCompanion Function({
  Value<String> verseId,
  Value<String> body,
  Value<int> createdAtMs,
  Value<int> updatedAtMs,
  Value<int> rowid,
});

class $$VerseNotesTableFilterComposer
    extends Composer<_$AppDatabase, $VerseNotesTable> {
  $$VerseNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VerseNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $VerseNotesTable> {
  $$VerseNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VerseNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VerseNotesTable> {
  $$VerseNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$VerseNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VerseNotesTable,
          NoteRow,
          $$VerseNotesTableFilterComposer,
          $$VerseNotesTableOrderingComposer,
          $$VerseNotesTableAnnotationComposer,
          $$VerseNotesTableCreateCompanionBuilder,
          $$VerseNotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $VerseNotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$VerseNotesTableTableManager(_$AppDatabase db, $VerseNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VerseNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VerseNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VerseNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerseNotesCompanion(
                verseId: verseId,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required String body,
                required int createdAtMs,
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => VerseNotesCompanion.insert(
                verseId: verseId,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VerseNotesTable, NoteRow>(table),
                  BaseReferences<_$AppDatabase, $VerseNotesTable, NoteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VerseNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VerseNotesTable,
      NoteRow,
      $$VerseNotesTableFilterComposer,
      $$VerseNotesTableOrderingComposer,
      $$VerseNotesTableAnnotationComposer,
      $$VerseNotesTableCreateCompanionBuilder,
      $$VerseNotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $VerseNotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String?> verseId,
      required String body,
      required int createdAtMs,
      required int updatedAtMs,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String?> verseId,
      Value<String> body,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalRow,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalRow,
            BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalRow>,
          ),
          JournalRow,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> verseId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                verseId: verseId,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> verseId = const Value.absent(),
                required String body,
                required int createdAtMs,
                required int updatedAtMs,
              }) => JournalEntriesCompanion.insert(
                id: id,
                verseId: verseId,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalEntriesTable, JournalRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $JournalEntriesTable,
                    JournalRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalRow,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalRow,
        BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalRow>,
      ),
      JournalRow,
      PrefetchHooks Function()
    >;
typedef $$ShlokaProgressTableCreateCompanionBuilder =
    ShlokaProgressCompanion Function({
      required String verseId,
      required int step,
      required String status,
      required int reviewIndex,
      Value<String?> nextReview,
      required int startedAtMs,
      Value<int?> learnedAtMs,
      Value<int?> lastReviewedAtMs,
      Value<int> rowid,
    });
typedef $$ShlokaProgressTableUpdateCompanionBuilder =
    ShlokaProgressCompanion Function({
      Value<String> verseId,
      Value<int> step,
      Value<String> status,
      Value<int> reviewIndex,
      Value<String?> nextReview,
      Value<int> startedAtMs,
      Value<int?> learnedAtMs,
      Value<int?> lastReviewedAtMs,
      Value<int> rowid,
    });

class $$ShlokaProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ShlokaProgressTable> {
  $$ShlokaProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewIndex => $composableBuilder(
    column: $table.reviewIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedAtMs => $composableBuilder(
    column: $table.learnedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedAtMs => $composableBuilder(
    column: $table.lastReviewedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShlokaProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ShlokaProgressTable> {
  $$ShlokaProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewIndex => $composableBuilder(
    column: $table.reviewIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedAtMs => $composableBuilder(
    column: $table.learnedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAtMs => $composableBuilder(
    column: $table.lastReviewedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShlokaProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShlokaProgressTable> {
  $$ShlokaProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get reviewIndex => $composableBuilder(
    column: $table.reviewIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedAtMs => $composableBuilder(
    column: $table.learnedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReviewedAtMs => $composableBuilder(
    column: $table.lastReviewedAtMs,
    builder: (column) => column,
  );
}

class $$ShlokaProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShlokaProgressTable,
          ShlokaProgressRow,
          $$ShlokaProgressTableFilterComposer,
          $$ShlokaProgressTableOrderingComposer,
          $$ShlokaProgressTableAnnotationComposer,
          $$ShlokaProgressTableCreateCompanionBuilder,
          $$ShlokaProgressTableUpdateCompanionBuilder,
          (
            ShlokaProgressRow,
            BaseReferences<
              _$AppDatabase,
              $ShlokaProgressTable,
              ShlokaProgressRow
            >,
          ),
          ShlokaProgressRow,
          PrefetchHooks Function()
        > {
  $$ShlokaProgressTableTableManager(
    _$AppDatabase db,
    $ShlokaProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShlokaProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShlokaProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShlokaProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<int> step = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> reviewIndex = const Value.absent(),
                Value<String?> nextReview = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> learnedAtMs = const Value.absent(),
                Value<int?> lastReviewedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShlokaProgressCompanion(
                verseId: verseId,
                step: step,
                status: status,
                reviewIndex: reviewIndex,
                nextReview: nextReview,
                startedAtMs: startedAtMs,
                learnedAtMs: learnedAtMs,
                lastReviewedAtMs: lastReviewedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required int step,
                required String status,
                required int reviewIndex,
                Value<String?> nextReview = const Value.absent(),
                required int startedAtMs,
                Value<int?> learnedAtMs = const Value.absent(),
                Value<int?> lastReviewedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShlokaProgressCompanion.insert(
                verseId: verseId,
                step: step,
                status: status,
                reviewIndex: reviewIndex,
                nextReview: nextReview,
                startedAtMs: startedAtMs,
                learnedAtMs: learnedAtMs,
                lastReviewedAtMs: lastReviewedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShlokaProgressTable, ShlokaProgressRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ShlokaProgressTable,
                    ShlokaProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShlokaProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShlokaProgressTable,
      ShlokaProgressRow,
      $$ShlokaProgressTableFilterComposer,
      $$ShlokaProgressTableOrderingComposer,
      $$ShlokaProgressTableAnnotationComposer,
      $$ShlokaProgressTableCreateCompanionBuilder,
      $$ShlokaProgressTableUpdateCompanionBuilder,
      (
        ShlokaProgressRow,
        BaseReferences<_$AppDatabase, $ShlokaProgressTable, ShlokaProgressRow>,
      ),
      ShlokaProgressRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
  $$ReadDaysTableTableManager get readDays =>
      $$ReadDaysTableTableManager(_db, _db.readDays);
  $$ReadDayVersesTableTableManager get readDayVerses =>
      $$ReadDayVersesTableTableManager(_db, _db.readDayVerses);
  $$NotifAssignmentsTableTableManager get notifAssignments =>
      $$NotifAssignmentsTableTableManager(_db, _db.notifAssignments);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db, _db.searchHistory);
  $$VerseHighlightsTableTableManager get verseHighlights =>
      $$VerseHighlightsTableTableManager(_db, _db.verseHighlights);
  $$VerseNotesTableTableManager get verseNotes =>
      $$VerseNotesTableTableManager(_db, _db.verseNotes);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$ShlokaProgressTableTableManager get shlokaProgress =>
      $$ShlokaProgressTableTableManager(_db, _db.shlokaProgress);
}
