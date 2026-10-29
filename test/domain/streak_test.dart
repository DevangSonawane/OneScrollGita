import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/local_date.dart';
import 'package:versescroll/domain/streak.dart';

List<ReadDay> days(List<String> dates) => [
  for (final d in dates) ReadDay(d, 1),
];

void main() {
  group('computeStreak', () {
    test('empty', () {
      final s = computeStreak(const [], '2026-03-10');
      expect(s.currentStreak, 0);
      expect(s.totalDays, 0);
    });

    test('consecutive days ending today', () {
      final s = computeStreak(
        days(['2026-03-08', '2026-03-09', '2026-03-10']),
        '2026-03-10',
      );
      expect(s.currentStreak, 3);
      expect(s.todayCounted, isTrue);
      expect(s.lastSevenDays.sublist(4), [true, true, true]);
    });

    test('today not read yet: streak still alive from yesterday', () {
      final s = computeStreak(days(['2026-03-08', '2026-03-09']), '2026-03-10');
      expect(s.currentStreak, 2);
      expect(s.todayCounted, isFalse);
    });

    test('gap breaks the streak', () {
      final s = computeStreak(days(['2026-03-05', '2026-03-06']), '2026-03-10');
      expect(s.currentStreak, 0);
      expect(s.longestStreak, 2);
      expect(s.totalDays, 2);
    });

    test('longest streak across gaps', () {
      final s = computeStreak(
        days([
          '2026-01-01',
          '2026-01-02',
          '2026-01-03',
          '2026-01-05',
          '2026-01-06',
        ]),
        '2026-01-06',
      );
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 3);
    });

    test('future-dated rows are ignored', () {
      final s = computeStreak(days(['2026-03-10', '2026-03-11']), '2026-03-10');
      expect(s.currentStreak, 1);
      expect(s.totalDays, 1);
    });

    test('leap day counts as a normal day', () {
      final s = computeStreak(
        days(['2028-02-28', '2028-02-29', '2028-03-01']),
        '2028-03-01',
      );
      expect(s.currentStreak, 3);
    });

    test('daylight-saving change does not shift days', () {
      // Europe springs forward on the last Sunday of March.
      final before = dateKey(DateTime(2026, 3, 28, 23, 30));
      final after = dateKey(DateTime(2026, 3, 29, 0, 30));
      expect(daysBetween(before, after), 1);
      final s = computeStreak(days([before, after]), after);
      expect(s.currentStreak, 2);
    });

    test('total verses sums verse counts', () {
      final s = computeStreak(const [
        ReadDay('2026-03-09', 3),
        ReadDay('2026-03-10', 2),
      ], '2026-03-10');
      expect(s.totalVerses, 5);
    });
  });

  group('choosePopup', () {
    final empty = computeStreak(const [], '2026-03-10');
    test('first day ever is milestone 1', () {
      final after = computeStreak(days(['2026-03-10']), '2026-03-10');
      final c = choosePopup(before: empty, after: after, milestonesShown: {});
      expect(c.kind, PopupKind.milestone);
      expect(c.milestone, 1);
    });

    test('milestone shown once', () {
      final after = computeStreak(days(['2026-03-10']), '2026-03-10');
      final c = choosePopup(before: empty, after: after, milestonesShown: {1});
      expect(c.kind, PopupKind.goodWork);
    });

    test('after a gap: comeback, never streak-broken', () {
      final before = computeStreak(days(['2026-03-01']), '2026-03-10');
      final after = computeStreak(
        days(['2026-03-01', '2026-03-10']),
        '2026-03-10',
      );
      final c = choosePopup(before: before, after: after, milestonesShown: {1});
      expect(c.kind, PopupKind.comeback);
    });

    test('day 7 milestone', () {
      final list = [
        for (var d = 4; d <= 10; d++) '2026-03-${d.toString().padLeft(2, '0')}',
      ];
      final after = computeStreak(days(list), '2026-03-10');
      final before = computeStreak(days(list.sublist(0, 6)), '2026-03-10');
      final c = choosePopup(
        before: before,
        after: after,
        milestonesShown: {1, 3},
      );
      expect(c.milestone, 7);
    });
  });
}
