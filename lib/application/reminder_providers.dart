import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications/notification_service.dart';
import '../data/user/database.dart' show NotifAssignmentRow;
import '../domain/local_date.dart';
import '../domain/models/reminder_settings.dart';
import '../domain/models/written_content.dart';
import '../domain/notification_plan.dart';
import 'core_providers.dart';
import 'search_providers.dart';
import 'streak_providers.dart';

/// Overridden in main() with [LocalNotificationService].
final notificationServiceProvider = Provider<NotificationService>(
  (_) => NoopNotificationService(),
);

class ReminderState {
  const ReminderState(this.settings, {this.permissionDenied = false});

  final ReminderSettings settings;

  /// The system refused notifications the last time we asked or checked.
  final bool permissionDenied;
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, ReminderState>(ReminderController.new);

/// Reminder settings and the schedule rebuild (PRD_v2 section 5).
class ReminderController extends Notifier<ReminderState> {
  Future<void>? _running;
  bool _again = false;

  @override
  ReminderState build() =>
      ReminderState(ref.read(settingsRepositoryProvider).loadReminders());

  NotificationService get _svc => ref.read(notificationServiceProvider);

  Future<void> _save(ReminderSettings s) async {
    state = ReminderState(s, permissionDenied: state.permissionDenied);
    await ref.read(settingsRepositoryProvider).saveReminders(s);
    await rebuild();
  }

  /// Turning reminders on asks for permission. Returns false when denied
  /// (the switch stays off).
  Future<bool> setEnabled(bool on) async {
    if (!on) {
      await _save(state.settings.copyWith(remindersEnabled: false));
      return true;
    }
    final granted =
        await _svc.hasPermission() || await _svc.requestPermission();
    if (!granted) {
      state = ReminderState(
        state.settings.copyWith(remindersEnabled: false),
        permissionDenied: true,
      );
      return false;
    }
    state = ReminderState(state.settings);
    await _save(state.settings.copyWith(remindersEnabled: true));
    return true;
  }

  Future<void> setReminderTime(TimeOfDayHm t) =>
      _save(state.settings.copyWith(reminderTime: t));

  Future<void> setStreakNudge(bool on) =>
      _save(state.settings.copyWith(streakNudgeEnabled: on));

  Future<void> setStreakNudgeTime(TimeOfDayHm t) =>
      _save(state.settings.copyWith(streakNudgeTime: t));

  Future<void> setVerseNotifs(bool on) =>
      _save(state.settings.copyWith(verseNotifsEnabled: on));

  Future<void> openSystemSettings() => _svc.openSystemSettings();

  /// On every app open and resume: remember the day, then rebuild (this
  /// also catches time-zone and clock changes).
  Future<void> onAppOpened() async {
    final today = dateKey(ref.read(clockProvider)());
    await ref.read(settingsRepositoryProvider).setLastOpenedDate(today);
    await rebuild();
  }

  /// Today counted: today's nudges must not fire.
  Future<void> onTodayCounted() async {
    final today = dateKey(ref.read(clockProvider)());
    await _svc.cancel([
      for (final s in NotifSlot.values) notificationId(today, s),
    ]);
    await rebuild();
  }

  /// After "Reset all saved data".
  Future<void> reset() async {
    await _svc.cancelAll();
    state = ReminderState(ref.read(settingsRepositoryProvider).loadReminders());
  }

  /// Cancels everything and schedules the next 14 days. Serialised: a call
  /// during a rebuild runs once more afterwards.
  Future<void> rebuild() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final run = _rebuild().catchError((Object _) {}).whenComplete(() {
      _running = null;
      if (_again) {
        _again = false;
        rebuild();
      }
    });
    return _running = run;
  }

  Future<void> _rebuild() async {
    final svc = _svc;
    await svc.init();
    await svc.refreshTimeZone();
    await svc.cancelAll();
    final s = state.settings;
    if (!s.remindersEnabled) return;
    if (!await svc.hasPermission()) {
      state = ReminderState(s, permissionDenied: true);
      return;
    }
    if (state.permissionDenied) state = ReminderState(s);

    final clock = ref.read(clockProvider);
    final now = clock();
    final today = dateKey(now);
    final prefs = ref.read(settingsRepositoryProvider);
    final repo = ref.read(activityRepositoryProvider);
    final readDates = {for (final d in await repo.readDays()) d.date};
    final keepFrom = addDays(today, -ScheduleRules.noRepeatDays);
    final assignments = [
      for (final r in await repo.assignmentsSince(keepFrom)) ?_fromRow(r),
    ];
    final bank = await ref.read(messageBankProvider.future);
    var catalogue = const <CatalogueEntryLite>[];
    if (s.verseNotifsEnabled) {
      try {
        final index = await ref.read(searchIndexProvider.future);
        catalogue = [
          for (final e in index.catalogue())
            CatalogueEntryLite(e.id, e.label, e.translation),
        ];
      } catch (_) {
        // No index yet: verse notifications fall back to invite.
      }
    }
    final lastOpened = prefs.lastOpenedDate ?? today;
    final plan = planSchedule(
      now: now,
      settings: s,
      permissionGranted: true,
      readDates: readDates,
      lastOpened: lastOpened,
      assignments: assignments,
      bank: bank,
      entryIds: [for (final e in catalogue) e.id],
    );
    await repo.saveAssignments([
      for (final a in plan.assignments)
        NotifAssignmentRow(
          date: a.date,
          slot: a.slot.name,
          messageId: a.messageId,
          verseId: a.verseId,
        ),
    ]);
    await repo.pruneAssignments(keepFrom);

    final lang = ref.read(languageProvider);
    final byId = {for (final e in catalogue) e.id: e};
    final requests = <NotificationRequest>[];
    for (final n in plan.notifications) {
      final m = bank.byId[n.messageId];
      if (m == null) continue;
      final streak = _streakBefore(readDates, n.date);
      final days = daysBetween(lastOpened, n.date);
      String fill(String t) => fillPlaceholders(t, streak: streak, days: days);
      if (n.category == MessageCategory.randomVerse) {
        final e = byId[n.verseId];
        if (e == null) continue;
        requests.add(
          NotificationRequest(
            id: n.id,
            at: n.at,
            category: n.category,
            title: fill(m.title.of(lang)),
            body: verseNotificationBody(e.translation(lang), e.label),
            payload: e.id,
          ),
        );
      } else {
        requests.add(
          NotificationRequest(
            id: n.id,
            at: n.at,
            category: n.category,
            title: fill(m.title.of(lang)),
            body: fill(m.body.of(lang)),
          ),
        );
      }
    }
    await svc.schedule(requests);
    await prefs.setLastScheduleRebuildAt(now);
  }

  /// Consecutive read days ending the day before [date].
  int _streakBefore(Set<String> readDates, String date) {
    var n = 0;
    var d = addDays(date, -1);
    while (readDates.contains(d)) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  SlotAssignment? _fromRow(NotifAssignmentRow r) {
    final slot = NotifSlot.values.where((s) => s.name == r.slot).firstOrNull;
    if (slot == null) return null;
    return SlotAssignment(
      date: r.date,
      slot: slot,
      messageId: r.messageId,
      verseId: r.verseId,
    );
  }
}

/// The bits of a catalogue entry a verse notification needs.
class CatalogueEntryLite {
  const CatalogueEntryLite(this.id, this.label, this.translation);

  final String id;
  final String label;
  final String Function(String lang) translation;
}
