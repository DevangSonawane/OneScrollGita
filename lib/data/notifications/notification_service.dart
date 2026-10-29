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

  Future<void> cancelAll();

  Future<void> cancel(Iterable<int> ids);

  /// Ids of notifications waiting to be delivered.
  Future<List<int>> pendingIds();

  Future<void> schedule(List<NotificationRequest> requests);

  /// Re-reads the device time zone. Returns its name.
  Future<String> refreshTimeZone();
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
  Future<void> schedule(List<NotificationRequest> requests) async {
    assert(requests.length <= ScheduleRules.maxPending);
    for (final r in requests) {
      final (channelId, channelName) =
          _channels[r.category] ?? _channels[MessageCategory.invite]!;
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime(
          tz.local,
          r.at.year,
          r.at.month,
          r.at.day,
          r.at.hour,
          r.at.minute,
        ),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            icon: 'ic_notification',
            styleInformation: BigTextStyleInformation(r.body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Inexact: no exact-alarm permission; a few minutes late is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.payload,
      );
    }
  }

  @override
  Future<String> refreshTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return info.identifier;
    } catch (e) {
      debugPrint('Time zone not found, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
      return 'UTC';
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
  Future<void> schedule(List<NotificationRequest> requests) async {}
  @override
  Future<String> refreshTimeZone() async => 'UTC';
}
