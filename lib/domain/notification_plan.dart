/// Pure scheduling logic for local reminders (PRD_v2 section 5). The plugin
/// wrapper only turns [PlannedNotification]s into platform calls.
library;

import 'daily_verse.dart';
import 'local_date.dart';
import 'models/reminder_settings.dart';
import 'models/written_content.dart';

enum NotifSlot {
  morning,
  evening;

  int get index0 => this == morning ? 0 : 1;
}

/// A stored assignment: keeps a day's message stable across rebuilds.
class SlotAssignment {
  const SlotAssignment({
    required this.date,
    required this.slot,
    required this.messageId,
    this.verseId,
  });

  final String date;
  final NotifSlot slot;
  final String messageId;
  final String? verseId;
}

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.date,
    required this.slot,
    required this.at,
    required this.category,
    required this.messageId,
    this.verseId,
  });

  /// Stable platform id for (date, slot).
  final int id;
  final String date;
  final NotifSlot slot;

  /// Local wall-clock time.
  final DateTime at;

  /// [MessageCategory.randomVerse] uses a `verse_lead_in` message as title.
  final MessageCategory category;
  final String messageId;
  final String? verseId;
}

class SchedulePlan {
  const SchedulePlan(this.notifications, this.assignments);

  static const empty = SchedulePlan([], []);

  final List<PlannedNotification> notifications;

  /// Assignments to save (new or changed).
  final List<SlotAssignment> assignments;
}

abstract final class ScheduleRules {
  static const windowDays = 14;
  static const noRepeatDays = 60;

  /// iOS keeps at most 64 pending local notifications.
  static const maxPending = 60;

  /// Morning rotation while the user is active.
  static const rotation = [
    MessageCategory.invite,
    MessageCategory.randomVerse,
    MessageCategory.reflection,
    MessageCategory.invite,
    MessageCategory.randomVerse,
    MessageCategory.invite,
    MessageCategory.reflection,
  ];

  /// Days without opening the app after which the evening nudge stops.
  static const stopEveningAfter = 3;

  /// After this, one morning notification every [sparseEvery] days.
  static const sparseAfter = 7;
  static const sparseEvery = 3;

  /// After this, nothing until the app is opened again.
  static const silentAfter = 30;
}

/// Platform id for (date, slot).
int notificationId(String date, NotifSlot slot) =>
    dayNumber(parseDateKey(date)!) * 2 + slot.index0;

/// Builds the next [ScheduleRules.windowDays] days of reminders.
///
/// [lastOpened] is the last local date the app was opened (normally today,
/// since this runs on every open). [entryIds] is the dataset in reading
/// order; when empty, verse notifications fall back to `invite`.
SchedulePlan planSchedule({
  required DateTime now,
  required ReminderSettings settings,
  required bool permissionGranted,
  required Set<String> readDates,
  required String lastOpened,
  required List<SlotAssignment> assignments,
  required MessageBank bank,
  required List<String> entryIds,
}) {
  if (!settings.remindersEnabled || !permissionGranted) {
    return SchedulePlan.empty;
  }
  final today = dateKey(now);
  final byKey = {for (final a in assignments) '${a.date}|${a.slot.name}': a};
  final out = <PlannedNotification>[];
  final saved = <SlotAssignment>[];

  for (var offset = 0; offset < ScheduleRules.windowDays; offset++) {
    final date = addDays(today, offset);
    if (offset == 0 && readDates.contains(today)) continue; // already read
    final idle = daysBetween(lastOpened, date);
    if (idle >= ScheduleRules.silentAfter) continue;

    for (final slot in NotifSlot.values) {
      final MessageCategory category;
      final TimeOfDayHm time;
      if (slot == NotifSlot.morning) {
        if (idle >= ScheduleRules.sparseAfter &&
            (idle - ScheduleRules.sparseAfter) % ScheduleRules.sparseEvery !=
                0) {
          continue;
        }
        time = settings.reminderTime;
        // A day after at least one whole day without opening the app.
        if (idle >= 2) {
          category = MessageCategory.comeback;
        } else {
          var c =
              ScheduleRules.rotation[dayNumber(parseDateKey(date)!) %
                  ScheduleRules.rotation.length];
          if (c == MessageCategory.randomVerse &&
              (!settings.verseNotifsEnabled || entryIds.isEmpty)) {
            c = MessageCategory.invite;
          }
          category = c;
        }
      } else {
        if (!settings.streakNudgeEnabled) continue;
        if (idle >= ScheduleRules.stopEveningAfter) continue;
        // Only while a streak is alive on that day and it has not counted.
        if (!readDates.contains(addDays(date, -1))) continue;
        if (readDates.contains(date)) continue;
        category = MessageCategory.streakRisk;
        time = settings.streakNudgeTime;
      }

      final d = parseDateKey(date)!;
      final at = DateTime(d.year, d.month, d.day, time.hour, time.minute);
      if (!at.isAfter(now)) continue;

      final messageCategory = category == MessageCategory.randomVerse
          ? MessageCategory.verseLeadIn
          : category;
      final existing = byKey['$date|${slot.name}'];
      SlotAssignment? chosen;
      if (existing != null &&
          bank.byId[existing.messageId]?.category == messageCategory &&
          (category != MessageCategory.randomVerse ||
              (existing.verseId != null &&
                  entryIds.contains(existing.verseId)))) {
        chosen = existing;
      } else {
        chosen = _pick(
          date: date,
          slot: slot,
          category: category,
          messageCategory: messageCategory,
          bank: bank,
          entryIds: entryIds,
          recent: [...assignments, ...saved],
        );
        if (chosen == null) continue;
        saved.add(chosen);
      }
      out.add(
        PlannedNotification(
          id: notificationId(date, slot),
          date: date,
          slot: slot,
          at: at,
          category: category,
          messageId: chosen.messageId,
          verseId: category == MessageCategory.randomVerse
              ? chosen.verseId
              : null,
        ),
      );
      if (out.length >= ScheduleRules.maxPending) {
        return SchedulePlan(out, saved);
      }
    }
  }
  return SchedulePlan(out, saved);
}

SlotAssignment? _pick({
  required String date,
  required NotifSlot slot,
  required MessageCategory category,
  required MessageCategory messageCategory,
  required MessageBank bank,
  required List<String> entryIds,
  required List<SlotAssignment> recent,
}) {
  final from = addDays(date, -ScheduleRules.noRepeatDays);
  final window = [
    for (final a in recent)
      if (a.date.compareTo(from) >= 0 && !(a.date == date && a.slot == slot)) a,
  ];
  final usedMessages = {for (final a in window) a.messageId};
  final rng = Mulberry32(dayNumber(parseDateKey(date)!) * 4 + slot.index0 + 11);

  final all = bank.of(messageCategory);
  if (all.isEmpty) return null;
  final fresh = [
    for (final m in all)
      if (!usedMessages.contains(m.id)) m,
  ];
  final pool = fresh.isEmpty ? all : fresh;
  final message = pool[rng.nextUint32() % pool.length];

  String? verseId;
  if (category == MessageCategory.randomVerse) {
    final usedVerses = {
      for (final a in window) ?a.verseId,
      entryIds[dailyEntryIndex(parseDateKey(date)!, entryIds.length)],
    };
    final candidates = [
      for (final id in entryIds)
        if (!usedVerses.contains(id)) id,
    ];
    if (candidates.isEmpty) return null;
    verseId = candidates[rng.nextUint32() % candidates.length];
  }
  return SlotAssignment(
    date: date,
    slot: slot,
    messageId: message.id,
    verseId: verseId,
  );
}

/// Cuts [text] at a word boundary to about [max] characters, adding "…"
/// when shortened. Never changes the words themselves.
String truncateAtWord(String text, int max) {
  final t = text.trim();
  if (t.length <= max) return t;
  var cut = t.lastIndexOf(' ', max - 1);
  if (cut <= 0) cut = max - 1;
  return '${t.substring(0, cut).trimRight()}…';
}

/// Random verse body: translation (~120 chars) and the reference.
String verseNotificationBody(String translation, String label) =>
    '${truncateAtWord(translation, 120)} BG $label';
