import 'models/verse_entry.dart';

const chapterCount = 18;

final _idPattern = RegExp(r'^bg-(\d{2})-(\d{3})(?:-(\d{3}))?$');

typedef ParsedVerseId = ({int chapter, int verseStart, int verseEnd});

/// Parses `bg-CC-VVV` or `bg-CC-VVV-WWW`. Returns null for anything else.
ParsedVerseId? parseVerseId(String id) {
  final m = _idPattern.firstMatch(id);
  if (m == null) return null;
  final start = int.parse(m.group(2)!);
  return (
    chapter: int.parse(m.group(1)!),
    verseStart: start,
    verseEnd: m.group(3) == null ? start : int.parse(m.group(3)!),
  );
}

String formatVerseId(int chapter, int verseStart, [int? verseEnd]) {
  String pad(int n, int w) => n.toString().padLeft(w, '0');
  final base = 'bg-${pad(chapter, 2)}-${pad(verseStart, 3)}';
  return verseEnd == null || verseEnd == verseStart
      ? base
      : '$base-${pad(verseEnd, 3)}';
}

String formatLabel(int chapter, int verseStart, int verseEnd) =>
    verseEnd == verseStart
    ? '$chapter.$verseStart'
    : '$chapter.$verseStart-$verseEnd';

/// The label without the chapter prefix ("47" or "16-18").
String shortLabel(VerseEntry e) =>
    e.isRange ? '${e.verseStart}-${e.verseEnd}' : '${e.verseStart}';

int? chapterOfId(String id) => parseVerseId(id)?.chapter;

/// Index of the entry with [id], or of the range entry containing the verse
/// the id points at. -1 if not found.
int indexOfId(List<VerseEntry> entries, String id) {
  final exact = entries.indexWhere((e) => e.id == id);
  if (exact >= 0) return exact;
  final parsed = parseVerseId(id);
  if (parsed == null) return -1;
  return entries.indexWhere(
    (e) =>
        e.chapter == parsed.chapter &&
        e.verseStart <= parsed.verseStart &&
        e.verseEnd >= parsed.verseStart,
  );
}

VerseEntry? previousInChapter(List<VerseEntry> entries, int index) =>
    index > 0 && index < entries.length ? entries[index - 1] : null;

VerseEntry? nextInChapter(List<VerseEntry> entries, int index) =>
    index >= 0 && index < entries.length - 1 ? entries[index + 1] : null;

bool isLastInChapter(List<VerseEntry> entries, int index) =>
    index == entries.length - 1;

/// The chapter after [chapter], or null after the last chapter.
int? nextChapter(int chapter) => chapter < chapterCount ? chapter + 1 : null;

int? previousChapter(int chapter) => chapter > 1 ? chapter - 1 : null;
