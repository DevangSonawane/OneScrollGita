import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../domain/markup.dart';
import '../../domain/search/normalize.dart';
import '../scripture/scripture_repository.dart';
import '../scripture/scripture_validator.dart' show chapterFileName;

/// One row of the dataset catalogue (also used by verse notifications).
class CatalogueEntry {
  const CatalogueEntry({
    required this.id,
    required this.chapter,
    required this.label,
    required this.translationEn,
    this.translationHi,
  });

  final String id;
  final int chapter;
  final String label;
  final String translationEn;
  final String? translationHi;

  String translation(String lang) =>
      lang == 'hi' && (translationHi?.trim().isNotEmpty ?? false)
      ? translationHi!
      : translationEn;
}

class SearchHit {
  const SearchHit({
    required this.id,
    required this.chapter,
    required this.label,
    required this.snippet,
    required this.inPurport,
  });

  final String id;
  final int chapter;
  final String label;

  /// Snippet text; matched words are wrapped in [hitStart] / [hitEnd].
  final String snippet;
  final bool inPurport;

  static const hitStart = '\u0001';
  static const hitEnd = '\u0002';
}

class SearchResults {
  const SearchResults(this.translation, this.purport);

  static const empty = SearchResults([], []);

  final List<SearchHit> translation;
  final List<SearchHit> purport;

  bool get isEmpty => translation.isEmpty && purport.isEmpty;
}

/// Local SQLite FTS5 index of the bundled dataset (PRD_v2 section 10). Its
/// own database file, separate from user data. Rebuilt when the dataset
/// version changes.
class SearchIndex {
  SearchIndex(this._db, this._aliases);

  /// Bump when the table layout changes.
  static const schema = 1;
  static const fileName = 'search_index.sqlite';
  static const resultLimit = 60;

  final Database _db;

  /// Normalised spelling -> normalised dataset spelling.
  final Map<String, String> _aliases;

  /// Opens the on-disk index, building it in an isolate when missing or
  /// out of date. [onBuilding] is called before a (one-time) build.
  static Future<SearchIndex> open({
    required String datasetVersion,
    required Map<String, String> aliases,
    AssetBundle? bundle,
    VoidCallback? onBuilding,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, fileName);
    final version = '$schema/$datasetVersion';
    if (_storedVersion(path) != version) {
      onBuilding?.call();
      final jsons = await _loadChapters(bundle ?? rootBundle);
      await compute(_buildFile, (path: path, jsons: jsons, version: version));
    }
    return SearchIndex(sqlite3.open(path), _normalizeAliases(aliases));
  }

  /// In-memory index for tests (built on this isolate).
  static SearchIndex memory(
    List<String> chapterJsons, {
    Map<String, String> aliases = const {},
  }) {
    final db = sqlite3.openInMemory();
    _build(db, chapterJsons, 'memory');
    return SearchIndex(db, _normalizeAliases(aliases));
  }

  static Future<List<String>> _loadChapters(AssetBundle bundle) async => [
    for (var c = 1; c <= 18; c++)
      await bundle.loadString(
        '${ScriptureRepository.basePath}/${chapterFileName(c)}',
        cache: false,
      ),
  ];

  static String? _storedVersion(String path) {
    if (!File(path).existsSync()) return null;
    try {
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        final rows = db.select("SELECT value FROM meta WHERE key = 'version'");
        return rows.isEmpty ? null : rows.first['value'] as String;
      } finally {
        db.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _normalizeAliases(Map<String, String> raw) => {
    for (final e in raw.entries) normalizeQuery(e.key): normalizeQuery(e.value),
  };

  static void _buildFile(
    ({String path, List<String> jsons, String version}) a,
  ) {
    final file = File(a.path);
    if (file.existsSync()) file.deleteSync();
    final db = sqlite3.open(a.path);
    try {
      _build(db, a.jsons, a.version);
    } finally {
      db.close();
    }
  }

  static void _build(Database db, List<String> jsons, String version) {
    db.execute('''
      CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT);
      CREATE TABLE catalogue(
        ord INTEGER PRIMARY KEY,
        entry_id TEXT NOT NULL UNIQUE,
        chapter INTEGER NOT NULL,
        label TEXT NOT NULL,
        translation_en TEXT NOT NULL,
        translation_hi TEXT
      );
      CREATE VIRTUAL TABLE entries USING fts5(
        entry_id UNINDEXED,
        label,
        translation_en,
        translation_hi,
        transliteration,
        sanskrit,
        purport,
        tokenize = 'unicode61 remove_diacritics 2',
        prefix = '2 3'
      );
    ''');
    db.execute('BEGIN');
    final cat = db.prepare('INSERT INTO catalogue VALUES (?, ?, ?, ?, ?, ?)');
    final fts = db.prepare(
      'INSERT INTO entries(rowid, entry_id, label, translation_en, '
      'translation_hi, transliteration, sanskrit, purport) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    var ord = 0;
    for (final raw in jsons) {
      for (final e in parseChapterJson(raw)) {
        final purport = [
          for (final b in [...?e.purportEn, ...?e.purportHi])
            stripMarkup(b.text),
        ].join('\n');
        cat.execute([
          ord,
          e.id,
          e.chapter,
          e.label,
          e.translationEn,
          e.translationHi,
        ]);
        fts.execute([
          ord,
          e.id,
          e.label,
          e.translationEn,
          e.translationHi ?? '',
          e.transliteration.join(' '),
          e.sanskrit.join(' '),
          purport,
        ]);
        ord++;
      }
    }
    cat.close();
    fts.close();
    db.execute("INSERT INTO meta VALUES ('version', ?)", [version]);
    db.execute('COMMIT');
  }

  /// Every entry in reading order.
  List<CatalogueEntry> catalogue() => [
    for (final r in _db.select('SELECT * FROM catalogue ORDER BY ord'))
      _entry(r),
  ];

  List<CatalogueEntry> entries(Iterable<String> ids) {
    final list = ids.toList();
    if (list.isEmpty) return const [];
    final rows = _db.select(
      'SELECT * FROM catalogue WHERE entry_id IN '
      '(${List.filled(list.length, '?').join(',')})',
      list,
    );
    final byId = {for (final r in rows) r['entry_id'] as String: _entry(r)};
    return [for (final id in list) ?byId[id]];
  }

  CatalogueEntry _entry(Row r) => CatalogueEntry(
    id: r['entry_id'] as String,
    chapter: r['chapter'] as int,
    label: r['label'] as String,
    translationEn: r['translation_en'] as String,
    translationHi: r['translation_hi'] as String?,
  );

  /// FTS5 match expression for a typed query, or null when it has no
  /// words. The last word matches as a prefix (typed so far); aliases add
  /// the dataset spelling.
  @visibleForTesting
  String? matchExpression(String query) {
    final words = queryWords(normalizeQuery(query));
    if (words.isEmpty) return null;
    String term(String w) => '"${w.replaceAll('"', '')}"*';
    return [
      for (final w in words)
        _aliases[w] == null || _aliases[w] == w
            ? term(w)
            : '(${term(w)} OR ${_aliases[w]!.split(' ').map(term).join(' ')})',
    ].join(' AND ');
  }

  /// Keyword search, ranked with bm25 (translation highest, then
  /// transliteration, then purport).
  SearchResults search(String query, {required String lang}) {
    final expr = matchExpression(query);
    if (expr == null) return SearchResults.empty;
    final textCol = lang == 'hi' ? 3 : 2;
    // Column weights: entry_id, label, en, hi, transliteration, sanskrit,
    // purport.
    const rank = 'bm25(entries, 0, 2, 10, 10, 5, 3, 1)';
    try {
      final main = _db.select(
        'SELECT e.entry_id, c.chapter, c.label, c.translation_hi, '
        "snippet(entries, $textCol, char(1), char(2), '…', 14) AS snip, "
        "snippet(entries, 2, char(1), char(2), '…', 14) AS snip_en "
        'FROM entries e JOIN catalogue c ON c.ord = e.rowid '
        'WHERE entries MATCH ? ORDER BY $rank LIMIT ?',
        [
          '{label translation_en translation_hi transliteration sanskrit} : '
              '($expr)',
          resultLimit,
        ],
      );
      final seen = <String>{};
      final translation = <SearchHit>[];
      for (final r in main) {
        final id = r['entry_id'] as String;
        seen.add(id);
        final hasHi = (r['translation_hi'] as String?)?.isNotEmpty ?? false;
        translation.add(
          SearchHit(
            id: id,
            chapter: r['chapter'] as int,
            label: r['label'] as String,
            snippet:
                (lang == 'hi' && hasHi ? r['snip'] : r['snip_en']) as String,
            inPurport: false,
          ),
        );
      }
      final purportRows = _db.select(
        'SELECT e.entry_id, c.chapter, c.label, '
        "snippet(entries, 6, char(1), char(2), '…', 16) AS snip "
        'FROM entries e JOIN catalogue c ON c.ord = e.rowid '
        'WHERE entries MATCH ? ORDER BY $rank LIMIT ?',
        ['purport : ($expr)', resultLimit],
      );
      final purport = [
        for (final r in purportRows)
          if (!seen.contains(r['entry_id']))
            SearchHit(
              id: r['entry_id'] as String,
              chapter: r['chapter'] as int,
              label: r['label'] as String,
              snippet: r['snip'] as String,
              inPurport: true,
            ),
      ];
      return SearchResults(translation, purport);
    } on SqliteException {
      return SearchResults.empty;
    }
  }

  void close() => _db.close();
}
