import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/features/gita/reader_screen.dart';

import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

/// Real fingers: slow and quick, from the middle and from low on screen.
final _gestures = <(String, Future<void> Function(WidgetTester))>[
  ('small drag', (t) => t.drag(find.byType(PageView), const Offset(0, -120))),
  ('flick', (t) => t.fling(find.byType(PageView), const Offset(0, -300), 2500)),
  ('long drag', (t) => t.drag(find.byType(PageView), const Offset(0, -2000))),
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
  (
    'two flicks',
    (t) async {
      await t.fling(find.byType(PageView), const Offset(0, -300), 2500);
      await t.pump(const Duration(milliseconds: 120));
      await t.fling(find.byType(PageView), const Offset(0, -300), 2500);
    },
  ),
];

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final (name, act) in _gestures) {
      testWidgets('long verse (${platform.name}): $name stays', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final app = await pumpApp(tester, size: const Size(402, 874));
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
}
