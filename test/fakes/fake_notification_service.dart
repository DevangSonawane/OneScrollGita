import 'package:versescroll/data/notifications/notification_service.dart';

/// Records what the app asks of the platform notifications.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permission = true, this.exact = true});

  bool permission;
  bool exact;
  int cancelAllCalls = 0;
  int cancelPendingCalls = 0;
  int testsSent = 0;
  int exactSettingsOpened = 0;
  List<NotificationRequest> scheduled = [];

  @override
  Stream<String> get taps => const Stream.empty();
  @override
  Future<void> init() async {}
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> openSystemSettings() async {}
  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled = [];
  }

  @override
  Future<void> cancelPending() async {
    cancelPendingCalls++;
    scheduled = [];
  }

  @override
  Future<void> cancel(Iterable<int> ids) async {
    final drop = ids.toSet();
    scheduled = [
      for (final r in scheduled)
        if (!drop.contains(r.id)) r,
    ];
  }

  @override
  Future<List<int>> pendingIds() async => [for (final r in scheduled) r.id];
  @override
  Future<ScheduleReport> schedule(List<NotificationRequest> requests) async {
    scheduled = [...requests];
    return ScheduleReport(scheduled: requests.length);
  }

  @override
  Future<bool> canScheduleExact() async => exact;
  @override
  Future<void> openExactAlarmSettings() async => exactSettingsOpened++;
  @override
  Future<void> sendTest({required String title, required String body}) async =>
      testsSent++;
  @override
  Future<String> refreshTimeZone() async => 'UTC';
}
