import '../local_date.dart';

/// Reminder settings (PRD_v2 section 3).
class ReminderSettings {
  const ReminderSettings({
    this.remindersEnabled = false,
    this.reminderTime = defaultReminderTime,
    this.streakNudgeEnabled = true,
    this.streakNudgeTime = defaultNudgeTime,
    this.verseNotifsEnabled = true,
  });

  static const defaultReminderTime = TimeOfDayHm(8, 0);
  static const defaultNudgeTime = TimeOfDayHm(20, 30);

  final bool remindersEnabled;
  final TimeOfDayHm reminderTime;

  /// Only active when reminders are on.
  final bool streakNudgeEnabled;
  final TimeOfDayHm streakNudgeTime;

  /// Only active when reminders are on.
  final bool verseNotifsEnabled;

  ReminderSettings copyWith({
    bool? remindersEnabled,
    TimeOfDayHm? reminderTime,
    bool? streakNudgeEnabled,
    TimeOfDayHm? streakNudgeTime,
    bool? verseNotifsEnabled,
  }) => ReminderSettings(
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderTime: reminderTime ?? this.reminderTime,
    streakNudgeEnabled: streakNudgeEnabled ?? this.streakNudgeEnabled,
    streakNudgeTime: streakNudgeTime ?? this.streakNudgeTime,
    verseNotifsEnabled: verseNotifsEnabled ?? this.verseNotifsEnabled,
  );
}
