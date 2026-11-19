import 'models/written_content.dart';

/// "What brings you to the Gita?" on the guided first launch (PRD_v5
/// section 4). Stored on the phone only.
///
/// Each answer points at a situation-search theme from the bundled dataset
/// (`assets/search/themes.json`); the first verse is that theme's top-ranked
/// verse. The answer-to-theme choice is written content: reviewed:false
/// until the owner checks it (docs/review-needed.md).
enum FirstIntent {
  peace('Peace', 'A calmer mind', 'peace'),
  guidance('Guidance', 'Help with a decision', 'confusion'),
  study('Study', 'Understand the teachings', 'knowledge'),
  heart('Learning by heart', 'Memorise shlokas', 'study');

  const FirstIntent(this.label, this.hint, this.themeId);

  final String label;
  final String hint;
  final String themeId;

  static const reviewed = false;

  static FirstIntent? byName(String? name) =>
      values.where((v) => v.name == name).firstOrNull;
}

/// The first verse for [intent]: the top verse of its theme, or null when the
/// theme is missing (the daily verse is used instead).
String? firstVerseFor(FirstIntent? intent, List<SearchTheme> themes) {
  if (intent == null) return null;
  final t = themes.where((t) => t.id == intent.themeId).firstOrNull;
  return t == null || t.verseIds.isEmpty ? null : t.verseIds.first;
}
