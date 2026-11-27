import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/scripture/scripture_repository.dart';

import '../../tool/build_watch_scripture.dart';

/// The Apple Watch ships its own copy of the verse text
/// (docs/PRD_v10.md section 3). It must be exactly the app's text.
void main() {
  test('watch scripture file is up to date with assets/scripture', () {
    final committed = File(watchScripturePath).readAsStringSync();
    expect(
      committed == buildFromAssets(),
      isTrue,
      reason: 'Run: dart run tool/build_watch_scripture.dart',
    );
  });

  test('every watch entry matches the app entry, in the same order', () {
    final watch = jsonDecode(
      File(watchScripturePath).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(watch['isPlaceholder'], isFalse);
    final entries = (watch['entries'] as List).cast<Map<String, dynamic>>();
    var i = 0;
    for (var c = 1; c <= 18; c++) {
      final raw = File(
        'assets/scripture/chapter_${c.toString().padLeft(2, '0')}.json',
      ).readAsStringSync();
      for (final e in parseChapterJson(raw)) {
        final w = entries[i++];
        expect(w['id'], e.id);
        expect(w['chapter'], e.chapter);
        expect(w['verseStart'], e.verseStart);
        expect(w['verseEnd'], e.verseEnd);
        expect(w['label'], e.label);
        expect(w['sanskrit'], e.sanskrit);
        expect(w['transliteration'], e.transliteration);
        expect(w['en'], e.translationEn);
        expect(w['hi'], e.translationHi);
      }
    }
    expect(i, entries.length);
  });

  test('refuses placeholder data', () {
    expect(
      () => buildWatchScripture(
        jsonEncode({
          'isPlaceholder': true,
          'chapters': <Object>[],
          'source': <String, Object>{},
        }),
        const {},
      ),
      throwsStateError,
    );
  });
}
