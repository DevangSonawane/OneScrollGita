import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/reminder_providers.dart';
import 'package:versescroll/application/streak_providers.dart';
import 'package:versescroll/data/content/content_repository.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/data/user/activity_repository.dart';
import 'package:versescroll/data/user/database.dart';
import 'package:versescroll/domain/models/written_content.dart';

import '../fakes/fake_notification_service.dart';
import '../helpers.dart' show DiskAssetBundle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 25, 6);

  Future<ProviderContainer> make(
    FakeNotificationService svc, {
    bool brokenBank = false,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({
      SettingsRepository.kRemindersEnabled: true,
      // No search index needed: verse notifications fall back to invite.
      SettingsRepository.kVerseNotifsEnabled: false,
    });
    final sp = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    final c = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(sp)),
        activityRepositoryProvider.overrideWithValue(
          ActivityRepository(db, clock: () => now),
        ),
        contentRepositoryProvider.overrideWithValue(
          ContentRepository(bundle: DiskAssetBundle()),
        ),
        clockProvider.overrideWithValue(() => now),
        notificationServiceProvider.overrideWithValue(svc),
        if (brokenBank)
          messageBankProvider.overrideWith(
            (_) => Future<MessageBank>.error(StateError('bank unreadable')),
          ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    return c;
  }

  test('a rebuild schedules the next days of reminders', () async {
    final svc = FakeNotificationService();
    final c = await make(svc);
    await c.read(reminderControllerProvider.notifier).rebuild();
    expect(svc.scheduled, isNotEmpty);
    expect(c.read(reminderControllerProvider).lastError, isNull);
  });

  test('a failed rebuild keeps the previous schedule', () async {
    final svc = FakeNotificationService();
    final good = await make(svc);
    await good.read(reminderControllerProvider.notifier).rebuild();
    final before = [for (final r in svc.scheduled) r.id];
    expect(before, isNotEmpty);

    final broken = await make(svc, brokenBank: true);
    await broken.read(reminderControllerProvider.notifier).rebuild();
    expect([for (final r in svc.scheduled) r.id], before);
    expect(broken.read(reminderControllerProvider).lastError, isNotNull);
  });

  test(
    'permission revoked while on: flagged and nothing left pending',
    () async {
      final svc = FakeNotificationService();
      final c = await make(svc);
      await c.read(reminderControllerProvider.notifier).rebuild();
      expect(svc.scheduled, isNotEmpty);

      svc.permission = false;
      await c.read(reminderControllerProvider.notifier).rebuild();
      final state = c.read(reminderControllerProvider);
      expect(state.settings.remindersEnabled, isTrue);
      expect(state.permissionDenied, isTrue);
      expect(svc.scheduled, isEmpty);
    },
  );
}
