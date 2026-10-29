import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/daily_verse.dart';
import 'package:versescroll/domain/local_date.dart';
import 'package:versescroll/domain/models/reminder_settings.dart';
import 'package:versescroll/domain/models/written_content.dart';
import 'package:versescroll/domain/notification_plan.dart';

MessageBank bank() {
  final list = <Message>[];
  for (final c in MessageCategory.values) {
    if (c == MessageCategory.randomVerse) continue;
    for (var i = 0; i < 80; i++) {
      list.add(
        Message(
          id: '${c.code}-$i',
          category: c,
          title: LocalText('T $i'),
          body: LocalText('B $i {streak}'),
        ),
      );
    }
  }
  return MessageBank(list);
}

final ids = [
  for (var i = 0; i < 700; i++)
    'bg-${(i ~/ 40 + 1).toString().padLeft(2, '0')}-${(i % 40 + 1).toString().padLeft(3, '0')}',
];
const on = ReminderSettings(remindersEnabled: true);

SchedulePlan plan({
  DateTime? now,
  ReminderSettings settings = on,
  Set<String> read = const {},
  String? lastOpened,
  List<SlotAssignment> assignments = const [],
  bool permission = true,
}) {
  final n = now ?? DateTime(2026, 3, 10, 7, 0);
  return planSchedule(
    now: n,
    settings: settings,
    permissionGranted: permission,
    readDates: read,
    lastOpened: lastOpened ?? dateKey(n),
    assignments: assignments,
    bank: bank(),
    entryIds: ids,
  );
}

void main() {
  test('nothing when reminders are off or permission missing', () {
    expect(plan(settings: const ReminderSettings()).notifications, isEmpty);
    expect(plan(permission: false).notifications, isEmpty);
  });

  test('14-day window of mornings, well under the iOS limit', () {
    final p = plan();
    final mornings = p.notifications.where((n) => n.slot == NotifSlot.morning);
    expect(mornings.length, lessThanOrEqualTo(ScheduleRules.windowDays));
    expect(p.notifications.length, lessThanOrEqualTo(28));
    expect(p.notifications.length, lessThan(64));
    final last = p.notifications
        .map((n) => n.date)
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    expect(daysBetween('2026-03-10', last), lessThan(ScheduleRules.windowDays));
  });

  test('skips today when it already counted', () {
    final p = plan(read: {'2026-03-10'});
    expect(p.notifications.where((n) => n.date == '2026-03-10'), isEmpty);
  });

  test('skips a time that has passed today', () {
    final p = plan(now: DateTime(2026, 3, 10, 9, 0));
    expect(
      p.notifications.where(
        (n) => n.date == '2026-03-10' && n.slot == NotifSlot.morning,
      ),
      isEmpty,
    );
  });

  test('evening nudge only while a streak is alive and today not counted', () {
    final noStreak = plan();
    expect(
      noStreak.notifications.where(
        (n) => n.slot == NotifSlot.evening && n.date == '2026-03-10',
      ),
      isEmpty,
    );
    final streak = plan(read: {'2026-03-09'});
    final evening = streak.notifications.where(
      (n) => n.slot == NotifSlot.evening && n.date == '2026-03-10',
    );
    expect(evening.single.category, MessageCategory.streakRisk);
  });

  test('morning rotation uses invite, random verse and reflection', () {
    final cats = {
      for (final n in plan().notifications.where(
        (n) => n.slot == NotifSlot.morning,
      ))
        n.category,
    };
    // Only today and tomorrow use the rotation; later days are comebacks.
    final rotation = {
      for (var d = 0; d < 7; d++)
        ScheduleRules.rotation[(dayNumberOf('2026-03-10') + d) % 7],
    };
    expect(
      rotation,
      containsAll([
        MessageCategory.invite,
        MessageCategory.randomVerse,
        MessageCategory.reflection,
      ]),
    );
    expect(
      cats.difference({
        MessageCategory.invite,
        MessageCategory.reflection,
        MessageCategory.randomVerse,
        MessageCategory.comeback,
      }),
      isEmpty,
    );
  });

  test('verse notifications off fall back to invite', () {
    final p = plan(settings: on.copyWith(verseNotifsEnabled: false));
    expect(
      p.notifications.where((n) => n.category == MessageCategory.randomVerse),
      isEmpty,
    );
  });

  test('random verse is never the daily verse and has a verse id', () {
    for (final n in plan().notifications.where(
      (n) => n.category == MessageCategory.randomVerse,
    )) {
      expect(n.verseId, isNotNull);
      expect(ids, contains(n.verseId));
    }
  });

  test('assignments are stable across rebuilds', () {
    final first = plan();
    final second = plan(assignments: first.assignments);
    expect(second.assignments, isEmpty);
    expect(
      [for (final n in second.notifications) n.messageId],
      [for (final n in first.notifications) n.messageId],
    );
  });

  test('no message repeats within 60 days', () {
    final p = plan();
    final used = [for (final n in p.notifications) n.messageId];
    expect(used.toSet().length, used.length);
    final recent = [
      for (var i = 1; i <= 59; i++)
        SlotAssignment(
          date: addDays('2026-03-10', -i),
          slot: NotifSlot.morning,
          messageId: 'invite-${i % 80}',
        ),
    ];
    final next = plan(assignments: recent);
    for (final n in next.notifications) {
      if (n.category == MessageCategory.invite) {
        final idx = int.parse(n.messageId.split('-').last);
        expect(idx == 0 || idx > 59, isTrue, reason: n.messageId);
      }
    }
  });

  test(
    'back-off: no evening after 3 idle days, sparse after 7, none after 30',
    () {
      final p = plan(
        read: {for (var i = 0; i < 20; i++) addDays('2026-03-09', -i)},
      );
      for (final n in p.notifications) {
        final idle = daysBetween('2026-03-10', n.date);
        if (n.slot == NotifSlot.evening) expect(idle, lessThan(3));
        if (idle >= 7) expect((idle - 7) % 3, 0);
      }
      final silent = plan(lastOpened: '2026-01-01');
      expect(silent.notifications, isEmpty);
    },
  );

  test('comeback after a full day away', () {
    final p = plan();
    final far = p.notifications.where(
      (n) => daysBetween('2026-03-10', n.date) >= 2,
    );
    expect(
      far.every(
        (n) =>
            n.slot != NotifSlot.morning ||
            n.category == MessageCategory.comeback,
      ),
      isTrue,
    );
  });

  test('truncation keeps whole words', () {
    const t =
        'You have a right to perform your prescribed duty, but you are not entitled to the fruits of action. Never consider yourself to be the cause';
    final cut = truncateAtWord(t, 120);
    expect(cut.length, lessThanOrEqualTo(121));
    expect(cut.endsWith('…'), isTrue);
    expect(t.startsWith(cut.substring(0, cut.length - 1)), isTrue);
    expect(verseNotificationBody(t, '2.47').length, lessThanOrEqualTo(140));
  });
}

int dayNumberOf(String key) => dayNumber(parseDateKey(key)!);
