import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/search/search_index.dart';

void main() {
  late SearchIndex index;
  setUpAll(() {
    final jsons = [
      for (var c = 1; c <= 18; c++)
        File('assets/scripture/chapter_${c.toString().padLeft(2, '0')}.json')
            .readAsStringSync(),
    ];
    final aliases = Map<String, String>.from(
      (jsonDecode(File('assets/search/aliases.json').readAsStringSync())
              as Map)['aliases']
          as Map,
    );
    index = SearchIndex.memory(jsons, aliases: aliases);
  });
  tearDownAll(() => index.close());

  test('catalogue has every entry in order', () {
    final c = index.catalogue();
    expect(c.length, greaterThan(600));
    expect(c.first.id, 'bg-01-001');
  });

  test('diacritics: kṛṣṇa and krsna match', () {
    expect(index.search('kṛṣṇa', lang: 'en').isEmpty, isFalse);
    expect(index.search('krsna', lang: 'en').isEmpty, isFalse);
  });

  test('alias: krishna matches kṛṣṇa', () {
    expect(index.search('krishna', lang: 'en').translation, isNotEmpty);
    expect(index.search('arjun', lang: 'en').translation, isNotEmpty);
  });

  test('prefix of the word being typed', () {
    expect(index.search('compass', lang: 'en').translation, isNotEmpty);
  });

  test('Hindi words', () {
    expect(index.search('अर्जुन', lang: 'hi').translation, isNotEmpty);
  });

  test('snippets mark matches; purport matches separate', () {
    final r = index.search('anger', lang: 'en');
    expect(r.translation.first.snippet, contains(SearchHit.hitStart));
    final ids = {for (final h in r.translation) h.id};
    expect(r.purport.any((h) => ids.contains(h.id)), isFalse);
  });

  test('junk input is safe', () {
    expect(index.search('"*(', lang: 'en').isEmpty, isTrue);
    expect(index.search('', lang: 'en').isEmpty, isTrue);
  });
}
