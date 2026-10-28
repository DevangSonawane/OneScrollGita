import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/models/verse_entry.dart';
import 'package:versescroll/domain/verse_navigation.dart';

VerseEntry _e(int c, int s, [int? end]) => VerseEntry(
  id: formatVerseId(c, s, end),
  chapter: c,
  verseStart: s,
  verseEnd: end ?? s,
  label: formatLabel(c, s, end ?? s),
  sanskrit: const ['क'],
  transliteration: const ['ka'],
  translationEn: 'en',
  translationHi: 'hi',
);

void main() {
  final entries = [_e(1, 1), _e(1, 2), _e(1, 3, 5), _e(1, 6)];

  test('ids and labels', () {
    expect(formatVerseId(2, 47), 'bg-02-047');
    expect(formatVerseId(1, 16, 18), 'bg-01-016-018');
    expect(formatLabel(1, 16, 18), '1.16-18');
    expect(parseVerseId('bg-01-016-018'), (chapter: 1, verseStart: 16, verseEnd: 18));
    expect(parseVerseId('bg-1-16'), isNull);
    expect(chapterOfId('bg-18-078'), 18);
  });

  test('index lookup finds exact ids and verses inside ranges', () {
    expect(indexOfId(entries, 'bg-01-002'), 1);
    expect(indexOfId(entries, 'bg-01-003-005'), 2);
    expect(indexOfId(entries, 'bg-01-004'), 2); // inside the range
    expect(indexOfId(entries, 'bg-01-099'), -1);
  });

  test('previous and next stop at chapter edges', () {
    expect(previousInChapter(entries, 0), isNull);
    expect(nextInChapter(entries, 1)!.id, 'bg-01-003-005');
    expect(nextInChapter(entries, 3), isNull);
    expect(isLastInChapter(entries, 3), isTrue);
    expect(nextChapter(17), 18);
    expect(nextChapter(18), isNull);
    expect(previousChapter(1), isNull);
  });

  test('short labels', () {
    expect(shortLabel(entries[2]), '3-5');
    expect(shortLabel(entries[0]), '1');
  });
}
