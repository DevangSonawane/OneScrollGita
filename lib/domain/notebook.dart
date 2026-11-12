/// What goes into the "My Gita notebook" PDF, and in what order
/// (PRD_v3 section 6). Pure Dart.
library;

import 'models/study_items.dart';
import 'verse_navigation.dart';

class NotebookOptions {
  const NotebookOptions({
    this.notes = true,
    this.highlights = true,
    this.journal = true,
  });

  final bool notes;
  final bool highlights;
  final bool journal;

  bool get any => notes || highlights || journal;
}

sealed class NotebookPage {
  const NotebookPage();
}

/// One verse with the user's note and/or highlight on it.
class VersePage extends NotebookPage {
  const VersePage({required this.verseId, this.note, this.highlight});

  final String verseId;
  final VerseNote? note;
  final HighlightColor? highlight;
}

class JournalPage extends NotebookPage {
  const JournalPage(this.entry);

  final JournalEntry entry;
}

/// Verse pages in Gita order (chapter, then verse), then journal entries
/// oldest first, like a written notebook.
List<NotebookPage> buildNotebook({
  required List<VerseNote> notes,
  required List<VerseHighlight> highlights,
  required List<JournalEntry> journal,
  required NotebookOptions options,
}) {
  final byVerse = <String, ({VerseNote? note, HighlightColor? color})>{};
  if (options.notes) {
    for (final n in notes) {
      byVerse[n.verseId] = (note: n, color: byVerse[n.verseId]?.color);
    }
  }
  if (options.highlights) {
    for (final h in highlights) {
      byVerse[h.verseId] = (note: byVerse[h.verseId]?.note, color: h.color);
    }
  }
  int order(String id) {
    final p = parseVerseId(id);
    return p == null ? 1 << 30 : p.chapter * 1000 + p.verseStart;
  }

  final ids = byVerse.keys.toList()
    ..sort((a, b) => order(a).compareTo(order(b)));
  return [
    for (final id in ids)
      VersePage(
        verseId: id,
        note: byVerse[id]!.note,
        highlight: byVerse[id]!.color,
      ),
    if (options.journal)
      for (final e in [
        ...journal,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
        JournalPage(e),
  ];
}
