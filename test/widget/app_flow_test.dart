import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/core/design/components.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/features/gita/reader_screen.dart';
import 'package:versescroll/features/purport/purport_screen.dart';

import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

/// Real verses are long, so buttons may start below the fold.
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await settle(tester);
  await tester.tap(f);
  await settle(tester);
}

final _chip = find.textContaining(RegExp(r'^Bhagavad-gītā \d'));

void main() {
  testWidgets('first launch: choose Hindi, Begin, land on Home', (
    tester,
  ) async {
    final app = await pumpApp(tester, prefs: const {});
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('One Scroll Gita'), findsOneWidget);
    // The numbers come from the dataset.
    expect(find.text('chapters'), findsOneWidget);
    // Owner decision (2026-11-22): no Skip anywhere in first launch.
    expect(find.text('Skip'), findsNothing);
    await tester.ensureVisible(find.text('हिन्दी'));
    await tester.tap(find.text('हिन्दी'));
    await tester.pump();
    await tester.tap(find.text('Begin'));
    await settle(tester);
    expect(find.text('What brings you to the Gita?'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.text('Peace'));
    await settle(tester);
    await tester.ensureVisible(find.text('I have read it'));
    await tester.tap(find.text('I have read it'));
    await settle(tester);
    await tester.tap(find.text('I will come back on my own'));
    await settle(tester);
    expect(find.text("TODAY'S VERSE"), findsOneWidget);
    final s = app.container.read(settingsProvider);
    expect(s.firstLaunchDone, isTrue);
    expect(s.languageCode, 'hi');
    expect(app.prefs.getBool(SettingsRepository.kFirstLaunch), isTrue);
  });

  testWidgets('home shows today\'s verse; same all day, changes next day', (
    tester,
  ) async {
    await pumpApp(tester, now: DateTime(2026, 10, 28, 8));
    expect(find.text('Wednesday, 28 October'), findsOneWidget);
    expect(find.text("TODAY'S VERSE"), findsOneWidget);
    expect(tester.widget<Text>(_chip).data, isNotNull);
  });

  testWidgets('favourite on Home updates the Profile count', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.bySemanticsLabel('Add to favourites'));
    expect(find.bySemanticsLabel('Remove from favourites'), findsOneWidget);
    await tapTab(tester, 'Profile');
    final row = find
        .ancestor(of: find.text('Favourites'), matching: find.byType(Row))
        .first;
    expect(find.descendant(of: row, matching: find.text('1')), findsOneWidget);
  });

  testWidgets('Read in Gita opens the reader at the daily verse', (
    tester,
  ) async {
    final app = await pumpApp(tester, now: DateTime(2026, 10, 28));
    final chip = tester.widget<Text>(_chip).data!;
    final label = chip.replaceFirst('Bhagavad-gītā ', '');
    await tapVisible(tester, find.text('Read in Gita'));
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    expect(reader.current!.label, label);
    // Position is saved (debounced).
    await tester.pump(const Duration(seconds: 1));
    expect(
      app.container.read(settingsProvider).lastVerseId,
      reader.current!.id,
    );
  });

  testWidgets('reader: swipe, language switch keeps entry, history after 2 s', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    expect(reader.current!.id, 'bg-01-001');
    expect(find.textContaining(RegExp(r'^1\.1 · ')), findsOneWidget);

    // Reels-style: swipe up for the next verse.
    await swipeToNextVerse(tester, () => reader.current!.id);
    expect(reader.current!.id, 'bg-01-002');

    await tester.tap(find.bySemanticsLabel('Hindi translation'));
    await settle(tester);
    expect(reader.current!.id, 'bg-01-002');
    expect(app.container.read(languageProvider), 'hi');

    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    final history = await tester.runAsync(
      () => app.userData.watchHistory().first,
    );
    expect(history!.map((e) => e.verseId), contains('bg-01-002'));
  });

  testWidgets('reader: first entry has no previous; range entry; chapter end', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    await tester.fling(
      find.byKey(ReaderScreen.scrollKey),
      const Offset(0, 400),
      1500,
    );
    await settle(tester);
    expect(reader.current!.id, 'bg-01-001');

    app.container.read(readerJumpProvider.notifier).request('bg-01-017');
    await settle(tester);
    expect(reader.current!.id, 'bg-01-016-018');
    expect(find.textContaining(RegExp(r'^1\.16-18 · ')), findsOneWidget);

    app.container.read(readerJumpProvider.notifier).request('bg-01-046');
    await settle(tester);
    await tapVisible(tester, find.text('Continue to Chapter 2'));
    expect(reader.current!.id, 'bg-02-001');

    app.container.read(readerJumpProvider.notifier).request('bg-18-078');
    await settle(tester);
    final end = find.text('You have reached the end of the Gita');
    await tester.ensureVisible(end);
    expect(end, findsOneWidget);
  });

  testWidgets('go to verse: chapter tile, verse grid, reference box', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));

    // Chapter pill opens the sheet; pick chapter 2, then verse 47.
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Chapter 1, .*Choose chapter')),
    );
    await settle(tester);
    expect(find.text('Go to verse'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Chapter 2, ')));
    await settle(tester);
    expect(find.text('Chapter 2 · 72 verses'), findsOneWidget);
    final v = find.bySemanticsLabel(RegExp(r'^Verse 2\.47'));
    await tester.scrollUntilVisible(
      v,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(v);
    await settle(tester);
    await tester.tap(v);
    await settle(tester, 5);
    expect(reader.current!.id, 'bg-02-047');

    // Verse pill opens the same sheet; type a reference.
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Chapter 2, .*verse 2\.47\. Choose')),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField), '18.66');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await settle(tester, 5);
    expect(reader.current!.id, 'bg-18-066');
  });

  testWidgets('go to verse: a bad reference explains itself', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Chapter 1, .*Choose chapter')),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField), '2.99');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await settle(tester);
    expect(find.text('Try a reference like 2.47'), findsOneWidget);
  });

  testWidgets('purport: opens, long text, back returns to the same entry', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    // The current verse's own Purport button (the next verse is laid out
    // below it in the same scroll).
    final purport = find.descendant(
      of: find.byKey(ValueKey(reader.current!.id)),
      matching: find.text('Purport'),
    );
    await Scrollable.ensureVisible(tester.element(purport), alignment: 0.5);
    await settle(tester);
    await tester.tap(purport);
    await settle(tester);
    expect(find.byType(PurportScreen), findsOneWidget);
    expect(find.textContaining('BHAGAVAD-GITA'), findsOneWidget);
    // A long purport scrolls without overflow.
    await tester.fling(
      find.byType(CustomScrollView).last,
      const Offset(0, -20000),
      8000,
    );
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.byType(PurportScreen), findsNothing);
    expect(reader.current!.id, 'bg-01-001');
  });

  testWidgets('purport: Hindi purport shows without the English note', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await app.container.read(settingsProvider.notifier).setLanguage('hi');
    app.container.read(readerJumpProvider.notifier).request('bg-02-001');
    await tapTab(tester, 'Gita');
    // The current verse's own Purport button (the next verse is laid out
    // below it in the same scroll).
    final purport = find.descendant(
      of: find.byKey(
        ValueKey(
          tester
              .state<ReaderScreenState>(find.byType(ReaderScreen))
              .current!
              .id,
        ),
      ),
      matching: find.text('Purport'),
    );
    await Scrollable.ensureVisible(tester.element(purport), alignment: 0.5);
    await settle(tester);
    await tester.tap(purport);
    await settle(tester);
    expect(find.byType(PurportScreen), findsOneWidget);
    expect(find.textContaining('BHAGAVAD-GITA'), findsOneWidget);
    // Every bundled entry has a Hindi purport; the English fallback is
    // covered in test/domain/verse_entry_test.dart.
    expect(find.text('Purport is available in English.'), findsNothing);
  });

  testWidgets('entry without purport hides the Purport button', (tester) async {
    final app = await pumpApp(tester);
    app.container.read(readerJumpProvider.notifier).request('bg-01-005');
    await tapTab(tester, 'Gita');
    expect(find.text('Purport'), findsNothing);
  });

  testWidgets('tabs keep their own state', (tester) async {
    final app = await pumpApp(tester);
    app.container.read(readerJumpProvider.notifier).request('bg-03-012');
    await tapTab(tester, 'Gita');
    await tapTab(tester, 'Profile');
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    expect(reader.current!.id, 'bg-03-012');
  });

  testWidgets('empty states and library list', (tester) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Profile');
    await tester.tap(find.text('Favourites'));
    await settle(tester);
    expect(find.text('No favourites yet'), findsOneWidget);
    await tester.tap(find.text('Open the Gita'));
    await settle(tester);
    expect(find.byType(ReaderScreen), findsOneWidget);

    await tester.runAsync(() => app.userData.setBookmark('bg-02-047', true));
    // The Profile tab remembers the Favourites page; tapping it again
    // returns to the Profile root.
    await tapTab(tester, 'Profile');
    await tapTab(tester, 'Profile');
    await tester.tap(find.text('Bookmarks'));
    await settle(tester);
    expect(find.text('2.47'), findsOneWidget);
    // Swipe to remove, then undo.
    await tester.drag(find.text('2.47'), const Offset(-500, 0));
    await settle(tester);
    expect(find.text('Nothing bookmarked'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('2.47'), findsOneWidget);

    await tester.tap(find.byType(LucideBackButton));
    await settle(tester);
    await tester.tap(find.text('History'));
    await settle(tester);
    // "Open the Gita" above opened 1.1 for over 2 s, so it is in history.
    expect(find.text('1.1'), findsOneWidget);
  });

  testWidgets('reset all data returns to first launch', (tester) async {
    final app = await pumpApp(tester);
    await tester.runAsync(() => app.userData.setFavourite('bg-01-001', true));
    await tapTab(tester, 'Profile');
    // Profile is taller since v2 (streak card); scroll its vertical list,
    // not the first Scrollable in the tree.
    await tester.scrollUntilVisible(
      find.text('Reset all saved data'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tapVisible(tester, find.text('Reset all saved data'));
    await tester.tap(find.text('Reset'));
    await settle(tester);
    expect(find.text('Begin'), findsOneWidget);
    expect(await tester.runAsync(app.userData.allReferencedIds), isEmpty);
  });

  testWidgets('theme setting switches to dark', (tester) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Profile');
    // The Study section pushes Theme below the fold.
    await tester.scrollUntilVisible(
      find.text('Dark'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tapVisible(tester, find.text('Dark'));
    expect(
      Theme.of(tester.element(find.text('Dark'))).brightness,
      Brightness.dark,
    );
    expect(app.prefs.getString(SettingsRepository.kTheme), 'dark');
  });
}
