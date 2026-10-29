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
}
