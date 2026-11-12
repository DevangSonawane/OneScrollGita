import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/premium_providers.dart';
import 'package:versescroll/data/purchases/purchase_gateway.dart';
import 'package:versescroll/domain/premium.dart';
import 'package:versescroll/features/premium/paywall_screen.dart';
import 'package:versescroll/features/premium/sadhak_card.dart';

import '../fakes/fake_purchase_gateway.dart';
import '../helpers.dart';

Future<TestApp> openSadhak(
  WidgetTester tester, {
  FakePurchaseGateway? store,
  String path = '/sadhak',
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reducedMotion = false,
  Brightness brightness = Brightness.light,
}) async {
  final app = await pumpApp(
    tester,
    purchases: store,
    size: size,
    textScale: textScale,
    reducedMotion: reducedMotion,
    brightness: brightness,
  );
  unawaited(app.container.read(routerProvider).push(path));
  await settle(tester, 5);
  return app;
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await settle(tester);
  await tester.tap(f);
  await settle(tester);
}

void main() {
  testWidgets('shows the offer with store prices, yearly pre-selected', (
    tester,
  ) async {
    await openSadhak(tester);
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.text('Go deeper into the Gita'), findsOneWidget);
    expect(find.text('₹699.00'), findsOneWidget);
    expect(find.text('₹1,999.00'), findsOneWidget);
    expect(find.text('Just ₹58 a month'), findsOneWidget);
    expect(find.textContaining('stays free'), findsOneWidget);
    expect(find.textContaining('Renews every year at ₹699.00'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Yearly'))),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Lifetime'))),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('choosing lifetime changes the terms line', (tester) async {
    await openSadhak(tester);
    await tapVisible(tester, find.text('Lifetime'));
    expect(find.text('One payment of ₹1,999.00. No renewal.'), findsOneWidget);
  });

  testWidgets('buying shows the welcome and unlocks Sadhak', (tester) async {
    final store = FakePurchaseGateway(buyResult: PurchaseOutcome.purchased);
    final app = await openSadhak(tester, store: store);
    await tapVisible(tester, find.bySemanticsLabel('Continue'));
    await settle(tester, 6);
    expect(store.bought, [SadhakProducts.yearly]);
    expect(find.text('Welcome, Sadhak'), findsOneWidget);
    expect(app.container.read(isPremiumProvider), isTrue);
    await tester.tap(find.text('Begin'));
    await settle(tester);
    expect(find.byType(PaywallScreen), findsNothing);
  });

  testWidgets('cancelled purchase stays on the offer, no message', (
    tester,
  ) async {
    await openSadhak(
      tester,
      store: FakePurchaseGateway(buyResult: PurchaseOutcome.cancelled),
    );
    await tapVisible(tester, find.bySemanticsLabel('Continue'));
    expect(find.text('Go deeper into the Gita'), findsOneWidget);
    expect(find.textContaining('did not go through'), findsNothing);
  });

  testWidgets('restore with nothing to restore explains it', (tester) async {
    await openSadhak(tester, store: FakePurchaseGateway(owned: {}));
    await tapVisible(tester, find.text('Restore purchase'));
    expect(find.textContaining('No earlier Sadhak purchase'), findsOneWidget);
  });

  testWidgets('store unavailable offers to try again', (tester) async {
    final store = FakePurchaseGateway(plans: []);
    await openSadhak(tester, store: store);
    expect(find.textContaining('Plans could not be loaded'), findsOneWidget);
    store.plans = FakePurchaseGateway().plans;
    await tapVisible(tester, find.text('Try again'));
    expect(find.text('₹699.00'), findsOneWidget);
  });

  testWidgets('a locked feature explains why the paywall opened', (
    tester,
  ) async {
    await openSadhak(tester, path: '/sadhak?reason=unlimitedNotes');
    expect(find.text('Unlimited notes are part of Sadhak'), findsOneWidget);
  });

  testWidgets('already premium shows the thank-you view', (tester) async {
    final app = await pumpApp(tester);
    await app.container
        .read(entitlementProvider.notifier)
        .setPretendPremium(true);
    unawaited(app.container.read(routerProvider).push('/sadhak'));
    await settle(tester, 5);
    expect(find.text('You are a Sadhak'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('close button returns', (tester) async {
    await openSadhak(tester);
    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);
    expect(find.byType(PaywallScreen), findsNothing);
  });

  for (final (name, size, scale, dark) in [
    ('360 px, text scale 2.0', const Size(360, 740), 2.0, false),
    ('390 px, dark', const Size(390, 844), 1.0, true),
  ]) {
    testWidgets('fits without overflow: $name', (tester) async {
      await openSadhak(
        tester,
        size: size,
        textScale: scale,
        brightness: dark ? Brightness.dark : Brightness.light,
      );
      expect(tester.takeException(), isNull);
      // The one action stays on screen.
      final cta = tester.getRect(find.bySemanticsLabel('Continue'));
      expect(cta.bottom, lessThanOrEqualTo(size.height));
      expect(cta.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('reduced motion renders the offer immediately', (tester) async {
    final app = await pumpApp(tester, reducedMotion: true);
    unawaited(app.container.read(routerProvider).push('/sadhak'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final title = find.text('Go deeper into the Gita');
    expect(title, findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: title, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1);
    // No ambient ticker keeps running.
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('Profile shows the Sadhak card and opens the paywall', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Profile, tab')));
    await settle(tester);
    expect(find.byType(SadhakCard), findsOneWidget);
    await tester.tap(find.byType(SadhakCard));
    await settle(tester, 5);
    expect(find.byType(PaywallScreen), findsOneWidget);
  });
}
