import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/reminder_providers.dart';
import 'package:versescroll/application/streak_providers.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/premium.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/features/gita/reader_screen.dart';
import 'package:versescroll/features/home/home_screen.dart';

import '../fakes/fake_notification_service.dart';
import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

void main() {
  testWidgets('nav pill comes back when swiping to the previous verse', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
    await settle(tester);
    expect(reader.current!.id, 'bg-01-002');

    final nav = app.container.read(navBarVisibleProvider.notifier);
    nav.hide();
    await settle(tester);
    expect(app.container.read(navBarVisibleProvider), isFalse);

    await tester.fling(find.byType(PageView), const Offset(0, 400), 1500);
    await settle(tester);
    expect(reader.current!.id, 'bg-01-001');
    expect(app.container.read(navBarVisibleProvider), isTrue);
  });

  group('reminders', () {
    Future<void> open(TestApp app, WidgetTester tester) async {
      unawaited(app.container.read(routerProvider).push('/profile/reminders'));
      await settle(tester, 4);
    }

    testWidgets('rebuild keeps delivered notifications', (tester) async {
      final svc = FakeNotificationService();
      final app = await pumpApp(tester, notifications: svc);
      await tester.runAsync(
        () => app.container
            .read(reminderControllerProvider.notifier)
            .setEnabled(true),
      );
      expect(svc.cancelPendingCalls, greaterThan(0));
      expect(svc.cancelAllCalls, 0);
    });

    testWidgets('Android without exact alarms offers the system page', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final svc = FakeNotificationService(exact: false);
      final app = await pumpApp(tester, notifications: svc);
      await tester.runAsync(
        () => app.container
            .read(reminderControllerProvider.notifier)
            .setEnabled(true),
      );
      await open(app, tester);
      await tester.tap(find.text('Deliver at the exact time'));
      await settle(tester);
      expect(svc.exactSettingsOpened, 1);

      await tester.tap(find.text('Send a test notification'));
      await settle(tester);
      expect(svc.testsSent, 1);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('exact row hidden when allowed and on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final svc = FakeNotificationService(exact: false);
      final app = await pumpApp(tester, notifications: svc);
      await tester.runAsync(
        () => app.container
            .read(reminderControllerProvider.notifier)
            .setEnabled(true),
      );
      await open(app, tester);
      expect(find.text('Deliver at the exact time'), findsNothing);
      expect(find.text('Send a test notification'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('no test row while reminders are off', (tester) async {
      final app = await pumpApp(
        tester,
        notifications: FakeNotificationService(),
      );
      await open(app, tester);
      expect(find.text('Send a test notification'), findsNothing);
    });
  });

  testWidgets('guided first launch: Peace, first verse counts day 1', (
    tester,
  ) async {
    final app = await pumpApp(tester, prefs: const {});
    await tester.tap(find.text('Begin'));
    await settle(tester);
    await tester.tap(find.text('Peace'));
    await settle(tester);
    expect(find.text('Your first verse'), findsOneWidget);
    // The top verse of the dataset's "peace" theme.
    expect(find.text('Bhagavad-gītā 2.66'), findsOneWidget);
    await tester.ensureVisible(find.text('I have read it'));
    await tester.tap(find.text('I have read it'));
    await settle(tester);
    expect(find.text('Day 1. A beginning.'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);

    expect(find.text("TODAY'S VERSE"), findsOneWidget);
    expect(app.container.read(settingsProvider).lastVerseId, 'bg-02-066');
    expect(app.prefs.getString(SettingsRepository.kFirstIntent), 'peace');
    expect(app.container.read(streakStatsProvider).currentStreak, 1);
    expect(find.text('Continue at 2.66'), findsOneWidget);
  });

  testWidgets('home: feelings card and Continue in thumb reach', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text("Read today's verse"), findsOneWidget);
    final button = tester.getRect(find.byType(ContinueButton));
    expect(button.top, greaterThan(844 / 2), reason: 'lower half');
  });

  testWidgets('chapter end offers next chapter and reflect', (tester) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Gita');
    app.container.read(readerJumpProvider.notifier).request('bg-01-046');
    await settle(tester);
    expect(find.text('Continue to Chapter 2', skipOffstage: false), findsOne);
    expect(
      find.text('Reflect on this chapter', skipOffstage: false),
      findsOneWidget,
    );
  });

  group('free trial', () {
    test('parses store periods', () {
      expect(parseTrialPeriod('P7D'), const FreeTrial(7, TrialUnit.day));
      expect(parseTrialPeriod('P1W'), const FreeTrial(1, TrialUnit.week));
      expect(parseTrialPeriod('P1M')!.label, '1 month free');
      expect(parseTrialPeriod('P1Y'), isNull);
      expect(parseTrialPeriod('nonsense'), isNull);
    });

    test('label', () {
      expect(const FreeTrial(7, TrialUnit.day).label, '7 days free');
    });
  });

}
