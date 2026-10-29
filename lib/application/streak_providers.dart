import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content/content_repository.dart';
import '../data/user/activity_repository.dart';
import '../domain/daily_verse.dart';
import '../domain/local_date.dart';
import '../domain/models/written_content.dart';
import '../domain/streak.dart';
import 'core_providers.dart';
import 'reminder_providers.dart';
import 'scripture_providers.dart';

/// Overridden in main() and in tests.
final activityRepositoryProvider = Provider<ActivityRepository>(
  (_) => throw UnimplementedError('activityRepositoryProvider'),
);
final contentRepositoryProvider = Provider<ContentRepository>(
  (_) => ContentRepository(),
);

final messageBankProvider = FutureProvider<MessageBank>(
  (ref) => ref.watch(contentRepositoryProvider).messages(),
);

final readDaysProvider = StreamProvider<List<ReadDay>>(
  (ref) => ref.watch(activityRepositoryProvider).watchReadDays(),
);

final streakStatsProvider = Provider<StreakStats>((ref) {
  final days = ref.watch(readDaysProvider).value ?? const <ReadDay>[];
  return computeStreak(days, dateKey(ref.watch(todayProvider)));
});

/// What the "Good work" popup shows.
class StreakPopupData {
  const StreakPopupData({
    required this.serial,
    required this.title,
    required this.body,
    required this.streakLine,
    required this.stats,
  });

  final int serial;
  final String title;
  final String body;
  final String streakLine;
  final StreakStats stats;
}

final streakPopupProvider =
    NotifierProvider<StreakPopupNotifier, StreakPopupData?>(
      StreakPopupNotifier.new,
    );

class StreakPopupNotifier extends Notifier<StreakPopupData?> {
  @override
  StreakPopupData? build() => null;

  void show(StreakPopupData data) => state = data;

  void dismiss() => state = null;
}

/// "Day 4", or "Day 1. A beginning."
String streakLine(int streak) =>
    streak <= 1 ? 'Day 1. A beginning.' : 'Day $streak';

final readTrackerProvider = NotifierProvider<ReadTracker, void>(
  ReadTracker.new,
);

/// Records qualifying reads (PRD_v2 section 4) and raises the popup.
class ReadTracker extends Notifier<void> {
  final _recorded = <String>{};

  @override
  void build() {}

  Future<void> qualify(String verseId) async {
    final clock = ref.read(clockProvider);
    final today = dateKey(clock());
    if (!_recorded.add('$today|$verseId')) return;
    final repo = ref.read(activityRepositoryProvider);
    final bool first;
    try {
      first = await repo.recordQualifyingRead(today, verseId);
    } catch (_) {
      _recorded.remove('$today|$verseId');
      return;
    }
    if (!first) return;
    ref.read(reminderControllerProvider.notifier).onTodayCounted().ignore();

    final settings = ref.read(settingsRepositoryProvider);
    if (settings.streakPopupShownDate == today) return;
    final days = await repo.readDays();
    final after = computeStreak(days, today);
    final before = computeStreak([
      for (final d in days)
        if (d.date != today) d,
    ], today);
    final shown = settings.milestonesShown;
    final choice = choosePopup(
      before: before,
      after: after,
      milestonesShown: shown,
    );

    final bank = await ref
        .read(messageBankProvider.future)
        .catchError((_) => MessageBank.empty);
    final seed = Mulberry32(dayNumber(clock()) * 31 + 7).nextUint32();
    Message? pick(MessageCategory c) {
      final list = bank.of(c);
      return list.isEmpty ? null : list[seed % list.length];
    }

    final message = switch (choice.kind) {
      PopupKind.milestone =>
        bank.milestone(choice.milestone!, seed: seed) ??
            pick(MessageCategory.popupGoodWork),
      PopupKind.comeback => pick(MessageCategory.comeback),
      PopupKind.goodWork => pick(MessageCategory.popupGoodWork),
    };
    final lang = ref.read(languageProvider);
    final n = after.currentStreak;

    await settings.setStreakPopupShownDate(today);
    if (choice.kind == PopupKind.milestone) {
      await settings.addMilestoneShown(choice.milestone!);
    }
    ref
        .read(streakPopupProvider.notifier)
        .show(
          StreakPopupData(
            serial: dayNumber(clock()),
            title: fillPlaceholders(
              message?.title.of(lang) ?? 'Good work',
              streak: n,
              days: after.totalDays,
            ),
            body: fillPlaceholders(
              message?.body.of(lang) ?? 'One more verse read today.',
              streak: n,
              days: after.totalDays,
            ),
            streakLine: streakLine(n),
            stats: after,
          ),
        );
  }

  /// After "Reset all saved data".
  void forget() => _recorded.clear();
}
