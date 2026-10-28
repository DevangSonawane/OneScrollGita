import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/features/gita/reader_screen.dart';

import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

void main() {
  testWidgets('first launch: choose Hindi, Begin, land on Home', (tester) async {
    final app = await pumpApp(tester, prefs: const {});
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('Read the Bhagavad-gita As It Is. No account. No internet needed.'), findsOneWidget);
    await tester.tap(find.text('हिन्दी'));
    await tester.pump();
    await tester.tap(find.text('Begin'));
    await settle(tester);
    expect(find.text("TODAY'S VERSE"), findsOneWidget);
    final s = app.container.read(settingsProvider);
    expect(s.firstLaunchDone, isTrue);
    expect(s.languageCode, 'hi');
    expect(app.prefs.getBool(SettingsRepository.kFirstLaunch), isTrue);
  });

  testWidgets('home shows today\'s verse; same all day, changes next day', (tester) async {
    await pumpApp(tester, now: DateTime(2026, 10, 28, 8));
    expect(find.text('Wednesday, 28 October'), findsOneWidget);
    expect(find.textContaining('Placeholder translation for Bhagavad-gita'), findsOneWidget);
    final chip = tester.widget<Text>(find.textContaining(RegExp(r'^Bhagavad-gita \d'))).data;
    expect(chip, isNotNull);
  });

  testWidgets('favourite on Home updates the Profile count', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Add to favourites'));
    await settle(tester);
    expect(find.bySemanticsLabel('Remove from favourites'), findsOneWidget);
    await tapTab(tester, 'Profile');
    final row = find.ancestor(of: find.text('Favourites'), matching: find.byType(Row)).first;
    expect(find.descendant(of: row, matching: find.text('1')), findsOneWidget);
  });

  testWidgets('Read in Gita opens the reader at the daily verse', (tester) async {
    final app = await pumpApp(tester, now: DateTime(2026, 10, 28));
    final chip = tester.widget<Text>(find.textContaining(RegExp(r'^Bhagavad-gita \d'))).data!;
    final label = chip.replaceFirst('Bhagavad-gita ', '');
    await tester.tap(find.text('Read in Gita'));
    await settle(tester);
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    expect(reader.current!.label, label);
    // Position is saved (debounced).
    await tester.pump(const Duration(seconds: 1));
    expect(app.container.read(settingsProvider).lastVerseId, reader.current!.id);
  });

  testWidgets('reader: swipe, language switch keeps entry, history after 2 s', (tester) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    expect(reader.current!.id, 'bg-01-001');
    expect(find.text('1.1'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await settle(tester);
    expect(reader.current!.id, 'bg-01-002');

    await tester.tap(find.bySemanticsLabel('Hindi translation'));
    await settle(tester);
    expect(reader.current!.id, 'bg-01-002');
    expect(find.textContaining('का प्लेसहोल्डर अनुवाद'), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    final history = await tester.runAsync(() => app.userData.watchHistory().first);
    expect(history!.map((e) => e.verseId), contains('bg-01-002'));
  });

  testWidgets('reader: first entry has no previous; range entry; chapter end', (tester) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
    await settle(tester);
    expect(reader.current!.id, 'bg-01-001');

    app.container.read(readerJumpProvider.notifier).request('bg-01-017');
    await settle(tester);
    expect(reader.current!.id, 'bg-01-016-018');
    expect(find.text('1.16-18'), findsOneWidget);

    app.container.read(readerJumpProvider.notifier).request('bg-01-047');
    await settle(tester);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -800));
    await settle(tester);
    expect(find.text('Continue to Chapter 2'), findsOneWidget);
    await tester.tap(find.text('Continue to Chapter 2'));
    await settle(tester);
    expect(reader.current!.id, 'bg-02-001');

    app.container.read(readerJumpProvider.notifier).request('bg-18-078');
    await settle(tester);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -800));
    await settle(tester);
    expect(find.text('You have reached the end of the Gita'), findsOneWidget);
  });

  testWidgets('chapter sheet and verse selector', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));

    await tester.tap(find.bySemanticsLabel(RegExp(r'^Chapter 1, .*Choose chapter')));
    await settle(tester);
    expect(find.text('Chapters'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Chapter 2, .*72 verses')));
    await settle(tester);
    expect(reader.current!.id, 'bg-02-001');

    await tester.tap(find.bySemanticsLabel(RegExp(r'^Verse 2.1\. Choose verse')));
    await settle(tester);
    expect(find.text('Chapter 2 - 72 verses'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Verse 2\.47')));
    await settle(tester);
    expect(reader.current!.id, 'bg-02-047');
  });

  testWidgets('purport: opens, long text, back returns to the same entry', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Gita');
    final reader = tester.state<ReaderScreenState>(find.byType(ReaderScreen));
    await tester.tap(find.text('Purport'));
    await settle(tester);
    expect(find.text('PURPORT'), findsOneWidget);
    // 4,000-word placeholder purport scrolls without overflow.
    await tester.fling(find.byType(CustomScrollView), const Offset(0, -20000), 8000);
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.text('PURPORT'), findsNothing);
    expect(reader.current!.id, 'bg-01-001');
  });

  testWidgets('purport: Hindi with English-only purport shows a note', (tester) async {
    final app = await pumpApp(tester);
    await app.container.read(settingsProvider.notifier).setLanguage('hi');
    app.container.read(readerJumpProvider.notifier).request('bg-02-001');
    await tapTab(tester, 'Gita');
    await tester.tap(find.text('Purport'));
    await settle(tester);
    expect(find.text('Purport is available in English.'), findsOneWidget);
  });

  testWidgets('entry without purport hides the Purport button', (tester) async {
    final app = await pumpApp(tester);
    app.container.read(readerJumpProvider.notifier).request('bg-02-009');
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

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.text('History'));
    await settle(tester);
    expect(find.text('No reading history'), findsOneWidget);
  });

  testWidgets('reset all data returns to first launch', (tester) async {
    final app = await pumpApp(tester);
    await tester.runAsync(() => app.userData.setFavourite('bg-01-001', true));
    await tapTab(tester, 'Profile');
    await tester.scrollUntilVisible(find.text('Reset all saved data'), 200);
    await tester.tap(find.text('Reset all saved data'));
    await settle(tester);
    await tester.tap(find.text('Reset'));
    await settle(tester);
    expect(find.text('Begin'), findsOneWidget);
    expect(await tester.runAsync(app.userData.allReferencedIds), isEmpty);
  });

  testWidgets('theme setting switches to dark', (tester) async {
    final app = await pumpApp(tester);
    await tapTab(tester, 'Profile');
    await tester.tap(find.text('Dark'));
    await settle(tester);
    expect(Theme.of(tester.element(find.text('Your library'))).brightness, Brightness.dark);
    expect(app.prefs.getString(SettingsRepository.kTheme), 'dark');
  });
}
