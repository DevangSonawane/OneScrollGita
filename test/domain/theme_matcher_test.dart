import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/models/written_content.dart';
import 'package:versescroll/domain/search/normalize.dart';
import 'package:versescroll/domain/search/sensitive.dart';
import 'package:versescroll/domain/search/theme_matcher.dart';

void main() {
  final json = jsonDecode(
    File('assets/search/themes.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final themes = [
    for (final t in json['themes'] as List)
      SearchTheme.fromJson(t as Map<String, dynamic>),
  ];
  final m = ThemeMatcher(themes);
  String? top(String q) => m.match(q).firstOrNull?.id;

  test('normalise removes diacritics', () {
    expect(normalizeQuery('  Kṛṣṇa  Gītā '), 'krsna gita');
  });

  test('exact, prefix and fuzzy', () {
    expect(top('sadness'), 'sadness');
    expect(top('Anger'), 'anger');
    expect(top('sadnes'), 'sadness'); // prefix
    expect(top('sadnss'), 'sadness'); // edit distance 1
  });

  test('Hindi and Hinglish synonyms', () {
    expect(top('udaas'), 'sadness');
    expect(top('gussa'), 'anger');
    expect(top('क्रोध'), 'anger');
  });

  test('multi-word: free thinking', () {
    expect(top('free thinking'), 'freedom');
    expect(top('feeling sad today'), isNotNull);
  });

  test('no match', () {
    expect(m.match('zzqx'), isEmpty);
  });

  test('sensitive queries, whole words only', () {
    expect(isSensitiveQuery('I want to die'), isTrue);
    expect(isSensitiveQuery('aatmahatya'), isTrue);
    expect(isSensitiveQuery('आत्महत्या'), isTrue);
    expect(isSensitiveQuery('grapes'), isFalse);
    expect(isSensitiveQuery('anger'), isFalse);
    for (final id in sensitiveFallbackThemes) {
      expect(themes.any((t) => t.id == id), isTrue, reason: id);
    }
  });

  test('edit distance', () {
    expect(editDistanceAtMostOne('peace', 'peaces'), isTrue);
    expect(editDistanceAtMostOne('peace', 'place'), isTrue);
    expect(editDistanceAtMostOne('peace', 'plate'), isFalse);
  });
}
