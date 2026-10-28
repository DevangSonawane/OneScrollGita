import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/markup.dart';
import '../../domain/verse_navigation.dart';

/// Structural validator for the bundled scripture (PRD section 3).
///
/// Pure Dart so it runs from `tool/validate_scripture.dart`, CI and tests.
/// It never changes data; it only reports.
class ValidationReport {
  final errors = <String>[];
  final warnings = <String>[];

  bool get ok => errors.isEmpty;

  @override
  String toString() {
    final b = StringBuffer();
    for (final e in errors) {
      b.writeln('ERROR   $e');
    }
    for (final w in warnings) {
      b.writeln('WARNING $w');
    }
    b.write(ok ? 'PASS' : 'FAIL');
    b.write(' (${errors.length} errors, ${warnings.length} warnings)');
    return b.toString();
  }
}

String chapterFileName(int chapter) =>
    'chapter_${chapter.toString().padLeft(2, '0')}.json';

String sha256Of(String raw) => sha256.convert(utf8.encode(raw)).toString();

final _devanagari = RegExp(r'[ऀ-ॿ]');
final _hidden = RegExp(
  r'[\u0000-\u0008\u000B\u000C\u000E-\u001F­​⁠﻿]',
);

/// [indexRaw] is the text of chapters.json, [chapterFiles] maps file names to
/// their raw text, [expectedCountsRaw] is tool/expected_counts.json.
ValidationReport validateScripture({
  required String indexRaw,
  required Map<String, String> chapterFiles,
  required String expectedCountsRaw,
  bool release = false,
}) {
  final r = ValidationReport();

  Map<String, dynamic> index;
  Map<String, dynamic> expected;
  try {
    index = jsonDecode(indexRaw) as Map<String, dynamic>;
  } catch (e) {
    r.errors.add('chapters.json is not valid JSON: $e');
    return r;
  }
  try {
    expected = jsonDecode(expectedCountsRaw) as Map<String, dynamic>;
  } catch (e) {
    r.errors.add('expected_counts.json is not valid JSON: $e');
    return r;
  }

  // Placeholder data.
  if (index['isPlaceholder'] == true) {
    if (release) {
      r.errors.add('Placeholder data is present (isPlaceholder: true).');
    } else {
      r.warnings.add('Dataset is placeholder data (dev only).');
    }
  }
  if (expected['approved'] != true) {
    r.warnings.add('expected_counts.json has not been approved by the owner.');
  }

  // Source and attribution block.
  final source = index['source'];
  if (source is! Map<String, dynamic>) {
    r.errors.add('Source block is missing.');
  } else {
    for (final key in const [
      'name',
      'edition',
      'rightsHolder',
      'attribution',
      'datasetVersion',
    ]) {
      final v = source[key];
      if (v is! String || v.trim().isEmpty) {
        r.errors.add('Source block field "$key" is missing or empty.');
      }
    }
  }
  final checksums = source is Map<String, dynamic>
      ? source['checksums'] as Map<String, dynamic>?
      : null;
  if (checksums == null) r.errors.add('Source block has no checksums.');

  // Chapters.
  final chapters = index['chapters'];
  if (chapters is! List) {
    r.errors.add('chapters.json has no "chapters" list.');
    return r;
  }
  if (chapters.length != chapterCount) {
    r.errors.add('Expected $chapterCount chapters, found ${chapters.length}.');
  }
  final expectedPer = <int, Map<String, dynamic>>{
    for (final c in (expected['perChapter'] as List? ?? const []))
      (c as Map<String, dynamic>)['chapter'] as int: c,
  };

  var totalVerses = 0;
  final seenIds = <String>{};
  for (var i = 0; i < chapters.length; i++) {
    final c = chapters[i] as Map<String, dynamic>;
    final number = c['number'];
    if (number != i + 1) {
      r.errors.add('Chapter at position ${i + 1} has number $number.');
      continue;
    }
    final n = number as int;
    if ((c['titleEn'] as String?)?.trim().isEmpty ?? true) {
      r.errors.add('Chapter $n has no English title.');
    }
    final file = chapterFileName(n);
    final raw = chapterFiles[file];
    if (raw == null) {
      r.errors.add('Missing file $file.');
      continue;
    }
    final declaredSum = checksums?[file];
    if (checksums != null && declaredSum != sha256Of(raw)) {
      r.errors.add('Checksum mismatch for $file.');
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      r.errors.add('$file is not valid JSON: $e');
      continue;
    }
    if (data['chapter'] != n) {
      r.errors.add('$file declares chapter ${data['chapter']}.');
    }
    final entries = data['entries'] as List? ?? const [];
    final verses = _validateEntries(r, n, entries, seenIds);
    totalVerses += verses;

    if (c['verseCount'] != verses) {
      r.errors.add(
        'Chapter $n: chapters.json says ${c['verseCount']} verses, '
        'file has $verses.',
      );
    }
    if (c['entryCount'] != entries.length) {
      r.errors.add(
        'Chapter $n: chapters.json says ${c['entryCount']} entries, '
        'file has ${entries.length}.',
      );
    }
    final exp = expectedPer[n];
    if (exp == null) {
      r.errors.add('expected_counts.json has no entry for chapter $n.');
    } else {
      if (exp['verses'] != verses) {
        r.errors.add(
          'Chapter $n: expected ${exp['verses']} verses, found $verses.',
        );
      }
      if (exp['entries'] != null && exp['entries'] != entries.length) {
        r.errors.add(
          'Chapter $n: expected ${exp['entries']} entries, '
          'found ${entries.length}.',
        );
      }
    }
  }
  final expectedTotal = expected['totalVerses'];
  if (expectedTotal != totalVerses) {
    r.errors.add('Expected $expectedTotal verses in total, found $totalVerses.');
  }
  return r;
}

/// Validates one chapter's entries and returns its individual verse count.
int _validateEntries(
  ValidationReport r,
  int chapter,
  List<dynamic> entries,
  Set<String> seenIds,
) {
  var expectedStart = 1;
  var verses = 0;
  var missingHindi = 0;
  for (final raw in entries) {
    final e = raw as Map<String, dynamic>;
    final id = e['id'];
    final where = 'Chapter $chapter, entry ${id ?? '?'}';
    final start = e['verseStart'];
    final end = e['verseEnd'];
    if (start is! int || end is! int || end < start) {
      r.errors.add('$where: invalid verseStart/verseEnd ($start, $end).');
      continue;
    }
    if (e['chapter'] != chapter) {
      r.errors.add('$where: chapter field is ${e['chapter']}.');
    }
    if (start != expectedStart) {
      r.errors.add(
        start > expectedStart
            ? '$where: gap, expected verse $expectedStart next, got $start.'
            : '$where: overlap or out of order, expected verse '
                  '$expectedStart next, got $start.',
      );
    }
    expectedStart = end + 1;
    verses += end - start + 1;

    if (id is! String || id != formatVerseId(chapter, start, end)) {
      r.errors.add(
        '$where: id should be ${formatVerseId(chapter, start, end)}.',
      );
    } else if (!seenIds.add(id)) {
      r.errors.add('$where: duplicate id.');
    }
    if (e['label'] != formatLabel(chapter, start, end)) {
      r.errors.add(
        '$where: label "${e['label']}" should be '
        '"${formatLabel(chapter, start, end)}".',
      );
    }

    final sanskrit = _lines(e['sanskrit']);
    final translit = _lines(e['transliteration']);
    if (sanskrit == null) {
      r.errors.add('$where: Sanskrit is empty.');
    } else if (!sanskrit.every(_devanagari.hasMatch)) {
      r.errors.add('$where: Sanskrit line without Devanagari characters.');
    }
    if (translit == null) {
      r.errors.add('$where: transliteration is empty.');
    } else if (translit.any(_devanagari.hasMatch)) {
      r.errors.add('$where: transliteration contains Devanagari.');
    }
    final translation = e['translation'];
    for (final lang in const ['en', 'hi']) {
      final t = translation is Map ? translation[lang] : null;
      // A Hindi translation the source does not have is allowed (the app
      // shows English); an empty one is an error.
      if (lang == 'hi' && t == null) {
        missingHindi++;
        continue;
      }
      if (t is! String || t.trim().isEmpty) {
        r.errors.add('$where: translation.$lang is missing or empty.');
      } else {
        _warnText(r, '$where translation.$lang', t);
      }
    }

    final purport = e['purport'];
    if (purport != null) {
      if (purport is! Map) {
        r.errors.add('$where: purport must be an object or null.');
      } else {
        for (final lang in const ['en', 'hi']) {
          final blocks = purport[lang];
          if (blocks == null) continue;
          if (blocks is! List) {
            r.errors.add('$where: purport.$lang must be a list or null.');
            continue;
          }
          for (final b in blocks) {
            final type = b is Map ? b['type'] : null;
            final text = b is Map ? b['text'] : null;
            if (type is! String || !const {'p', 'quote', 'sanskrit'}.contains(type)) {
              r.errors.add('$where: purport.$lang block type "$type".');
            }
            if (text is! String || text.trim().isEmpty) {
              r.errors.add('$where: purport.$lang has an empty block.');
              continue;
            }
            try {
              parseMarkup(text, strict: true);
            } on MarkupException catch (ex) {
              r.errors.add('$where: purport.$lang markup: ${ex.message}.');
            }
            _warnText(r, '$where purport.$lang', text);
          }
        }
      }
    }
  }
  if (missingHindi > 0) {
    r.warnings.add(
      'Chapter $chapter: $missingHindi entries have no Hindi translation.',
    );
  }
  return verses;
}

List<String>? _lines(Object? v) {
  if (v is! List || v.isEmpty) return null;
  final lines = v.whereType<String>().toList();
  if (lines.length != v.length || lines.any((l) => l.trim().isEmpty)) {
    return null;
  }
  return lines;
}

void _warnText(ValidationReport r, String where, String text) {
  if (_hidden.hasMatch(text)) {
    r.warnings.add('$where: hidden characters.');
  }
  if (text.contains('  ')) {
    r.warnings.add('$where: doubled spaces.');
  }
  final straight = '"'.allMatches(text).length;
  final open = '“'.allMatches(text).length;
  final close = '”'.allMatches(text).length;
  if (straight.isOdd || open != close) {
    r.warnings.add('$where: unmatched quotes.');
  }
}
