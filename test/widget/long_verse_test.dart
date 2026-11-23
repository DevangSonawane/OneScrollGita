import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/features/gita/reader_screen.dart';

import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

/// Real fingers: slow and quick, from the middle and from low on screen.
final _gestures = <(String, Future<void> Function(WidgetTester))>[
  (
    'small drag',
    (t) => t.drag(find.byKey(ReaderScreen.scrollKey), const Offset(0, -120)),
  ),
  (
    'flick',
    (t) => t.fling(
      find.byKey(ReaderScreen.scrollKey),
      const Offset(0, -300),
      2500,
    ),
  ),
  (
    'slow drag from low',
    (t) => t.timedDragFrom(
      const Offset(200, 620),
      const Offset(0, -200),
      const Duration(milliseconds: 600),
    ),
  ),
  (
    'quick flick from low',
    (t) => t.flingFrom(const Offset(200, 640), const Offset(0, -250), 3000),
  ),
];

/// These verses are long at the Medium reading size (the default before
/// 2026-11-23); the test keeps that size so they stay taller than the screen.
const _mediumText = {
  SettingsRepository.kFirstLaunch: true,
  SettingsRepository.kTextScale: 2,
};

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final (name, act) in _gestures) {
      testWidgets('long verse (${platform.name}): $name stays', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final app = await pumpApp(
          tester,
          prefs: _mediumText,
          size: const Size(402, 874),
        );
        await tapTab(tester, 'Gita');
        app.container.read(readerJumpProvider.notifier).request('bg-02-007');
        await settle(tester);
        final reader = tester.state<ReaderScreenState>(
          find.byType(ReaderScreen),
        );
        expect(reader.current!.id, 'bg-02-007');
        await act(tester);
        await settle(tester);
        final id = reader.current!.id;
        debugDefaultTargetPlatformOverride = null;
        expect(id, 'bg-02-007');
      });
    }
  }

  testWidgets('long verse: a flick stops at its end; the next one goes on', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      prefs: _mediumText,
      size: const Size(402, 874),
    );
    await tapTab(tester, 'Gita');
    app.container.read(readerJumpProvider.notifier).request('bg-02-007');
    await settle(tester);
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    // Momentum stops at the end of the verse, however hard the flick.
    await tester.fling(
      find.byKey(ReaderScreen.scrollKey),
      const Offset(0, -300),
      6000,
    );
    await settle(tester);
    expect(reader.current!.id, 'bg-02-007');
    // A swipe from the end goes to the next verse.
    await tester.fling(
      find.byKey(ReaderScreen.scrollKey),
      const Offset(0, -300),
      1500,
    );
    await settle(tester);
    expect(reader.current!.id, 'bg-02-008');
  });

  testWidgets('short verse: one quick flick turns the page', (tester) async {
    await pumpApp(tester, prefs: _mediumText, size: const Size(402, 874));
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    final start = reader.current!.id;
    await swipeToNextVerse(tester, () => reader.current!.id);
    expect(reader.current!.id, isNot(start));
  });
}
