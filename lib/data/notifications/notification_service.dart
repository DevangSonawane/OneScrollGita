import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/written_content.dart';
import '../../domain/notification_plan.dart';

/// A notification ready for the platform.
class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.at,
    required this.category,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime at;
  final MessageCategory category;
  final String title;
  final String body;

  /// The verse id to open, if any.
  final String? payload;
}

/// Thin wrapper over flutter_local_notifications (PRD_v2 section 5). All
/// scheduling decisions live in `domain/notification_plan.dart`.
abstract class NotificationService {
  /// Verse ids (or '' for Home) from tapped notifications.
  Stream<String> get taps;

  Future<void> init();

  /// The tap that launched the app, if any.
  Future<String?> launchPayload();

  Future<bool> hasPermission();

  /// Asks the system. Only called when the user turns reminders on.
  Future<bool> requestPermission();

  Future<void> openSystemSettings();

  /// Cancels pending and delivered notifications (reset, reminders off).
  Future<void> cancelAll();

  /// Cancels pending notifications only; delivered ones stay visible.
  Future<void> cancelPending();

  Future<void> cancel(Iterable<int> ids);

  /// Ids of notifications waiting to be delivered.
  Future<List<int>> pendingIds();

  /// Schedules each request on its own: one failure never stops the rest.
  Future<ScheduleReport> schedule(List<NotificationRequest> requests);

  /// Android 12+: whether exact alarms are allowed. Always true elsewhere.
  Future<bool> canScheduleExact();

  /// Android 12+: opens the system page for exact alarms.
  Future<void> openExactAlarmSettings();

  /// One notification shortly after the tap, to check delivery.
  Future<void> sendTest({required String title, required String body});

  /// Re-reads the device time zone. Returns its name.
  Future<String> refreshTimeZone();
}

/// What a [NotificationService.schedule] call did.
class ScheduleReport {
  const ScheduleReport({
    this.scheduled = 0,
    this.skipped = 0,
    this.failed = 0,
    this.lastError,
  });

  static const none = ScheduleReport();

  final int scheduled;

  /// Too soon (less than [ScheduleRules.minLead] away).
  final int skipped;
  final int failed;
  final Object? lastError;
}

/// Runs [one] for every request at least [ScheduleRules.minLead] after
/// [now], catching errors per request.
@visibleForTesting
Future<ScheduleReport> scheduleEach(
  List<NotificationRequest> requests,
  DateTime now,
  Future<void> Function(NotificationRequest r) one,
) async {
  var scheduled = 0, skipped = 0, failed = 0;
  Object? lastError;
  final earliest = now.add(ScheduleRules.minLead);
  for (final r in requests) {
    if (r.at.isBefore(earliest)) {
      skipped++;
      continue;
    }
    try {
      await one(r);
      scheduled++;
    } catch (e) {
      failed++;
      lastError = e;
      debugPrint('Notification ${r.id} not scheduled: $e');
    }
  }
  return ScheduleReport(
    scheduled: scheduled,
    skipped: skipped,
    failed: failed,
    lastError: lastError,
  );
}

/// A zone for a device time-zone name the database does not know: the first
/// zone whose current UTC offset matches the device's, else UTC. Better than
/// UTC alone, which shifts every reminder by the device's offset.
@visibleForTesting
tz.Location zoneForOffset(Duration offset, {DateTime? at}) {
  final ms = (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
  // Prefer real cities over "Etc/" zones, which have inverted names.
  final zones = tz.timeZoneDatabase.locations.values.toList()
    ..sort((a, b) {
      final ea = a.name.startsWith('Etc/') ? 1 : 0;
      final eb = b.name.startsWith('Etc/') ? 1 : 0;
      return ea != eb ? ea - eb : a.name.compareTo(b.name);
    });
  for (final z in zones) {
    if (z.timeZone(ms).offset == offset) return z;
  }
  return tz.UTC;
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  static const _channels = {
    MessageCategory.invite: ('daily_reminder', 'Daily reading reminder'),
    MessageCategory.reflection: ('daily_reminder', 'Daily reading reminder'),
    MessageCategory.comeback: ('daily_reminder', 'Daily reading reminder'),
    MessageCategory.streakRisk: ('streak_nudge', 'Streak nudges'),
    MessageCategory.randomVerse: ('verse_of_day', 'Verse of the day'),
  };

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    tzdata.initializeTimeZones();
    await refreshTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permission is asked only when reminders are switched on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _taps.add(r.payload ?? ''),
    );
    final android = _android;
    if (android != null) {
      for (final (id, name) in _channels.values.toSet()) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(id, name),
        );
      }
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<String?> launchPayload() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    return d.notificationResponse?.payload ?? '';
  }

  @override
  Future<bool> hasPermission() async {
    if (_android != null) {
      return await _android!.areNotificationsEnabled() ?? false;
    }
    if (_ios != null) {
      return (await _ios!.checkPermissions())?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    if (_android != null) {
      return await _android!.requestNotificationsPermission() ?? false;
    }
    if (_ios != null) {
      return await _ios!.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> openSystemSettings() async {
    try {
      await _plugin.openAppNotificationSettings();
    } catch (_) {
      // Not supported on this platform.
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> cancelPending() => _plugin.cancelAllPendingNotifications();

  @override
  Future<bool> canScheduleExact() async {
    final android = _android;
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {
      // Not supported on this version.
    }
  }

  @override
  Future<void> sendTest({required String title, required String body}) async {
    // Exact only when allowed: Android 12+ refuses exact alarms otherwise
    // (PRD_v6 section 2). Inexact still arrives within seconds when idle.
    final exact = await canScheduleExact();
    await _zoned(
      NotificationRequest(
        id: testNotificationId,
        at: DateTime.now().add(ScheduleRules.testDelay),
        category: MessageCategory.invite,
        title: title,
        body: body,
      ),
      exact: exact,
      exactSeconds: true,
    );
  }

  @override
  Future<List<int>> pendingIds() async => [
    for (final r in await _plugin.pendingNotificationRequests()) r.id,
  ];

  @override
  Future<void> cancel(Iterable<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  @override
  Future<ScheduleReport> schedule(List<NotificationRequest> requests) async {
    assert(requests.length <= ScheduleRules.maxPending);
    final exact = await canScheduleExact();
    return scheduleEach(
      requests,
      DateTime.now(),
      (r) => _zoned(r, exact: exact),
    );
  }

  Future<void> _zoned(
    NotificationRequest r, {
    required bool exact,
    bool exactSeconds = false,
  }) {
    final (channelId, channelName) =
        _channels[r.category] ?? _channels[MessageCategory.invite]!;
    final at = r.at;
    return _plugin.zonedSchedule(
      id: r.id,
      scheduledDate: exactSeconds
          ? tz.TZDateTime.from(at, tz.local)
          : tz.TZDateTime(
              tz.local,
              at.year,
              at.month,
              at.day,
              at.hour,
              at.minute,
            ),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          icon: 'ic_notification',
          styleInformation: BigTextStyleInformation(r.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
      ),
      // Exact when the system already allows it; inexact otherwise (a few
      // minutes late, or more under heavy battery saving).
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: r.title,
      body: r.body,
      payload: r.payload,
    );
  }

  @override
  Future<String> refreshTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return info.identifier;
    } catch (e) {
      final zone = zoneForOffset(DateTime.now().timeZoneOffset);
      debugPrint('Time zone not found, using ${zone.name}: $e');
      tz.setLocalLocation(zone);
      return zone.name;
    }
  }
}

/// Does nothing (tests, unsupported platforms).
class NoopNotificationService implements NotificationService {
  @override
  Stream<String> get taps => const Stream.empty();
  @override
  Future<void> init() async {}
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> openSystemSettings() async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> cancel(Iterable<int> ids) async {}
  @override
  Future<List<int>> pendingIds() async => const [];
  @override
  Future<void> cancelPending() async {}
  @override
  Future<ScheduleReport> schedule(List<NotificationRequest> requests) async =>
      ScheduleReport.none;
  @override
  Future<bool> canScheduleExact() async => true;
  @override
  Future<void> openExactAlarmSettings() async {}
  @override
  Future<void> sendTest({required String title, required String body}) async {}
  @override
  Future<String> refreshTimeZone() async => 'UTC';
}
