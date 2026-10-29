import 'local_date.dart';

/// One stored read day.
class ReadDay {
  const ReadDay(this.date, this.verseCount);

  /// Local `YYYY-MM-DD`.
  final String date;
  final int verseCount;
}

class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    required this.totalVerses,
    required this.todayCounted,
    required this.lastSevenDays,
  });

  static const empty = StreakStats(
    currentStreak: 0,
    longestStreak: 0,
    totalDays: 0,
    totalVerses: 0,
    todayCounted: false,
    lastSevenDays: [false, false, false, false, false, false, false],
  );

  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final int totalVerses;
  final bool todayCounted;

  /// Oldest first; the last item is today.
  final List<bool> lastSevenDays;
}

/// Streak numbers for [today] (PRD_v2 section 4). Rows dated after today
/// (device clock set forward then back) and malformed dates are ignored.
StreakStats computeStreak(Iterable<ReadDay> days, String today) {
  final valid = <String, int>{};
  for (final d in days) {
    if (parseDateKey(d.date) == null) continue;
    if (d.date.compareTo(today) > 0) continue;
    valid[d.date] = d.verseCount;
  }
  if (valid.isEmpty) return StreakStats.empty;

  final todayCounted = valid.containsKey(today);
  var current = 0;
  var cursor = todayCounted ? today : addDays(today, -1);
  while (valid.containsKey(cursor)) {
    current++;
    cursor = addDays(cursor, -1);
  }

  final sorted = valid.keys.toList()..sort();
  var longest = 0, run = 0;
  String? prev;
  for (final d in sorted) {
    run = prev != null && daysBetween(prev, d) == 1 ? run + 1 : 1;
    if (run > longest) longest = run;
    prev = d;
  }

  return StreakStats(
    currentStreak: current,
    longestStreak: longest,
    totalDays: valid.length,
    totalVerses: valid.values.fold(0, (a, b) => a + b),
    todayCounted: todayCounted,
    lastSevenDays: [
      for (var i = 6; i >= 0; i--) valid.containsKey(addDays(today, -i)),
    ],
  );
}

/// Streak milestones that get their own popup message, once each.
const streakMilestones = [1, 3, 7, 21, 40, 108, 365];

/// Which popup to show when today first counts.
enum PopupKind { goodWork, milestone, comeback }

/// Decides the popup after today has been recorded. [before] is the stats
/// without today; [after] includes it.
({PopupKind kind, int? milestone}) choosePopup({
  required StreakStats before,
  required StreakStats after,
  required Set<int> milestonesShown,
}) {
  final n = after.currentStreak;
  if (streakMilestones.contains(n) && !milestonesShown.contains(n)) {
    return (kind: PopupKind.milestone, milestone: n);
  }
  // Read before, but the streak had lapsed: welcome back, no guilt.
  if (before.totalDays > 0 && before.currentStreak == 0) {
    return (kind: PopupKind.comeback, milestone: null);
  }
  return (kind: PopupKind.goodWork, milestone: null);
}
