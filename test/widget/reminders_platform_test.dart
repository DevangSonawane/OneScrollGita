import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';

import '../helpers.dart';

const _batteryTip = 'battery settings';

Future<void> openReminders(TestApp app, WidgetTester tester) async {
  unawaited(app.container.read(routerProvider).push('/profile/reminders'));
  await settle(tester, 4);
}

void main() {
  testWidgets('battery tip shows on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final app = await pumpApp(tester);
    await openReminders(app, tester);
    expect(find.textContaining(_batteryTip), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('battery tip is hidden on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final app = await pumpApp(tester);
    await openReminders(app, tester);
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.textContaining(_batteryTip), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
