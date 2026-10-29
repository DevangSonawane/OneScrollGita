/// Query normalisation shared by keyword and situation search (PRD_v2
/// sections 10 and 11): lowercase, trim, diacritics removed.
library;

const _fold = {
  'ā': 'a',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'ī': 'i',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ū': 'u',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ē': 'e',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'ō': 'o',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ṛ': 'r',
  'ṝ': 'r',
  'ḷ': 'l',
  'ḹ': 'l',
  'ṁ': 'm',
  'ṃ': 'm',
  'ṅ': 'n',
  'ñ': 'n',
  'ṇ': 'n',
  'ń': 'n',
  'ṭ': 't',
  'ḍ': 'd',
  'ś': 's',
  'ṣ': 's',
  'ḥ': 'h',
  'ç': 'c',
};

/// Lowercase, trimmed, Latin diacritics removed, inner spaces collapsed.
/// Devanagari is left as it is.
String normalizeQuery(String input) {
  final lower = input.toLowerCase().trim();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_fold[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Words of a normalised query (letters, digits and Devanagari marks).
List<String> queryWords(String normalized) => [
  for (final w in normalized.split(
    RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true),
  ))
    if (w.isNotEmpty) w,
];
