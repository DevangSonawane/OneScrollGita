import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/models/verse_entry.dart';

void main() {
  test('Hindi falls back to the English purport and says so', () {
    const e = VerseEntry(
      id: 'bg-01-001',
      chapter: 1,
      verseStart: 1,
      verseEnd: 1,
      label: '1.1',
      sanskrit: [],
      transliteration: [],
      translationEn: 'en',
      translationHi: 'hi',
      purportEn: [PurportBlock(type: PurportBlockType.paragraph, text: 'p')],
    );
    final p = e.purportFor('hi')!;
    expect(p.isEnglishFallback, isTrue);
    expect(e.purportFor('en')!.isEnglishFallback, isFalse);
  });
}
