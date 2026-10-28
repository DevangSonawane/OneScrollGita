import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/core/design/glass_nav_bar.dart';
import 'package:versescroll/data/settings/settings_repository.dart';

import '../helpers.dart';

/// Every screen on a 360 x 640 phone at text scales 1.0, 1.3 and 2.0, in
/// both themes, at the largest reading size. Any overflow fails the test.
void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('all screens fit: ${brightness.name}, text scale $scale', (tester) async {
        final app = await pumpApp(
          tester,
          size: const Size(360, 640),
          textScale: scale,
          brightness: brightness,
          prefs: const {
            SettingsRepository.kFirstLaunch: true,
            SettingsRepository.kTextScale: 4,
          },
        );
        // Home
        expect(find.text("TODAY'S VERSE"), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
        await settle(tester);

        // Reader, chapter sheet, verse selector
        await tester.tap(find.bySemanticsLabel(RegExp('^Gita, tab')));
        await settle(tester);
        await tester.tap(find.bySemanticsLabel(RegExp(r'Choose chapter$')));
        await settle(tester);
        await tester.tapAt(const Offset(10, 10));
        await settle(tester);
        await tester.tap(find.bySemanticsLabel(RegExp(r'Choose verse$')));
        await settle(tester);
        await tester.tapAt(const Offset(10, 10));
        await settle(tester);

        // Purport
        await tester.scrollUntilVisible(find.text('Purport'), 200, scrollable: find.byType(Scrollable).last);
        await tester.tap(find.text('Purport'));
        await settle(tester);
        await tester.tap(find.bySemanticsLabel('Text size'));
        await settle(tester);
        await tester.tapAt(const Offset(10, 600));
        await settle(tester);
        await tester.tap(find.bySemanticsLabel('Back'));
        await settle(tester);

        // Profile, About, Specimen, lists
        await tester.tap(find.bySemanticsLabel(RegExp('^Profile, tab')));
        await settle(tester);
        await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
        await settle(tester);
        app.container.read(navBarVisibleProvider.notifier).show();
        for (final path in ['about', 'specimen', 'favourites', 'bookmarks', 'history']) {
          app.container.read(routerProvider).go('/profile/$path');
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('reduced motion keeps the nav pill visible', (tester) async {
    await pumpApp(tester, reducedMotion: true);
    await tester.tap(find.bySemanticsLabel(RegExp('^Profile, tab')));
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await settle(tester);
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(of: find.byType(GlassNavBar), matching: find.byType(AnimatedOpacity)),
    );
    expect(opacity.opacity, 1);
  });

  testWidgets('nav pill hides on scroll down and returns on scroll up', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Profile, tab')));
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await settle(tester);
    expect(app.container.read(navBarVisibleProvider), isFalse);
    await tester.drag(find.byType(ListView).first, const Offset(0, 200));
    await settle(tester);
    expect(app.container.read(navBarVisibleProvider), isTrue);
  });

  testWidgets('glass fallback: frosted without shaders, solid when simplified', (tester) async {
    final app = await pumpApp(tester, glass: null);
    // The test engine has no shader filters, so glass is frosted.
    expect(find.byType(BackdropFilter), findsWidgets);
    await app.container.read(settingsProvider.notifier).setSimplifiedGlass(true);
    await settle(tester);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
