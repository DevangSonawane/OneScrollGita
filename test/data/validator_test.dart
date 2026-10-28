import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/scripture/scripture_validator.dart';

/// A small valid dataset; each test breaks one rule.
class Fixture {
  Fixture() {
    for (var c = 1; c <= 18; c++) {
      final verses = c == 1 ? 5 : 2;
      final entries = <Map<String, dynamic>>[];
      var v = 1;
      while (v <= verses) {
        final end = c == 1 && v == 2 ? 4 : v; // one range 1.2-4
        entries.add(entry(c, v, end));
        v = end + 1;
      }
      chapters[c] = {'chapter': c, 'entries': entries};
      (index['chapters'] as List).add({
        'number': c,
        'titleEn': 'Chapter $c',
        'titleHi': null,
        'verseCount': verses,
        'entryCount': entries.length,
      });
      (expected['perChapter'] as List).add({
        'chapter': c,
        'verses': verses,
        'entries': entries.length,
      });
    }
    expected['totalVerses'] = 5 + 17 * 2;
  }

  final chapters = <int, Map<String, dynamic>>{};
  final Map<String, dynamic> index = {
    'source': <String, dynamic>{
      'name': 'n',
      'edition': 'e',
      'rightsHolder': 'r',
      'attribution': 'a',
      'datasetVersion': '1',
    },
    'chapters': <Map<String, dynamic>>[],
  };
  final Map<String, dynamic> expected = {
    'approved': true,
    'chapters': 18,
    'perChapter': <Map<String, dynamic>>[],
  };

  static Map<String, dynamic> entry(int c, int s, int e) {
    String pad(int n, int w) => n.toString().padLeft(w, '0');
    final id = 'bg-${pad(c, 2)}-${pad(s, 3)}${e == s ? '' : '-${pad(e, 3)}'}';
    return {
      'id': id,
      'chapter': c,
      'verseStart': s,
      'verseEnd': e,
      'label': e == s ? '$c.$s' : '$c.$s-$e',
      'sanskrit': ['धर्म'],
      'transliteration': ['dharma'],
      'translation': {'en': 'English.', 'hi': 'हिन्दी।'},
      'purport': {
        'en': [
          {'type': 'p', 'text': 'A <i>b</i>.'},
        ],
        'hi': null,
      },
      'synonyms': null,
    };
  }

  ValidationReport run({bool release = false, bool fixChecksums = true}) {
    final files = {
      for (final MapEntry(:key, :value) in chapters.entries)
        chapterFileName(key): jsonEncode(value),
    };
    if (fixChecksums) {
      (index['source'] as Map<String, dynamic>)['checksums'] = {
        for (final f in files.entries) f.key: sha256Of(f.value),
      };
    }
    return validateScripture(
      indexRaw: jsonEncode(index),
      chapterFiles: files,
      expectedCountsRaw: jsonEncode(expected),
      release: release,
    );
  }

  Map<String, dynamic> e(int chapter, int i) =>
      (chapters[chapter]!['entries'] as List)[i] as Map<String, dynamic>;
}

void main() {
  test('valid fixture passes', () {
    final r = Fixture().run();
    expect(r.errors, isEmpty, reason: r.toString());
  });

  test('bundled dataset passes in dev and release mode', () {
    final dir = Directory('assets/scripture');
    final files = {
      for (final f in dir.listSync().whereType<File>())
        if (f.path.contains('chapter_')) f.uri.pathSegments.last: f.readAsStringSync(),
    };
    String read(String p) => File(p).readAsStringSync();
    final dev = validateScripture(
      indexRaw: read('assets/scripture/chapters.json'),
      chapterFiles: files,
      expectedCountsRaw: read('tool/expected_counts.json'),
    );
    expect(dev.errors, isEmpty, reason: dev.toString());
    final release = validateScripture(
      indexRaw: read('assets/scripture/chapters.json'),
      chapterFiles: files,
      expectedCountsRaw: read('tool/expected_counts.json'),
      release: true,
    );
    expect(release.errors, isEmpty, reason: release.toString());
  });

  void expectError(Fixture f, String fragment, {bool release = false}) {
    final r = f.run(release: release);
    expect(r.ok, isFalse);
    expect(r.errors.join('\n'), contains(fragment), reason: r.toString());
  }

  test('wrong chapter count', () {
    final f = Fixture();
    (f.index['chapters'] as List).removeLast();
    expectError(f, 'Expected 18 chapters');
  });

  test('verse count mismatch with expected counts', () {
    final f = Fixture();
    (f.expected['perChapter'] as List<Map<String, dynamic>>)[1]['verses'] = 3;
    expectError(f, 'expected 3 verses');
  });

  test('total mismatch', () {
    final f = Fixture()..expected['totalVerses'] = 700;
    expectError(f, 'Expected 700 verses in total');
  });

  test('gap between entries', () {
    final f = Fixture();
    (f.chapters[2]!['entries'] as List).removeAt(0);
    expectError(f, 'gap');
  });

  test('overlapping range', () {
    final f = Fixture();
    f.e(1, 1)
      ..['verseEnd'] = 5
      ..['id'] = 'bg-01-002-005'
      ..['label'] = '1.2-5';
    expectError(f, 'overlap');
  });

  test('id does not match numbers', () {
    final f = Fixture();
    f.e(3, 0)['id'] = 'bg-03-009';
    expectError(f, 'id should be bg-03-001');
  });

  test('duplicate id', () {
    final f = Fixture();
    final list = f.chapters[4]!['entries'] as List;
    list[1] = Map<String, dynamic>.of(list[0] as Map<String, dynamic>)
      ..['verseStart'] = 2
      ..['verseEnd'] = 2
      ..['label'] = '4.2';
    expectError(f, 'id should be bg-04-002');
  });

  test('label mismatch', () {
    final f = Fixture();
    f.e(1, 1)['label'] = '1.2';
    expectError(f, 'label "1.2"');
  });

  test('empty Hindi translation', () {
    final f = Fixture();
    (f.e(5, 0)['translation'] as Map)['hi'] = ' '; // empty, not missing
    expectError(f, 'translation.hi is missing');
  });

  test('Sanskrit without Devanagari and Devanagari in transliteration', () {
    final f = Fixture();
    f.e(6, 0)['sanskrit'] = ['dharma'];
    f.e(6, 1)['transliteration'] = ['धर्म'];
    expectError(f, 'without Devanagari');
    expectError(f, 'transliteration contains Devanagari');
  });

  test('bad purport block type and unbalanced markup', () {
    final f = Fixture();
    ((f.e(7, 0)['purport'] as Map)['en'] as List)[0] = {'type': 'h1', 'text': 'x'};
    ((f.e(7, 1)['purport'] as Map)['en'] as List)[0] = {'type': 'p', 'text': '<i>x'};
    expectError(f, 'block type "h1"');
    expectError(f, 'Unclosed <i>');
  });

  test('checksum mismatch', () {
    final f = Fixture()..run(); // computes checksums
    f.e(8, 0)['translation'] = {'en': 'Edited.', 'hi': 'हिन्दी।'};
    final r = f.run(fixChecksums: false);
    expect(r.errors.join(), contains('Checksum mismatch for chapter_08.json'));
  });

  test('missing source block field', () {
    final f = Fixture();
    (f.index['source'] as Map)['attribution'] = '';
    expectError(f, '"attribution"');
  });

  test('placeholder fails only in release', () {
    final f = Fixture()..index['isPlaceholder'] = true;
    expect(f.run().ok, isTrue);
    expectError(f, 'Placeholder', release: true);
  });

  test('warnings for hidden characters, doubled spaces and quotes', () {
    final f = Fixture();
    (f.e(9, 0)['translation'] as Map)['en'] = 'a​b  c "d';
    final r = f.run();
    expect(r.ok, isTrue);
    final w = r.warnings.join('\n');
    expect(w, contains('hidden characters'));
    expect(w, contains('doubled spaces'));
    expect(w, contains('unmatched quotes'));
  });
}
