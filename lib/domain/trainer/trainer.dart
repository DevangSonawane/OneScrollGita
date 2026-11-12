/// The shloka trainer (PRD_v3 section 7). Pure Dart, fully unit tested.
///
/// It only decides which of the dataset's own words to hide and when a verse
/// is due again. It never changes, shortens or generates scripture text.
library;

import 'package:characters/characters.dart';

import '../daily_verse.dart' show Mulberry32;
import '../local_date.dart';

/// The five steps, the same for every verse.
enum TrainerStep {
  understand(1, 'Understand'),
  someHidden(2, 'Some words hidden'),
  mostHidden(3, 'Most words hidden'),
  firstLetters(4, 'First letters'),
  recite(5, 'Recite');

  const TrainerStep(this.number, this.title);
  final int number;
  final String title;

  static TrainerStep of(int number) =>
      values[(number.clamp(1, values.length)) - 1];

  /// Share of words hidden on this step.
  double get hiddenShare => switch (this) {
    TrainerStep.someHidden => 0.3,
    TrainerStep.mostHidden => 0.7,
    _ => 0,
  };

  /// Steps 2 to 4 go part by part on long verses; 1 and 5 show it whole.
  bool get byParts =>
      this == someHidden || this == mostHidden || this == firstLetters;
}

/// More reveals than this on one step repeats the step once.
const maxRevealsPerStep = 2;

bool shouldRepeatStep(int reveals) => reveals > maxRevealsPerStep;

/// Verses longer than this many lines are learned two lines at a time.
const maxLinesWhole = 4;

/// Line groups for steps 2 to 4: the whole verse when short, else pairs of
/// lines (a last odd line joins the previous pair).
List<List<int>> trainerParts(int lineCount) {
  if (lineCount <= 0) return const [];
  if (lineCount <= maxLinesWhole) {
    return [List.generate(lineCount, (i) => i)];
  }
  final parts = <List<int>>[];
  for (var i = 0; i < lineCount; i += 2) {
    parts.add([i, if (i + 1 < lineCount) i + 1]);
  }
  if (parts.length > 1 && parts.last.length == 1) {
    final last = parts.removeLast();
    parts.last.addAll(last);
  }
  return parts;
}

final _letter = RegExp(r'\p{L}', unicode: true);

/// A word can be hidden only if it has a letter (never dandas or numbers).
bool isHideable(String word) => _letter.hasMatch(word);

/// Words of one line, split on spaces exactly as the dataset prints them.
List<String> wordsOf(String line) =>
    line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// FNV-1a over UTF-16 units: a stable seed for a string.
int stableSeed(String s) {
  var h = 0x811C9DC5;
  for (final u in s.codeUnits) {
    h ^= u;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Which words to hide on [step] for [verseId], line part [part]. The same
/// inputs always give the same answer. Returns one flag per word.
List<bool> hiddenMask({
  required String verseId,
  required TrainerStep step,
  required int part,
  required List<String> words,
}) {
  final mask = List<bool>.filled(words.length, false);
  final candidates = [
    for (var i = 0; i < words.length; i++)
      if (isHideable(words[i])) i,
  ];
  if (step == TrainerStep.recite) {
    for (final i in candidates) {
      mask[i] = true;
    }
    return mask;
  }
  final share = step.hiddenShare;
  if (share == 0 || candidates.isEmpty) return mask;
  var count = (candidates.length * share).round();
  if (count < 1) count = 1;
  final rng = Mulberry32(stableSeed('$verseId|${step.number}|$part'));
  // Partial Fisher-Yates over the candidates.
  for (var i = 0; i < count; i++) {
    final j = i + rng.nextUint32() % (candidates.length - i);
    final t = candidates[i];
    candidates[i] = candidates[j];
    candidates[j] = t;
    mask[candidates[i]] = true;
  }
  return mask;
}

/// "kṛṣṇa" → "k", "कर्मणि" → "क", "'stv" → "'s": leading punctuation plus
/// the first letter (as a grapheme cluster, so Devanagari stays whole).
String firstLetterOf(String word) {
  final b = StringBuffer();
  for (final g in word.characters) {
    b.write(g);
    if (_letter.hasMatch(g)) break;
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Progress and reviews.

enum ShlokaStatus {
  learning,
  learned,
  mastered;

  static ShlokaStatus fromName(String name) =>
      values.where((s) => s.name == name).firstOrNull ?? learning;
}

class ShlokaState {
  const ShlokaState({
    required this.verseId,
    required this.step,
    required this.status,
    required this.reviewIndex,
    required this.startedAt,
    this.nextReview,
    this.learnedAt,
    this.lastReviewedAt,
  });

  factory ShlokaState.start(String verseId, DateTime now) => ShlokaState(
    verseId: verseId,
    step: 1,
    status: ShlokaStatus.learning,
    reviewIndex: 0,
    startedAt: now,
  );

  final String verseId;

  /// The next step to do while learning (1 to 5).
  final int step;
  final ShlokaStatus status;

  /// Index into [ReviewSchedule.intervals] of the current wait.
  final int reviewIndex;

  /// Local `YYYY-MM-DD` when the next review is due; null while learning and
  /// once mastered.
  final String? nextReview;
  final DateTime startedAt;
  final DateTime? learnedAt;
  final DateTime? lastReviewedAt;

  bool isDue(String today) =>
      status == ShlokaStatus.learned &&
      nextReview != null &&
      nextReview!.compareTo(today) <= 0;

  ShlokaState copyWith({
    int? step,
    ShlokaStatus? status,
    int? reviewIndex,
    String? nextReview,
    bool clearNextReview = false,
    DateTime? learnedAt,
    DateTime? lastReviewedAt,
  }) => ShlokaState(
    verseId: verseId,
    step: step ?? this.step,
    status: status ?? this.status,
    reviewIndex: reviewIndex ?? this.reviewIndex,
    nextReview: clearNextReview ? null : (nextReview ?? this.nextReview),
    startedAt: startedAt,
    learnedAt: learnedAt ?? this.learnedAt,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );
}

abstract final class ReviewSchedule {
  /// Days to wait before each review.
  static const intervals = [1, 3, 7, 21, 60];

  /// A learning step finished. Passing step 5 makes the verse learned, with
  /// the first review due tomorrow.
  static ShlokaState stepDone(ShlokaState s, DateTime now, String today) {
    if (s.status != ShlokaStatus.learning) return s;
    if (s.step < TrainerStep.recite.number) {
      return s.copyWith(step: s.step + 1);
    }
    return s.copyWith(
      status: ShlokaStatus.learned,
      reviewIndex: 0,
      nextReview: addDays(today, intervals.first),
      learnedAt: now,
    );
  }

  /// "Not yet" on step 5 while learning: practise first letters again.
  static ShlokaState reciteMissed(ShlokaState s) =>
      s.status == ShlokaStatus.learning
      ? s.copyWith(step: TrainerStep.firstLetters.number)
      : s;

  /// A review. Passing moves to the next wait; passing the last one makes
  /// the verse mastered. Missing moves back one wait.
  static ShlokaState reviewed(
    ShlokaState s, {
    required bool passed,
    required DateTime now,
    required String today,
  }) {
    if (s.status != ShlokaStatus.learned) return s;
    if (passed) {
      if (s.reviewIndex >= intervals.length - 1) {
        return s.copyWith(
          status: ShlokaStatus.mastered,
          clearNextReview: true,
          lastReviewedAt: now,
        );
      }
      final next = s.reviewIndex + 1;
      return s.copyWith(
        reviewIndex: next,
        nextReview: addDays(today, intervals[next]),
        lastReviewedAt: now,
      );
    }
    final back = s.reviewIndex > 0 ? s.reviewIndex - 1 : 0;
    return s.copyWith(
      reviewIndex: back,
      nextReview: addDays(today, intervals[back]),
      lastReviewedAt: now,
    );
  }
}
