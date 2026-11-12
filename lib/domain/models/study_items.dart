/// The user's own study layer (PRD_v3 section 6). Never scripture text.
library;

enum HighlightColor {
  saffron,
  leaf,
  sky,
  lotus;

  static HighlightColor? fromName(String? name) =>
      values.where((c) => c.name == name).firstOrNull;

  String get label => switch (this) {
    HighlightColor.saffron => 'Saffron',
    HighlightColor.leaf => 'Leaf',
    HighlightColor.sky => 'Sky',
    HighlightColor.lotus => 'Lotus',
  };
}

class VerseHighlight {
  const VerseHighlight({
    required this.verseId,
    required this.color,
    required this.updatedAt,
  });

  final String verseId;
  final HighlightColor color;
  final DateTime updatedAt;
}

/// Limits on what a user can type (PRD_v3 section 4).
abstract final class StudyLimits {
  static const noteMaxChars = 4000;
  static const journalMaxChars = 10000;

  /// The character counter appears this close to the limit.
  static const counterWithin = 400;
}

class VerseNote {
  const VerseNote({
    required this.verseId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final String verseId;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.verseId,
  });

  final int id;
  final String? verseId;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// First lines of a text for list previews, without breaking words badly.
String previewOf(String text, {int maxChars = 140}) {
  final t = text.trim().replaceAll(RegExp(r'\s*\n\s*'), ' · ');
  if (t.length <= maxChars) return t;
  final cut = t.substring(0, maxChars);
  final space = cut.lastIndexOf(' ');
  return '${space > maxChars * 0.6 ? cut.substring(0, space) : cut}…';
}
