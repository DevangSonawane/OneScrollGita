import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/models/verse_entry.dart';
import 'package:versescroll/domain/word_meanings.dart';

void main() {
  group('parseWordMeanings', () {
    test('splits pairs on ; and the first em dash, text unchanged', () {
      final r = parseWordMeanings('a—one; b-c—two, three; ');
      expect(r.ok, isTrue);
      expect(r.pairs, const [
        WordMeaning(word: 'a', meaning: 'one'),
        WordMeaning(word: 'b-c', meaning: 'two, three'),
      ]);
    });

    test('uses the given cleaner for inline markup', () {
      final r = parseWordMeanings(
        '*ka*—the *x*',
        clean: (s) => s.replaceAll('*', ''),
      );
      expect(r.pairs!.single, const WordMeaning(word: 'ka', meaning: 'the x'));
    });

    test('a pair with no dash or two dashes is reported, never guessed', () {
      final r = parseWordMeanings('a—one; b; c—x, d—y');
      expect(r.ok, isFalse);
      expect(r.pairs, isNull);
      expect(r.problems, ['b', 'c—x, d—y']);
    });

    test('empty word or meaning and empty input are reported', () {
      expect(parseWordMeanings('—one').ok, isFalse);
      expect(parseWordMeanings('a— ').ok, isFalse);
      expect(parseWordMeanings('  ').problems, ['(no pairs)']);
    });
  });

  group('VerseEntry.wordMeaningsFor', () {
    const en = [WordMeaning(word: 'karmaṇi', meaning: 'duties')];
    const hi = [WordMeaning(word: 'कर्मणि', meaning: 'कर्तव्यों में')];
    VerseEntry make({List<WordMeaning>? hiList}) => VerseEntry(
      id: 'bg-02-047',
      chapter: 2,
      verseStart: 47,
      verseEnd: 47,
      label: '2.47',
      sanskrit: const [],
      transliteration: const [],
      translationEn: 'en',
      translationHi: 'hi',
      wordMeaningsEn: en,
      wordMeaningsHi: hiList,
    );

    test('Hindi list when present', () {
      final r = make(hiList: hi).wordMeaningsFor('hi');
      expect(r.pairs, hi);
      expect(r.isEnglishFallback, isFalse);
    });

    test('English fallback when the Hindi list is missing', () {
      final r = make().wordMeaningsFor('hi');
      expect(r.pairs, en);
      expect(r.isEnglishFallback, isTrue);
      expect(make().wordMeaningsFor('en').isEnglishFallback, isFalse);
    });

    test('fromJson reads both lists', () {
      final e = VerseEntry.fromJson({
        'id': 'bg-02-047',
        'chapter': 2,
        'verseStart': 47,
        'verseEnd': 47,
        'label': '2.47',
        'sanskrit': ['क'],
        'transliteration': ['ka'],
        'translation': {'en': 'e', 'hi': null},
        'purport': null,
        'synonyms': {
          'en': [
            {'word': 'karmaṇi', 'meaning': 'duties'},
          ],
          'hi': null,
        },
      });
      expect(e.wordMeaningsEn, en);
      expect(e.wordMeaningsHi, isNull);
      expect(e.hasWordMeanings, isTrue);
    });
  });
}
