import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reminder_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/local_date.dart';

/// Profile > Reminders (PRD_v2 section 5). Everything is scheduled on the
/// phone.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<TimeOfDayHm?> _pick(BuildContext context, TimeOfDayHm current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    return t == null ? null : TimeOfDayHm(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final state = ref.watch(reminderControllerProvider);
    final s = state.settings;
    final ctl = ref.read(reminderControllerProvider.notifier);
    final on = s.remindersEnabled;
    String fmt(TimeOfDayHm t) =>
        MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay(hour: t.hour, minute: t.minute));

    Widget note(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s8,
        Space.readingSide,
        Space.s8,
      ),
      child: Text(text, style: ui.body(size: 13)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ContentWidthList(
        bottom: navBarInset(context),
        children: [
          SettingsRow(
            title: 'Daily reminder',
            trailing: Switch(value: on, onChanged: ctl.setEnabled),
            onTap: () => ctl.setEnabled(!on),
            showChevron: false,
          ),
          if (state.permissionDenied && !on)
            Container(
              margin: const EdgeInsets.fromLTRB(
                Space.readingSide,
                Space.s8,
                Space.readingSide,
                Space.s8,
              ),
              padding: const EdgeInsets.all(Space.s16),
              decoration: BoxDecoration(
                color: c.surfaceSoft,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications are turned off for this app. To get a '
                    'daily reminder, allow notifications in your phone '
                    'settings, then switch the reminder on here.',
                    style: ui.body(color: c.textPrimary),
                  ),
                  const SizedBox(height: Space.s8),
                  TextButton(
                    onPressed: ctl.openSystemSettings,
                    child: const Text('Open settings'),
                  ),
                ],
              ),
            ),
          SettingsRow(
            title: 'Reminder time',
            trailing: Text(fmt(s.reminderTime), style: ui.label()),
            onTap: on
                ? () async {
                    final t = await _pick(context, s.reminderTime);
                    if (t != null) await ctl.setReminderTime(t);
                  }
                : null,
          ),
          SettingsRow(
            title: 'Streak nudge in the evening',
            subtitle: 'Only on days you have not read yet',
            trailing: Switch(
              value: s.streakNudgeEnabled,
              onChanged: on ? ctl.setStreakNudge : null,
            ),
            onTap: on ? () => ctl.setStreakNudge(!s.streakNudgeEnabled) : null,
            showChevron: false,
          ),
          SettingsRow(
            title: 'Nudge time',
            trailing: Text(fmt(s.streakNudgeTime), style: ui.label()),
            onTap: on && s.streakNudgeEnabled
                ? () async {
                    final t = await _pick(context, s.streakNudgeTime);
                    if (t != null) await ctl.setStreakNudgeTime(t);
                  }
                : null,
          ),
          SettingsRow(
            title: 'Verse of the day notifications',
            trailing: Switch(
              value: s.verseNotifsEnabled,
              onChanged: on ? ctl.setVerseNotifs : null,
            ),
            onTap: on ? () => ctl.setVerseNotifs(!s.verseNotifsEnabled) : null,
            showChevron: false,
            divider: false,
          ),
          const SizedBox(height: Space.s16),
          note(
            'Reminders are scheduled on this phone. Nothing is sent from a '
            'server.',
          ),
          note(
            'If reminders arrive late, allow background activity for this '
            "app in your phone's battery settings.",
          ),
        ],
      ),
    );
  }
}

/// A centred, max-width list for settings pages.
class ContentWidthList extends StatelessWidget {
  const ContentWidthList({super.key, required this.children, this.bottom = 0});

  final List<Widget> children;
  final double bottom;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Space.contentMaxWidth),
      child: ListView(
        padding: EdgeInsets.only(bottom: bottom),
        children: children,
      ),
    ),
  );
}
