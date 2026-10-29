import '../models/written_content.dart';
import 'normalize.dart';

/// Situation search (PRD_v2 section 11): matches a query against theme
/// titles and synonyms. Exact, then prefix, then fuzzy (edit distance 1 for
/// words of 5 letters or more). No network, no language model.
class ThemeMatcher {
  ThemeMatcher(List<SearchTheme> themes)
    : _themes = [
        for (final t in themes)
          (
            theme: t,
            phrases: {
              normalizeQuery(t.title.en),
              if (t.title.hi != null) normalizeQuery(t.title.hi!),
              for (final s in t.synonyms) normalizeQuery(s),
            }.where((p) => p.isNotEmpty).toList(),
          ),
      ];

  final List<({SearchTheme theme, List<String> phrases})> _themes;

  /// Themes for [query], best first (at most [limit]).
  List<SearchTheme> match(String query, {int limit = 3}) {
    final q = normalizeQuery(query);
    if (q.length < 2) return const [];
    final qWords = queryWords(q);
    final scored = <({SearchTheme theme, int score})>[];
    for (final t in _themes) {
      var best = 0;
      for (final p in t.phrases) {
        final s = _score(q, qWords, p);
        if (s > best) best = s;
      }
      if (best > 0) scored.add((theme: t.theme, score: best));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final s in scored.take(limit)) s.theme];
  }

  /// 4 exact, 3 prefix, 2 fuzzy, 1 a phrase word matched inside a longer
  /// query ("feeling sad today"), 0 none.
  static int _score(String q, List<String> qWords, String phrase) {
    if (q == phrase) return 4;
    if (phrase.startsWith(q) && q.length >= 3) return 3;
    final pWords = queryWords(phrase);
    if (qWords.length == pWords.length && qWords.isNotEmpty) {
      var fuzzy = true;
      for (var i = 0; i < qWords.length; i++) {
        if (!_wordMatches(qWords[i], pWords[i])) {
          fuzzy = false;
          break;
        }
      }
      if (fuzzy) return 2;
    }
    // A short multi-word query matches if any synonym phrase is inside it.
    if (qWords.length > pWords.length && qWords.length <= 6) {
      for (var i = 0; i + pWords.length <= qWords.length; i++) {
        var all = true;
        for (var j = 0; j < pWords.length; j++) {
          if (!_wordMatches(qWords[i + j], pWords[j])) {
            all = false;
            break;
          }
        }
        if (all) return 1;
      }
    }
    return 0;
  }

  static bool _wordMatches(String a, String b) {
    if (a == b) return true;
    if (a.length >= 5 && b.length >= 5) return editDistanceAtMostOne(a, b);
    return false;
  }
}

/// True when [a] and [b] differ by at most one insert, delete or change.
bool editDistanceAtMostOne(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (a.length < b.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}
