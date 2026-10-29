import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:versescroll/data/notifications/notification_service.dart';
import 'package:versescroll/domain/models/written_content.dart';

/// Real-device / simulator check of local reminders (PRD_v2 section 5):
/// schedules one reminder through the app's own service, then waits for
/// the system to deliver it. Needs notification permission granted.
///
/// Run: `flutter test integration_test/notification_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a scheduled reminder is queued and then delivered', (t) async {
    final svc = LocalNotificationService();
    await svc.init();
    expect(await svc.hasPermission(), isTrue, reason: 'allow notifications first');
    await svc.cancelAll();

    // Reminders are scheduled to the minute; pick a minute safely ahead.
    final now = DateTime.now();
    final at = DateTime(now.year, now.month, now.day, now.hour, now.minute + 2);
    const id = 424242;
    await svc.schedule([
      NotificationRequest(
        id: id,
        at: at,
        category: MessageCategory.invite,
        title: 'A quiet minute',
        body: 'One verse is enough for today. Ready when you are.',
      ),
    ]);
    expect(await svc.pendingIds(), contains(id));
    // ignore: avoid_print
    print('REMINDER_QUEUED for $at');

    while (DateTime.now().isBefore(at.add(const Duration(seconds: 20)))) {
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    expect(await svc.pendingIds(), isNot(contains(id)), reason: 'not delivered');
    // ignore: avoid_print
    print('REMINDER_DELIVERED');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
