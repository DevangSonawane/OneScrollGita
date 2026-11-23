import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/features/premium/figure_art.dart';
import 'package:versescroll/features/premium/paywall_screen.dart';

import 'package:versescroll/data/settings/settings_repository.dart';

import '../helpers.dart';
import '../real_fonts.dart';

ScrollPosition _paywallScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(PaywallScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

Future<void> _open(
  WidgetTester tester,
  String path, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  final app = await pumpApp(tester, size: size, textScale: textScale);
  unawaited(app.container.read(routerProvider).push(path));
  await settle(tester, 5);
}

void main() {
  setUpAll(loadRealFonts);

  for (final (path, pose) in [
    ('/sadhak', FigurePose.reading),
    ('/shravan', FigurePose.listening),
  ]) {
    testWidgets('$path fits one screen, no scrolling (PRD_v6 3)', (
      tester,
    ) async {
      await _open(tester, path);
      if (find.byType(PaywallScreen).evaluate().isEmpty) return; // no route
      expect(_paywallScroll(tester).maxScrollExtent, 0);
      final figure = tester.widget<SeekerFigure>(find.byType(SeekerFigure));
      expect(figure.pose, pose);
    });
  }

  testWidgets('small phone (iPhone SE) still fits', (tester) async {
    await _open(tester, '/sadhak', size: const Size(375, 667));
    expect(_paywallScroll(tester).maxScrollExtent, 0);
  });

  testWidgets('text scale 2.0 scrolls instead of overflowing', (tester) async {
    await _open(tester, '/sadhak', textScale: 2);
    expect(tester.takeException(), isNull);
    expect(_paywallScroll(tester).maxScrollExtent, greaterThan(0));
  });

  testWidgets('iOS pushed pages use the native route (swipe back)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final app = await pumpApp(tester);
    unawaited(app.container.read(routerProvider).push('/search'));
    await settle(tester, 4);
    final route = ModalRoute.of(tester.element(find.byType(TextField).first));
    final cupertino = route is CupertinoRouteTransitionMixin;
    debugDefaultTargetPlatformOverride = null;
    expect(cupertino, isTrue);
  });

  for (final page in [
    'bookmarks',
    'favourites',
    'history',
    'reminders',
    'about',
  ]) {
    testWidgets('iOS: edge swipe on Profile > $page goes back', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final app = await pumpApp(tester);
      final router = app.container.read(routerProvider);
      router.go('/profile/$page');
      await settle(tester, 4);
      await edgeSwipe(tester);
      final loc = router.routerDelegate.currentConfiguration.uri.toString();
      debugDefaultTargetPlatformOverride = null;
      expect(loc, '/profile');
      await tester.pump(const Duration(seconds: 2));
    });
  }

  testWidgets('Home: no Continue reading card or button (owner, 2026-11-23)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: const {
        SettingsRepository.kFirstLaunch: true,
        SettingsRepository.kLastVerse: 'bg-02-024',
      },
    );
    expect(find.text('CONTINUE READING', skipOffstage: false), findsNothing);
    expect(find.text('Continue at 2.24'), findsNothing);
  });
}

/// Edge swipe from the left on iOS, like a finger.
Future<void> edgeSwipe(WidgetTester tester) async {
  final g = await tester.startGesture(const Offset(4, 400));
  for (var i = 0; i < 10; i++) {
    await g.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await settle(tester, 3);
}
