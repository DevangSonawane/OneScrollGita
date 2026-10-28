import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/models/chapter.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/verse_navigation.dart';
import 'scripture_validator.dart' show chapterFileName;

/// Reads the bundled scripture. Chapters load on demand, are parsed in a
/// background isolate and the last few are kept in memory.
class ScriptureRepository {
  ScriptureRepository({
    AssetBundle? bundle,
    this.cacheSize = 3,
    this.parseInIsolate = true,
  }) : _bundle = bundle ?? rootBundle;

  static const basePath = 'assets/scripture';

  final AssetBundle _bundle;
  final int cacheSize;

  /// Off in widget tests, where isolates do not run under fake time.
  final bool parseInIsolate;

  Future<ChaptersIndex>? _index;
  final _cache = <int, List<VerseEntry>>{}; // insertion-ordered: LRU
  final _inFlight = <int, Future<List<VerseEntry>>>{};

  Future<ChaptersIndex> chapters() => _index ??= _loadIndex();

  Future<ChaptersIndex> _loadIndex() async {
    try {
      final raw = await _bundle.loadString('$basePath/chapters.json');
      return ChaptersIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _index = null; // allow retry
      rethrow;
    }
  }

  /// All entries of [chapter], in order.
  Future<List<VerseEntry>> chapterEntries(int chapter) {
    final cached = _cache.remove(chapter);
    if (cached != null) {
      _cache[chapter] = cached; // mark most recent
      return SynchronousFuture(cached);
    }
    // Block body: returning the removed future here would make whenComplete
    // wait on itself.
    return _inFlight[chapter] ??= _loadChapter(chapter).whenComplete(() {
      _inFlight.remove(chapter);
    });
  }

  /// Entries of [chapter] if already parsed, without loading.
  List<VerseEntry>? cachedEntries(int chapter) => _cache[chapter];

  /// Warms the cache for [chapter] (used for the next chapter).
  void preload(int? chapter) {
    if (chapter == null || chapter < 1 || chapter > chapterCount) return;
    if (_cache.containsKey(chapter)) return;
    chapterEntries(chapter).ignore();
  }

  Future<List<VerseEntry>> _loadChapter(int chapter) async {
    final raw = await _bundle.loadString(
      '$basePath/${chapterFileName(chapter)}',
      cache: false,
    );
    final entries = parseInIsolate
        ? await compute(parseChapterJson, raw)
        : parseChapterJson(raw);
    _cache[chapter] = entries;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return entries;
  }

  Future<VerseEntry?> entryById(String id) async {
    final chapter = chapterOfId(id);
    if (chapter == null || chapter < 1 || chapter > chapterCount) return null;
    final entries = await chapterEntries(chapter);
    final i = indexOfId(entries, id);
    return i < 0 ? null : entries[i];
  }

  Future<bool> exists(String id) async {
    final chapter = chapterOfId(id);
    if (chapter == null || chapter < 1 || chapter > chapterCount) return false;
    final entries = await chapterEntries(chapter);
    return entries.any((e) => e.id == id);
  }

  /// The entry at a global index across all chapters (for the daily verse).
  Future<VerseEntry> entryAtGlobalIndex(int globalIndex) async {
    final index = await chapters();
    final loc = index.locateGlobalIndex(globalIndex);
    final entries = await chapterEntries(loc.chapter);
    return entries[loc.index];
  }
}

/// Top-level so it can run in an isolate.
List<VerseEntry> parseChapterJson(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['entries'] as List)
      .map((e) => VerseEntry.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}
