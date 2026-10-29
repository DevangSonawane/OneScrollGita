import 'normalize.dart';

/// Queries about suicide, self-harm, wanting to die or abuse (PRD_v2
/// section 11). English, Hindi and Hinglish. These show a care message
/// first and are never stored in search history.
const _sensitivePhrases = [
  // English
  'suicide', 'suicidal', 'kill myself', 'killing myself', 'end my life',
  'ending my life', 'take my life', 'want to die', 'wanna die',
  'wish i was dead', 'wish i were dead', 'better off dead', 'self harm',
  'self-harm', 'selfharm', 'hurt myself', 'hurting myself', 'cut myself',
  'cutting myself', 'no reason to live', 'dont want to live',
  "don't want to live", 'abuse', 'abused', 'abusive', 'molested',
  'molestation', 'raped', 'rape', 'domestic violence',
  // Hinglish
  'aatmahatya', 'atmahatya', 'aatmhatya', 'atmhatya', 'khudkushi',
  'khudkhushi', 'mar jana', 'marna chahta', 'marna chahti', 'mujhe marna',
  'jeena nahi', 'jina nahi', 'zindagi khatam', 'jaan de', 'khud ko nuksan',
  'shoshan',
  // Hindi
  'आत्महत्या', 'खुदकुशी', 'ख़ुदकुशी', 'मरना चाहता', 'मरना चाहती',
  'मर जाना', 'जीना नहीं', 'जान दे', 'खुद को नुकसान', 'ख़ुद को नुक़सान',
  'शोषण', 'दुर्व्यवहार', 'बलात्कार', 'घरेलू हिंसा',
];

String _words(String s) =>
    ' ${queryWords(normalizeQuery(s.replaceAll("'", ''))).join(' ')} ';

final _normalized = [for (final p in _sensitivePhrases) _words(p)];

/// Whole-word match, so "grapes" is not "rape".
bool isSensitiveQuery(String query) {
  final q = _words(query);
  if (q.trim().isEmpty) return false;
  return _normalized.any(q.contains);
}

/// Themes shown below the care message (by id, when they exist).
const sensitiveFallbackThemes = ['hope', 'shelter', 'courage'];
