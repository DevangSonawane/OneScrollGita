import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/models/study_items.dart';
import 'package:versescroll/domain/notebook.dart';

void main() {
  final t = DateTime(2026, 11, 12);
  VerseNote note(String id) =>
      VerseNote(verseId: id, body: 'n $id', createdAt: t, updatedAt: t);
  JournalEntry j(int id, int day) => JournalEntry(
    id: id,
    body: 'j$id',
    createdAt: DateTime(2026, 11, day),
    updatedAt: t,
  );

  test('verse pages in Gita order, notes and highlights merged, then journal '
      'oldest first', () {
    final pages = buildNotebook(
      notes: [note('bg-18-066'), note('bg-02-047')],
      highlights: [
        VerseHighlight(
          verseId: 'bg-02-047',
          color: HighlightColor.sky,
          updatedAt: t,
        ),
        VerseHighlight(
          verseId: 'bg-01-016-018',
          color: HighlightColor.leaf,
          updatedAt: t,
        ),
      ],
      journal: [j(2, 11), j(1, 3)],
      options: const NotebookOptions(),
    );
    final verses = pages.whereType<VersePage>().toList();
    expect(verses.map((p) => p.verseId), [
      'bg-01-016-018',
      'bg-02-047',
      'bg-18-066',
    ]);
    expect(verses[1].note!.body, 'n bg-02-047');
    expect(verses[1].highlight, HighlightColor.sky);
    expect(verses[0].note, isNull);
    expect(pages.whereType<JournalPage>().map((p) => p.entry.id), [1, 2]);
  });

  test('options leave parts out', () {
    final pages = buildNotebook(
      notes: [note('bg-02-047')],
      highlights: [
        VerseHighlight(
          verseId: 'bg-03-001',
          color: HighlightColor.lotus,
          updatedAt: t,
        ),
      ],
      journal: [j(1, 1)],
      options: const NotebookOptions(highlights: false, journal: false),
    );
    expect(pages, hasLength(1));
    expect((pages.single as VersePage).verseId, 'bg-02-047');
    expect(
      const NotebookOptions(
        notes: false,
        highlights: false,
        journal: false,
      ).any,
      isFalse,
    );
  });

  test('previewOf joins lines and cuts long text at a word', () {
    expect(previewOf('a\n\nb'), 'a · b');
    final long = List.filled(60, 'word').join(' ');
    final p = previewOf(long);
    expect(p.length, lessThanOrEqualTo(141));
    expect(p.endsWith('…'), isTrue);
  });
}
