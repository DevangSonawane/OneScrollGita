import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/library_providers.dart';
import 'package:versescroll/application/scripture_providers.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/quick_action.dart';
import 'package:versescroll/features/gita/reader_screen.dart';
import 'package:versescroll/features/profile/library_list_screen.dart';

import '../fakes/fake_quick_actions_channel.dart';
import '../helpers.dart';

String _location(TestApp app) => app.container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

String? _readerVerse(WidgetTester tester) {
  final f = find.byType(ReaderScreen);
  if (f.evaluate().isEmpty) return null;
  return tester.state<ReaderScreenState>(f).current?.id;
}

void main() {
  test('types are unique and stable', () {
    final types = QuickAction.values.map((a) => a.type).toSet();
    expect(types, hasLength(5));
    expect(
      types.every((t) => t.startsWith('com.onescrollgita.app.quick.')),
      isTrue,
    );
    expect(QuickAction.fromType('nonsense'), isNull);
  });

  testWidgets('Continue Reading opens the saved reading position', (
    tester,
  ) async {
    final channel = FakeQuickActionsChannel();
    await pumpApp(
      tester,
      prefs: const {
        SettingsRepository.kFirstLaunch: true,
        SettingsRepository.kLastVerse: 'bg-02-024',
      },
      quickActions: channel,
    );
    channel.choose(QuickAction.continueReading.type);
    await settle(tester, 5);
    expect(_readerVerse(tester), 'bg-02-024');
  });

  testWidgets('Continue Reading with nothing read starts at 1.1', (
    tester,
  ) async {
    final channel = FakeQuickActionsChannel();
    await pumpApp(tester, quickActions: channel);
    channel.choose(QuickAction.continueReading.type);
    await settle(tester, 5);
    expect(_readerVerse(tester), 'bg-01-001');
  });

  testWidgets("Today's Verse opens the daily verse", (tester) async {
    final channel = FakeQuickActionsChannel();
    final app = await pumpApp(tester, quickActions: channel);
    final daily = await tester.runAsync(
      () => app.container.read(dailyEntryProvider.future),
    );
    channel.choose(QuickAction.todaysVerse.type);
    await settle(tester, 5);
    expect(_readerVerse(tester), daily!.id);
  });

  testWidgets('Random Verse opens a verse from the dataset', (tester) async {
    final channel = FakeQuickActionsChannel();
    final app = await pumpApp(tester, quickActions: channel);
    channel.choose(QuickAction.randomVerse.type);
    await settle(tester, 5);
    final id = _readerVerse(tester);
    expect(id, isNotNull);
    final entry = await tester.runAsync(
      () => app.container.read(scriptureRepositoryProvider).entryById(id!),
    );
    expect(entry, isNotNull);
  });

  testWidgets('Bookmarks opens the bookmarks list, empty state included', (
    tester,
  ) async {
    final channel = FakeQuickActionsChannel();
    final app = await pumpApp(tester, quickActions: channel);
    channel.choose(QuickAction.bookmarks.type);
    await settle(tester, 5);
    expect(_location(app), '/profile/bookmarks');
    final list = tester.widget<LibraryListScreen>(
      find.byType(LibraryListScreen),
    );
    expect(list.kind, LibraryKind.bookmarks);
    expect(app.container.read(bookmarksProvider).value ?? const [], isEmpty);
  });

  testWidgets('a shortcut that launched the app is handled once', (
    tester,
  ) async {
    final channel = FakeQuickActionsChannel(
      initial: QuickAction.bookmarks.type,
    );
    final app = await pumpApp(tester, quickActions: channel);
    await settle(tester, 5);
    expect(_location(app), '/profile/bookmarks');
    expect(channel.initial, isNull);
  });

  testWidgets('during first launch, shortcuts wait for the welcome flow', (
    tester,
  ) async {
    final channel = FakeQuickActionsChannel(
      initial: QuickAction.randomVerse.type,
    );
    final app = await pumpApp(tester, prefs: const {}, quickActions: channel);
    await settle(tester, 5);
    expect(_location(app), startsWith('/welcome'));
  });

  group('Control Center links (gitaapp://open/quick?type=...)', () {
    testWidgets('Bookmarks link opens the bookmarks list', (tester) async {
      final app = await pumpApp(tester);
      app.container
          .read(routerProvider)
          .go('/quick?type=${QuickAction.bookmarks.type}');
      await settle(tester, 5);
      expect(_location(app), '/profile/bookmarks');
    });

    testWidgets('Continue Reading link opens the saved position', (
      tester,
    ) async {
      final app = await pumpApp(
        tester,
        prefs: const {
          SettingsRepository.kFirstLaunch: true,
          SettingsRepository.kLastVerse: 'bg-03-021',
        },
      );
      app.container
          .read(routerProvider)
          .go('/quick?type=${QuickAction.continueReading.type}');
      await settle(tester, 5);
      expect(_readerVerse(tester), 'bg-03-021');
    });

    testWidgets('an unknown link type just shows Home', (tester) async {
      final app = await pumpApp(tester);
      app.container.read(routerProvider).go('/quick?type=nonsense');
      await settle(tester, 5);
      expect(_location(app), '/home');
    });
  });

  testWidgets('Start Listening without Shravan opens the Listen library', (
    tester,
  ) async {
    final channel = FakeQuickActionsChannel();
    final app = await pumpApp(tester, quickActions: channel);
    channel.choose(QuickAction.startListening.type);
    await settle(tester, 5);
    // Nothing plays and no paywall is pushed; the library explains Shravan.
    expect(_location(app), '/listen');
  });
}
