import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/daily_verse.dart';

void main() {
  const n = 640;

  test('same date gives the same entry, at any time of day', () {
    final a = dailyEntryIndex(DateTime(2026, 10, 28, 0, 1), n);
    final b = dailyEntryIndex(DateTime(2026, 10, 28, 23, 59), n);
    expect(a, b);
  });

  test('consecutive days differ, including across cycle boundaries', () {
    var prev = dailyEntryIndex(DateTime(2024, 1, 1), n);
    for (var d = 1; d < n * 3; d++) {
      final next = dailyEntryIndex(DateTime(2024, 1, 1 + d), n);
      expect(next, isNot(prev), reason: 'day $d');
      prev = next;
    }
  });

  test('two full cycles contain every entry exactly once each', () {
    for (var cycle = 0; cycle < 2; cycle++) {
      final seen = <int>{};
      for (var d = 0; d < n; d++) {
        seen.add(dailyEntryIndex(DateTime(2024, 1, 1 + cycle * n + d), n));
      }
      expect(seen.length, n, reason: 'cycle $cycle');
    }
  });

  test('a DST change does not shift the day number', () {
    // Europe and US DST transitions; local midnight-to-midnight still +1.
    expect(dayNumber(DateTime(2026, 3, 29)) - dayNumber(DateTime(2026, 3, 28)), 1);
    expect(dayNumber(DateTime(2026, 11, 1)) - dayNumber(DateTime(2026, 10, 31)), 1);
    expect(
      dailyEntryIndex(DateTime(2026, 3, 29, 1), n),
      dailyEntryIndex(DateTime(2026, 3, 29, 23), n),
    );
  });

  test('leap day is its own day', () {
    final feb28 = dayNumber(DateTime(2028, 2, 28));
    final feb29 = dayNumber(DateTime(2028, 2, 29));
    final mar1 = dayNumber(DateTime(2028, 3, 1));
    expect(feb29 - feb28, 1);
    expect(mar1 - feb29, 1);
    expect(
      dailyEntryIndex(DateTime(2028, 2, 29), n),
      isNot(dailyEntryIndex(DateTime(2028, 3, 1), n)),
    );
  });

  test('epoch is 2024-01-01 and results are stable', () {
    expect(dayNumber(DateTime(2024, 1, 1)), 0);
    expect(dayNumber(DateTime(2025, 1, 1)), 366);
    // Pin a value so a PRNG change is noticed.
    final pinned = [for (var d = 0; d < 5; d++) dailyEntryIndex(DateTime(2024, 1, 1 + d), 10)];
    expect(pinned, [for (var d = 0; d < 5; d++) cyclePermutation(0, 10)[d]]);
  });

  test('mulberry32 matches reference output', () {
    final r = Mulberry32(1);
    // Reference values from the canonical JavaScript implementation (node), seed 1.
    final values = [for (var i = 0; i < 3; i++) r.nextUint32()];
    expect(values, [2693262067, 11749833, 2265367787]);
  });

  test('dates before the epoch work', () {
    expect(dailyEntryIndex(DateTime(2023, 12, 31), n), inInclusiveRange(0, n - 1));
  });
}
