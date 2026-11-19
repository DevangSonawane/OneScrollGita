import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:versescroll/data/notifications/notification_service.dart';
import 'package:versescroll/domain/models/written_content.dart';

NotificationRequest _req(int id, DateTime at) => NotificationRequest(
  id: id,
  at: at,
  category: MessageCategory.invite,
  title: 't',
  body: 'b',
);

void main() {
  final now = DateTime(2026, 11, 20, 7, 59, 30);

  test('one failure does not stop the rest', () async {
    final done = <int>[];
    final report = await scheduleEach(
      [
        _req(1, DateTime(2026, 11, 20, 20, 30)),
        _req(2, DateTime(2026, 11, 21, 8)),
        _req(3, DateTime(2026, 11, 22, 8)),
      ],
      now,
      (r) async {
        if (r.id == 2) throw ArgumentError('boom');
        done.add(r.id);
      },
    );
    expect(done, [1, 3]);
    expect(report.scheduled, 2);
    expect(report.failed, 1);
    expect(report.lastError, isA<ArgumentError>());
  });

  test('times less than a minute away are skipped, not sent', () async {
    final done = <int>[];
    final report = await scheduleEach(
      [
        _req(1, DateTime(2026, 11, 20, 8)), // 30 s away
        _req(2, DateTime(2026, 11, 20, 8, 1)), // 90 s away
      ],
      now,
      (r) async => done.add(r.id),
    );
    expect(done, [2]);
    expect(report.skipped, 1);
  });

  group('time-zone fallback', () {
    setUpAll(tzdata.initializeTimeZones);

    test('uses a zone with the device offset, not UTC', () {
      final at = DateTime.utc(2026, 11, 20);
      final z = zoneForOffset(const Duration(hours: 5, minutes: 30), at: at);
      expect(z.name, isNot('UTC'));
      expect(
        z.timeZone(at.millisecondsSinceEpoch).offset,
        const Duration(hours: 5, minutes: 30),
      );
      expect(z.name.startsWith('Etc/'), isFalse);
    });

    test('zero offset may stay UTC-like', () {
      final at = DateTime.utc(2026, 11, 20);
      final z = zoneForOffset(Duration.zero, at: at);
      expect(z.timeZone(at.millisecondsSinceEpoch).offset, Duration.zero);
    });
  });
}
