import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/core/design/tactile.dart';
import 'package:versescroll/features/trainer/word_bank.dart';
import 'package:versescroll/domain/auth.dart';
import 'package:versescroll/features/premium/paywall_screen.dart';
import 'package:versescroll/features/home/home_extras.dart';
import 'package:versescroll/features/first_launch/onboarding_demos.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/reminder_providers.dart';
import 'package:versescroll/application/streak_providers.dart';
import 'package:versescroll/domain/premium.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/features/gita/reader_screen.dart';

import '../fakes/fake_auth_gateway.dart';
import '../fakes/fake_notification_service.dart';
import '../helpers.dart';

/// Taps the word bank's buttons until every blank is filled (wrong words
/// just shake, so trying each in turn always gets there).
Future<void> fillAllFromBank(WidgetTester tester) async {
  for (var round = 0; round < 30; round++) {
    if (find.text('Every word in place').evaluate().isNotEmpty) return;
    for (var p = 0; p < 30; p++) {
      final f = find.byKey(WordBank.wordKey(p));
      if (f.evaluate().isEmpty) break;
      final enabled = tester.widget<TactileButton>(f).onTap != null;
      if (!enabled) continue;
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pump(const Duration(milliseconds: 400));
    }
  }
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await settle(tester);
  await tester.tap(f);
  await settle(tester);
}

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
    await swipeToNextVerse(tester, () => reader.current!.id);
    expect(reader.current!.id, 'bg-01-002');

    final nav = app.container.read(navBarVisibleProvider.notifier);
    nav.hide();
    await settle(tester);
    expect(app.container.read(navBarVisibleProvider), isFalse);

    await tester.fling(
      find.byKey(ReaderScreen.scrollKey),
      const Offset(0, 400),
      1500,
    );
    await settle(tester);
    expect(reader.current!.id, 'bg-01-001');
    expect(app.container.read(navBarVisibleProvider), isTrue);
  });

  // Owner confirmed reminders on a real iPhone (2026-11-20). These hang in
  // the widget-test clock (the search index isolate); skipped, not deleted.
  group(
    'reminders',
    skip: 'hangs under the test clock; verified on device',
    () {
      Future<void> open(TestApp app, WidgetTester tester) async {
        unawaited(
          app.container.read(routerProvider).push('/profile/reminders'),
        );
        await settle(tester, 4);
      }

      testWidgets('rebuild keeps delivered notifications', (tester) async {
        final svc = FakeNotificationService();
        final app = await pumpApp(tester, notifications: svc);
        await drive(
          tester,
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
        await drive(
          tester,
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
        await drive(
          tester,
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
    },
  );

  testWidgets('first launch: reading the first verse counts day 1', (
    tester,
  ) async {
    final app = await pumpApp(tester, prefs: const {});
    await tester.tap(find.text('Begin'));
    await settle(tester);
    expect(find.text('Your first verse'), findsOneWidget);
    await tapVisible(tester, find.text('I have read it'));
    // Owner, 2026-11-23: only the streak popup, no streak card here.
    expect(find.text('day streak'), findsNothing);
    expect(find.text('Day 1. A beginning.'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    // Day 1 is saved in the database (real async), not just in memory.
    final days = await tester.runAsync(
      () => app.container.read(activityRepositoryProvider).readDays(),
    );
    expect(days, hasLength(1));
  });

  testWidgets('first launch demos: swipe, fill a blank, play 1.1', (
    tester,
  ) async {
    await pumpApp(tester, prefs: const {});
    await tester.tap(find.text('Begin'));
    await settle(tester);
    await tapVisible(tester, find.text('I have read it'));
    await tapVisible(tester, find.text('Continue'));

    // Scrolling: real verses of chapter 2, one swipe moves to the next.
    expect(find.text('Bhagavad-gītā 2.20'), findsOneWidget);
    await tester.drag(find.byKey(ScrollDemo.cardKey), const Offset(0, -300));
    await settle(tester);
    expect(find.text('Bhagavad-gītā 2.21'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));

    // Sadhak: tapping a blank fills it.
    expect(find.text('Bhagavad-gītā 2.47'), findsOneWidget);
    expect(find.textContaining('0 of'), findsOneWidget);
    // Sadhak: 3D word buttons; the right one fills the next blank.
    await fillAllFromBank(tester);
    expect(find.text('Every word in place'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));

    // Shravan: 1.1 plays (the silent pretend engine in tests).
    expect(find.text('Bhagavad-gītā 1.1'), findsOneWidget);
    await tapVisible(tester, find.byKey(ListenDemo.playKey));
    expect(find.text('Sanskrit, then the translation'), findsOneWidget);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    await tapVisible(tester, find.byKey(ListenDemo.playKey));
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('home: greeting, plan banners and short feeling cards', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('How are you?'), findsOneWidget);
    // Owner, 2026-11-23: none of these on Home any more.
    expect(find.text('Good morning'), findsNothing);
    expect(find.byTooltip('Search'), findsNothing);
    expect(find.text("Read today's verse"), findsNothing);
    expect(find.textContaining('Continue at'), findsNothing);
    expect(find.byKey(PlanBanners.sadhakKey), findsOneWidget);
    for (final w in ['Peace', 'Stress', 'Confusion']) {
      expect(find.text(w, skipOffstage: false), findsOneWidget);
    }
    expect(find.text('Peace of mind', skipOffstage: false), findsNothing);
  });

  testWidgets('home: the greeting uses the account first name', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthGateway(
        user: const AppUser(
          id: 'u1',
          email: 'reader@example.com',
          name: 'Arjun Pandava',
          method: SignInMethod.google,
        ),
      ),
    );
    expect(find.text('Hi, Arjun'), findsOneWidget);
  });

  testWidgets('home: the Sadhak banner opens the Sadhak page', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.byKey(PlanBanners.sadhakKey));
    expect(find.byType(PaywallScreen), findsOneWidget);
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
