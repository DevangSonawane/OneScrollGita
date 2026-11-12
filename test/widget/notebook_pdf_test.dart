import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/scripture_providers.dart';
import 'package:versescroll/domain/models/study_items.dart';
import 'package:versescroll/domain/notebook.dart';
import 'package:versescroll/features/study/notebook_export.dart';

import '../helpers.dart';

void main() {
  testWidgets('builds a PDF: cover plus one page per item', (tester) async {
    final app = await pumpApp(tester);
    final t = DateTime(2026, 11, 12);
    final pages = buildNotebook(
      notes: [
        VerseNote(
          verseId: 'bg-02-047',
          body: 'Do the work. Let go of the result.',
          createdAt: t,
          updatedAt: t,
        ),
      ],
      highlights: [
        VerseHighlight(
          verseId: 'bg-02-047',
          color: HighlightColor.saffron,
          updatedAt: t,
        ),
      ],
      journal: [
        JournalEntry(
          id: 1,
          verseId: 'bg-18-066',
          body: 'Surrender is not giving up.',
          createdAt: t,
          updatedAt: t,
        ),
      ],
      options: const NotebookOptions(),
    );
    final container = app.container;
    final index = (await tester.runAsync(
      () => container.read(chaptersIndexProvider.future),
    ))!;
    final repo = container.read(scriptureRepositoryProvider);
    final context = tester.element(find.byType(Navigator).first);
    final built = (await tester.runAsync(
      () => buildNotebookPdf(
        context,
        pages: pages,
        index: index,
        lang: 'en',
        now: t,
        entryOf: repo.entryById,
      ),
    ))!;
    expect(built.pngs, hasLength(3)); // cover, 2.47, journal
    final head = latin1.decode(built.pdf.sublist(0, 5));
    expect(head, '%PDF-');
    // Three pages in the PDF's page tree.
    final text = latin1.decode(built.pdf);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text).length, 3);
  });
}
