import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/core/design/tactile.dart';
import 'package:versescroll/features/trainer/word_bank.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/premium_providers.dart';
import 'package:versescroll/application/study_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/domain/models/study_items.dart';
import 'package:versescroll/domain/premium.dart';
import 'package:versescroll/domain/trainer/trainer.dart';
import 'package:versescroll/features/premium/paywall_screen.dart';
import 'package:versescroll/features/study/note_editor_screen.dart';
import 'package:versescroll/features/trainer/trainer_session_screen.dart';

import '../helpers.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, tab')));
  await settle(tester);
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await Scrollable.ensureVisible(tester.element(f.first), alignment: 0.5);
  await settle(tester);
  await tester.tap(f.first);
  await settle(tester);
}

/// The study tools fold away behind "More" in the reader.
Future<void> openMore(WidgetTester tester) =>
    tapVisible(tester, find.bySemanticsLabel(RegExp('^More:')));

Future<void> go(TestApp app, WidgetTester tester, String path) async {
  unawaited(app.container.read(routerProvider).push(path));
  await settle(tester, 4);
}

/// Reads a stream-backed provider after giving it time to deliver.
Future<T> current<T>(
  TestApp app,
  WidgetTester tester,
  ProviderListenable<T> p,
) async {
  final sub = app.container.listen(p, (_, _) {});
  await settle(tester);
  final v = sub.read();
  sub.close();
  return v;
}

Future<void> openReaderAt(TestApp app, WidgetTester tester, String id) async {
  await tapTab(tester, 'Gita');
  app.container.read(readerJumpProvider.notifier).request(id);
  await settle(tester, 4);
}

void main() {
  group('highlights', () {
    testWidgets('pick a colour in the reader, see it in Highlights', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openReaderAt(app, tester, 'bg-02-047');
      await openMore(tester);
      await tapVisible(tester, find.bySemanticsLabel('Highlight verse'));
      await tester.tap(find.bySemanticsLabel('Leaf'));
      await settle(tester);
      expect(
        await current(app, tester, highlightForProvider('bg-02-047')),
        HighlightColor.leaf,
      );
      expect(find.bySemanticsLabel(RegExp('Highlighted Leaf')), findsWidgets);
      app.container.read(routerProvider).go('/profile/highlights');
      await settle(tester, 4);
      expect(find.text('LEAF'), findsOneWidget);
      expect(find.text('2.47'), findsOneWidget);
    });

    testWidgets('remove highlight', (tester) async {
      final app = await pumpApp(tester);
      await app.container
          .read(studyControllerProvider)
          .setHighlight('bg-02-047', HighlightColor.sky);
      await openReaderAt(app, tester, 'bg-02-047');
      await openMore(tester);
      await tapVisible(
        tester,
        find.bySemanticsLabel(RegExp('Highlighted Sky')),
      );
      await tester.tap(find.text('Remove highlight'));
      await settle(tester);
      expect(
        await current(app, tester, highlightForProvider('bg-02-047')),
        isNull,
      );
    });
  });

  group('notes', () {
    testWidgets('write a note: it saves itself and shows in My notes', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openReaderAt(app, tester, 'bg-02-047');
      await openMore(tester);
      await tapVisible(tester, find.bySemanticsLabel('Add a note'));
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Work without craving.');
      await tester.pump(const Duration(milliseconds: 700));
      await settle(tester);
      expect(
        (await current(app, tester, noteForProvider('bg-02-047')))?.body,
        'Work without craving.',
      );
      await tester.tap(find.byTooltip('Back').first, warnIfMissed: false);
      app.container.read(routerProvider).go('/profile/notes');
      await settle(tester, 4);
      expect(find.text('Work without craving.'), findsOneWidget);
      expect(find.textContaining('of 10 free notes'), findsOneWidget);
    });

    testWidgets('the 11th note opens the paywall; existing notes still open', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final study = app.container.read(studyControllerProvider);
      await tester.runAsync(() async {
        for (var v = 1; v <= FreeLimits.maxNotes; v++) {
          await study.saveNote('bg-02-${v.toString().padLeft(3, '0')}', 'n$v');
        }
      });
      await settle(tester);
      await openReaderAt(app, tester, 'bg-03-001');
      await openMore(tester);
      await tapVisible(tester, find.bySemanticsLabel('Add a note'));
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Unlimited notes are part of Sadhak'), findsOneWidget);

      // An existing note is never locked.
      await go(app, tester, '/note/bg-02-001');
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.text('n1'), findsOneWidget);
    });

    testWidgets('premium has no note limit', (tester) async {
      final app = await pumpApp(tester);
      await app.container
          .read(entitlementProvider.notifier)
          .setPretendPremium(true);
      final study = app.container.read(studyControllerProvider);
      await tester.runAsync(() async {
        for (var v = 1; v <= FreeLimits.maxNotes; v++) {
          await study.saveNote('bg-02-${v.toString().padLeft(3, '0')}', 'n$v');
        }
      });
      await settle(tester);
      expect(
        await current(app, tester, canWriteNoteProvider('bg-03-001')),
        isTrue,
      );
    });
  });

  group('trainer', () {
    testWidgets('a free user learns 2.47 end to end; review due tomorrow', (
      tester,
    ) async {
      final app = await pumpApp(tester, now: DateTime(2026, 11, 12, 9));
      await go(app, tester, '/trainer-learn/bg-02-047');
      expect(find.byType(TrainerLearnScreen), findsOneWidget);
      expect(find.textContaining('Step 1 of 5'), findsOneWidget);
      expect(find.text('WORD MEANINGS'), findsOneWidget);
      await tapVisible(tester, find.text('I have read it'));
      expect(find.textContaining('Step 2 of 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Hidden word. Tap to show'), findsWidgets);
      await tapVisible(tester, find.text('Next step'));
      expect(find.textContaining('Step 3 of 5'), findsOneWidget);
      await tapVisible(tester, find.text('Next step'));
      expect(find.textContaining('Step 4 of 5'), findsOneWidget);
      await tapVisible(tester, find.text('Next step'));
      expect(find.textContaining('Step 5 of 5'), findsOneWidget);
      await tapVisible(tester, find.text('Show the verse'));
      await tapVisible(tester, find.text('I got it'));
      await settle(tester, 6);
      expect(find.text('2.47 is learned'), findsOneWidget);
      final s = (await current(app, tester, shlokaForProvider('bg-02-047')))!;
      expect(s.status, ShlokaStatus.learned);
      expect(s.nextReview, '2026-11-13');
    });

    testWidgets('step 2 fills its blanks from 3D word buttons', (tester) async {
      final app = await pumpApp(tester);
      await go(app, tester, '/trainer-learn/bg-02-047');
      await tapVisible(tester, find.text('I have read it'));
      expect(find.textContaining('Step 2 of 5'), findsOneWidget);
      expect(find.byKey(WordBank.wordKey(0)), findsOneWidget);
      for (var round = 0; round < 30; round++) {
        if (find.text('Every word in place').evaluate().isNotEmpty) break;
        for (var p = 0; p < 30; p++) {
          final f = find.byKey(WordBank.wordKey(p));
          if (f.evaluate().isEmpty) break;
          if (tester.widget<TactileButton>(f).onTap == null) continue;
          await tester.ensureVisible(f);
          await tester.tap(f);
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      expect(find.text('Every word in place'), findsOneWidget);
      expect(find.bySemanticsLabel('Hidden word. Tap to show'), findsNothing);
    });

    testWidgets('too many reveals repeat a step once', (tester) async {
      final app = await pumpApp(tester);
      await go(app, tester, '/trainer-learn/bg-02-047');
      await tapVisible(tester, find.text('I have read it'));
      await tapVisible(
        tester,
        find.text('I have read it').evaluate().isEmpty
            ? find.text('Next step')
            : find.text('I have read it'),
      );
      // Now on step 3 (most hidden): reveal three words.
      expect(find.textContaining('Step 3 of 5'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tapVisible(
          tester,
          find.bySemanticsLabel('Hidden word. Tap to show'),
        );
      }
      await tapVisible(tester, find.text('Next step'));
      expect(find.textContaining('Step 3 of 5'), findsOneWidget);
      await tapVisible(tester, find.text('Next step'));
      expect(find.textContaining('Step 4 of 5'), findsOneWidget);
    });

    testWidgets('a locked verse shows the Sadhak offer', (tester) async {
      final app = await pumpApp(tester);
      await go(app, tester, '/trainer-learn/bg-01-001');
      expect(find.text('Learn every shloka with Sadhak'), findsOneWidget);
    });

    testWidgets('review: pass moves the verse on', (tester) async {
      final app = await pumpApp(tester, now: DateTime(2026, 11, 20, 9));
      final study = app.container.read(studyControllerProvider);
      await tester.runAsync(() async {
        await app.container
            .read(studyRepositoryProvider)
            .saveProgress(
              ShlokaState(
                verseId: 'bg-02-047',
                step: 5,
                status: ShlokaStatus.learned,
                reviewIndex: 0,
                nextReview: '2026-11-13',
                startedAt: DateTime(2026, 11, 12),
              ),
            );
      });
      expect(study, isNotNull);
      await settle(tester);
      expect(await current(app, tester, dueReviewsProvider), hasLength(1));
      await go(app, tester, '/trainer');
      expect(find.text('1 verse is ready for review'), findsOneWidget);
      await tapVisible(tester, find.text('Review'));
      expect(find.byType(TrainerReviewScreen), findsOneWidget);
      await tapVisible(tester, find.text('Show the verse'));
      await tapVisible(tester, find.text('I got it'));
      expect(find.text('Reviews done'), findsOneWidget);
      final s = (await current(app, tester, shlokaForProvider('bg-02-047')))!;
      expect(s.reviewIndex, 1);
      expect(s.nextReview, '2026-11-23');
    });

    testWidgets('script toggle switches to Devanagari and is remembered', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await go(app, tester, '/trainer-learn/bg-02-047');
      await tester.tap(find.bySemanticsLabel('Show Devanagari'));
      await settle(tester);
      expect(app.container.read(trainerDevanagariProvider), isTrue);
      expect(app.prefs.getString('trainerScript'), 'devanagari');
    });

    testWidgets('trainer fits at text scale 2.0 on 360 px', (tester) async {
      final app = await pumpApp(
        tester,
        size: const Size(360, 740),
        textScale: 2.0,
      );
      await go(app, tester, '/trainer-learn/bg-02-047');
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('I have read it'));
      expect(tester.takeException(), isNull);
      await go(app, tester, '/trainer');
      expect(tester.takeException(), isNull);
    });
  });

  group('journal and export', () {
    testWidgets('free: journal and export lead to Sadhak', (tester) async {
      final app = await pumpApp(tester);
      await go(app, tester, '/journal');
      expect(find.text('Your journal is part of Sadhak'), findsOneWidget);
      await go(app, tester, '/notebook');
      expect(find.text('Export is part of Sadhak'), findsOneWidget);
    });

    testWidgets('premium: write a journal entry about a verse', (tester) async {
      final app = await pumpApp(tester);
      await app.container
          .read(entitlementProvider.notifier)
          .setPretendPremium(true);
      await go(app, tester, '/journal-edit?verse=bg-02-047');
      expect(find.text('Bhagavad-gītā 2.47'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Today I let go.');
      await tester.pump(const Duration(milliseconds: 700));
      await settle(tester);
      final entries = (await current(app, tester, journalProvider)).value!;
      expect(entries.single.body, 'Today I let go.');
      expect(entries.single.verseId, 'bg-02-047');
    });

    testWidgets('premium: export screen offers what exists', (tester) async {
      final app = await pumpApp(tester);
      await app.container
          .read(entitlementProvider.notifier)
          .setPretendPremium(true);
      await app.container
          .read(studyControllerProvider)
          .saveNote('bg-02-047', 'n');
      await go(app, tester, '/notebook');
      expect(find.text('Create PDF'), findsOneWidget);
      expect(find.text('None yet'), findsNWidgets(2));
    });
  });

  testWidgets('Profile shows the Study section', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.text('Shloka trainer'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('Shloka trainer'), findsOneWidget);
    expect(find.text('Learn verses by heart'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('every new screen fits at text scale 2.0 on 360 px '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      final app = await pumpApp(
        tester,
        size: const Size(360, 740),
        textScale: 2.0,
        brightness: dark ? Brightness.dark : Brightness.light,
      );
      await app.container
          .read(entitlementProvider.notifier)
          .setPretendPremium(true);
      final study = app.container.read(studyControllerProvider);
      await study.saveNote('bg-02-047', 'A note.');
      await study.setHighlight('bg-02-047', HighlightColor.lotus);
      await study.saveJournal(verseId: 'bg-02-047', body: 'An entry.');
      await settle(tester);
      for (final path in [
        '/note/bg-02-047',
        '/trainer',
        '/trainer-learn/bg-02-047',
        '/trainer-review',
        '/journal',
        '/journal-edit?verse=bg-02-047',
        '/notebook',
      ]) {
        await go(app, tester, path);
        expect(tester.takeException(), isNull, reason: path);
      }
      for (final path in ['/profile/highlights', '/profile/notes']) {
        app.container.read(routerProvider).go(path);
        await settle(tester, 4);
        expect(tester.takeException(), isNull, reason: path);
      }
    });
  }
}
