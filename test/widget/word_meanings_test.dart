import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/core/design/reading_views.dart';
import 'package:versescroll/data/settings/settings_repository.dart';

import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

Future<void> openMeanings(WidgetTester tester) async {
  final row = find.text('Word meanings').first;
  // Centre it, so it is never under the reader's top bar.
  await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
  await settle(tester);
  await tester.tap(row);
  await settle(tester);
  expect(find.bySemanticsLabel('Hide word meanings'), findsOneWidget);
}

// Words and meanings below are read from the bundled dataset (1.1, 2.4).
void main() {
  testWidgets('reader shows word meanings from the dataset on demand', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    expect(find.byType(WordMeaningsSection), findsWidgets);
    expect(find.textContaining('King Dhṛtarāṣṭra'), findsNothing);

    await openMeanings(tester);
    expect(find.textContaining('King Dhṛtarāṣṭra'), findsOneWidget);

    await tester.tap(find.text('Word meanings').first);
    await settle(tester);
    expect(find.textContaining('King Dhṛtarāṣṭra'), findsNothing);
  });

  testWidgets('stays open across verses and shows the Hindi list', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      prefs: const {
        SettingsRepository.kFirstLaunch: true,
        SettingsRepository.kLanguage: 'hi',
      },
    );
    await tapTab(tester, 'Gita');
    await openMeanings(tester);
    expect(find.textContaining('राजा धृतराष्ट्र ने'), findsOneWidget);
    expect(app.container.read(wordMeaningsOpenProvider), isTrue);

    // 2.4 has no usable Hindi list in the source: English, with a note.
    app.container.read(readerJumpProvider.notifier).request('bg-02-004');
    await settle(tester);
    expect(
      find.textContaining('Hindi word meanings are not available'),
      findsOneWidget,
    );
  });

  testWidgets('open list fits at text scale 2.0 on a 360 px screen', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(360, 740), textScale: 2.0);
    await tapTab(tester, 'Gita');
    await openMeanings(tester);
    expect(find.textContaining('King Dhṛtarāṣṭra'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final row = tester.getSize(find.text('Word meanings').first);
    expect(row.width, lessThanOrEqualTo(360));
  });

  testWidgets('toggle is at least 48 dp and labelled', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final label = find.bySemanticsLabel('Show word meanings').first;
    expect(label, findsOneWidget);
    final size = tester.getSize(label);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });
}
