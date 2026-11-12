/// Word-for-word meanings ("synonyms" in the source edition).
///
/// The text always comes from the authorised source through the importer;
/// this file only splits it into pairs. It never changes a word or meaning.
library;

class WordMeaning {
  const WordMeaning({required this.word, required this.meaning});

  final String word;
  final String meaning;

  factory WordMeaning.fromJson(Map<String, dynamic> json) => WordMeaning(
    word: json['word'] as String,
    meaning: json['meaning'] as String,
  );

  Map<String, String> toJson() => {'word': word, 'meaning': meaning};

  @override
  bool operator ==(Object other) =>
      other is WordMeaning && other.word == word && other.meaning == meaning;

  @override
  int get hashCode => Object.hash(word, meaning);

  @override
  String toString() => '$word—$meaning';
}

/// The result of splitting one source string. [pairs] is null when any pair
/// could not be split; [problems] then lists each one verbatim.
class WordMeaningsParse {
  const WordMeaningsParse(this.pairs, this.problems);

  final List<WordMeaning>? pairs;
  final List<String> problems;

  bool get ok => pairs != null;
}

const _pairSeparator = ';';
const _wordSeparator = '—'; // em dash

/// Splits the source format `word—meaning; word—meaning; ...`.
///
/// Each pair must contain exactly one em dash with text on both sides.
/// Anything else is reported, never guessed. [clean] turns the source's
/// inline markup into plain text (the importer passes its own cleaner).
WordMeaningsParse parseWordMeanings(
  String raw, {
  String Function(String text)? clean,
}) {
  final tidy = clean ?? (String s) => s.trim();
  final pairs = <WordMeaning>[];
  final problems = <String>[];
  for (final part in raw.split(_pairSeparator)) {
    final p = part.trim();
    if (p.isEmpty) continue; // a trailing separator, not text
    final dashes = _wordSeparator.allMatches(p).length;
    if (dashes != 1) {
      problems.add(p);
      continue;
    }
    final i = p.indexOf(_wordSeparator);
    final word = tidy(p.substring(0, i)).trim();
    final meaning = tidy(p.substring(i + _wordSeparator.length)).trim();
    if (word.isEmpty || meaning.isEmpty) {
      problems.add(p);
      continue;
    }
    pairs.add(WordMeaning(word: word, meaning: meaning));
  }
  if (pairs.isEmpty && problems.isEmpty) problems.add('(no pairs)');
  return WordMeaningsParse(problems.isEmpty ? pairs : null, problems);
}
