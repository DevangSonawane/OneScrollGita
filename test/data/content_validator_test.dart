import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/content/content_validator.dart';

void main() {
  test('bundled message bank passes', () {
    final r = validateMessages(
      File('assets/messages/messages.json').readAsStringSync(),
    );
    expect(r.errors, isEmpty);
  });

  test('message rules are enforced', () {
    String doc(Map<String, Object?> m) => jsonEncode({
      'messages': [m],
    });
    final bad = validateMessages(
      doc({
        'id': 'x-1',
        'category': 'invite',
        'title': {'en': 'Krishna is watching you'},
        'body': {'en': 'You must read {name} ${'x' * 140}'},
        'reviewed': false,
      }),
    );
    final text = bad.errors.join('\n');
    expect(text, contains('banned phrase "watching you"'));
    expect(text, contains('banned phrase "you must"'));
    expect(text, contains('unknown placeholder {name}'));
    expect(text, contains('max 140'));
    expect(text, contains('invite: 1 messages'));
    expect(text, contains('No milestone message for day 365'));
  });

  test('bundled summaries pass', () {
    expect(
      validateSummaries(
        File('assets/summaries/summaries.json').readAsStringSync(),
      ).errors,
      isEmpty,
    );
  });

  test('bundled themes pass and every verse id exists', () {
    final ids = <String>{};
    for (var c = 1; c <= 18; c++) {
      final j = jsonDecode(
        File('assets/scripture/chapter_${c.toString().padLeft(2, '0')}.json')
            .readAsStringSync(),
      ) as Map;
      for (final e in j['entries'] as List) {
        ids.add((e as Map)['id'] as String);
      }
    }
    expect(
      validateThemes(
        File('assets/search/themes.json').readAsStringSync(),
        ids,
      ).errors,
      isEmpty,
    );
    expect(
      validateThemes(
        jsonEncode({
          'themes': [
            {
              'id': 'a',
              'title': {'en': 'A'},
              'synonyms': ['a'],
              'verseIds': ['bg-99-001'],
              'reviewed': false,
            },
          ],
        }),
        ids,
      ).errors,
      isNotEmpty,
    );
  });
}
