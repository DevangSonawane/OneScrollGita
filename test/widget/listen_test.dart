import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/audio_providers.dart';
import 'package:versescroll/application/premium_providers.dart';
import 'package:versescroll/data/audio/manifest_source.dart';
import 'package:versescroll/data/audio/audio_engine.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/audio/audio.dart';
import 'package:versescroll/features/listen/chapter_player_screen.dart';
import 'package:versescroll/features/listen/listen_library_screen.dart';
import 'package:versescroll/features/listen/listen_widgets.dart';

import '../fakes/fake_home_widget_repository.dart';
import '../helpers.dart';

Future<void> openListen(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^Listen, tab')));
  await settle(tester);
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await Scrollable.ensureVisible(tester.element(f.first), alignment: 0.5);
  await settle(tester);
  await tester.tap(f.first);
  await settle(tester);
}

/// A chapter tile in the "All chapters" row (deck cards end in an action).
Finder tileOf(int chapter) => find.bySemanticsLabel(
  RegExp('^Chapter $chapter, (?!.*(Play chapter|Continue [0-9.]+)\$)'),
);

AudioUiState audioOf(TestApp app) =>
    app.container.read(audioControllerProvider);

/// Advances fake time in engine-sized steps.
Future<void> advance(WidgetTester tester, Duration d) async {
  final steps = d.inMilliseconds ~/ 250;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('Listen tab opens the library with all 18 chapters', (
    tester,
  ) async {
    await pumpApp(tester);
    // Third of four tabs: Home, Gita, Listen, Profile (owner, 2026-11-22).
    expect(find.bySemanticsLabel('Listen, tab 3 of 4'), findsOneWidget);
    await openListen(tester);
    expect(find.byType(ListenLibraryScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Shravan'), findsOneWidget);
    expect(
      find.textContaining('Preview: silent stand-in audio'),
      findsOneWidget,
    );
    // The chapters are tiles in one sideways row, under the deck.
    await Scrollable.ensureVisible(tester.element(tileOf(1)), alignment: 0.5);
    await settle(tester);
    await tester.scrollUntilVisible(
      tileOf(18),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
          )
          .first,
    );
    expect(tileOf(18), findsOneWidget);
  });

  testWidgets('swipe the chapter deck, then play the front card', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openListen(tester);
    final front = find.bySemanticsLabel(RegExp(r'Play chapter$'));
    expect(tester.getSemantics(front).label, startsWith('Chapter 1, '));
    await tester.fling(front, const Offset(200, 0), 1000);
    await settle(tester);
    expect(tester.getSemantics(front).label, startsWith('Chapter 2, '));
    await tester.tap(front);
    await settle(tester);
    expect(find.byType(ChapterPlayerScreen), findsOneWidget);
    expect(audioOf(app).queue!.chapter, 2);
    await app.container.read(audioControllerProvider.notifier).stop();
    await settle(tester);
  });

  testWidgets('chapter names follow the reading language', (tester) async {
    await pumpApp(
      tester,
      prefs: const {
        SettingsRepository.kFirstLaunch: true,
        SettingsRepository.kLanguage: 'hi',
      },
    );
    await openListen(tester);
    // From the imported dataset (chapters.json titleHi).
    expect(
      find.text('कुरुक्षेत्र के युद्धक्षेत्र में सेनाओं का अवलोकन'),
      findsWidgets,
    );
    expect(find.text('अध्याय १'), findsWidgets);
    expect(find.text('Chapter 1'), findsNothing);
  });

  testWidgets('Listen widgets get the last place, in the reading language', (
    tester,
  ) async {
    final widgets = FakeHomeWidgetRepository();
    final app = await pumpApp(tester, homeWidgets: widgets);
    // Nothing heard yet: chapter 1.
    expect(widgets.listen.last['chapter'], 1);
    await app.container
        .read(audioControllerProvider.notifier)
        .playChapter(2, verseId: 'bg-02-047');
    await settle(tester);
    expect(widgets.listen.last['chapter'], 2);
    expect(widgets.listen.last['label'], '2.47');
    expect(widgets.listen.last['title'], 'Contents of the Gītā Summarized');
    // No purchase data for the widgets (PRD_v11).
    expect(widgets.listen.last.keys, {'chapter', 'title', 'label', 'lang'});
    await app.container.read(audioControllerProvider.notifier).stop();
    await settle(tester);
  });

  testWidgets('play a chapter: Sanskrit, then translation, then next verse', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openListen(tester);
    await tapVisible(tester, tileOf(2));
    expect(find.byType(ChapterPlayerScreen), findsOneWidget);
    var s = audioOf(app);
    expect(s.queue!.chapter, 2);
    expect(s.track!.label, '2.1');
    expect(s.track!.phase, AudioPhase.sanskrit);
    expect(find.bySemanticsLabel('Now: Sanskrit'), findsOneWidget);
    expect(find.text('Bhagavad-gītā 2.1'), findsOneWidget);

    await advance(tester, Duration(milliseconds: s.queue!.tracks[0].ms + 300));
    s = audioOf(app);
    expect(s.track!.phase, AudioPhase.translation);
    expect(find.bySemanticsLabel('Now: Translation'), findsOneWidget);

    await tester.tap(find.byTooltip('Next verse'));
    await settle(tester);
    expect(audioOf(app).track!.label, '2.2');
    await tester.tap(find.byTooltip('Previous verse'));
    await settle(tester);
    expect(audioOf(app).track!.label, '2.1');

    await tester.tap(find.bySemanticsLabel('Pause'));
    await settle(tester);
    expect(audioOf(app).playing, isFalse);
  });

  testWidgets('mini player shows while playing and closes', (tester) async {
    final app = await pumpApp(tester);
    await app.container.read(audioControllerProvider.notifier).playChapter(3);
    await settle(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.text('Chapter 3 · 3.1'), findsOneWidget);
    await tester.tap(find.byTooltip('Close player'));
    await settle(tester);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(audioOf(app).active, isFalse);
    // The place is remembered for "Continue listening".
    expect(
      app.container.read(audioControllerProvider.notifier).lastPlace!.chapter,
      3,
    );
  });

  testWidgets('player: Devanagari and English by default; More menu', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final audio = app.container.read(audioControllerProvider.notifier);
    await audio.playChapter(2);
    unawaited(app.container.read(routerProvider).push('/player'));
    await settle(tester, 4);
    expect(app.container.read(playerTextProvider), {
      PlayerText.devanagari,
      PlayerText.translation,
    });

    // View: tick transliteration on.
    await tester.tap(find.bySemanticsLabel('More options'));
    await settle(tester);
    for (final label in [
      'View',
      'Sleep timer',
      'Repeat this verse',
      'Playlist',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('View'));
    await settle(tester);
    await tester.tap(find.text('Transliteration'));
    await settle(tester);
    expect(
      app.container.read(playerTextProvider),
      contains(PlayerText.transliteration),
    );
    Navigator.of(tester.element(find.text('Transliteration'))).pop();
    await settle(tester);

    // Repeat from the menu.
    await tester.tap(find.bySemanticsLabel('More options'));
    await settle(tester);
    await tester.tap(find.text('Repeat this verse'));
    await settle(tester);
    expect(audioOf(app).repeatVerse, isTrue);

    // Listen to: English only (owner, 2026-11-27).
    await tester.tap(find.bySemanticsLabel('More options'));
    await settle(tester);
    await tester.tap(find.text('Listen to: Sanskrit + translation'));
    await settle(tester);
    await tester.tap(find.text('English only'));
    await settle(tester);
    expect(audioOf(app).mode, PlayMode.translationOnly);
    expect(audioOf(app).track!.phase, AudioPhase.translation);
    expect(audioOf(app).track!.label, '2.1');
    expect(find.text('NOW · ENGLISH ONLY'), findsOneWidget);

    // Speed sits on the controls card.
    await tester.tap(find.bySemanticsLabel(RegExp('^Speed 1×')));
    await settle(tester);
    expect(audioOf(app).speed, isNot(1.0));
    await audio.stop();
    await settle(tester);
  });

  testWidgets('while a chapter loads the player says Loading, not Nothing', (
    tester,
  ) async {
    final slow = _SlowManifest();
    final app = await pumpApp(tester, audioManifest: slow);
    await app.container
        .read(shravanEntitlementProvider.notifier)
        .setPretendPremium(true);
    final audio = app.container.read(audioControllerProvider.notifier);
    final play = audio.playChapter(2);
    unawaited(app.container.read(routerProvider).push('/player'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ChapterPlayerScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(find.text('Nothing is playing'), findsNothing);
    slow.release();
    await play;
    await settle(tester, 4);
    expect(find.bySemanticsLabel('Loading'), findsNothing);
    expect(audioOf(app).queue!.chapter, 2);
    await audio.stop();
    await settle(tester);
  });

  testWidgets('Sanskrit only and repeat this verse', (tester) async {
    final app = await pumpApp(tester);
    final audio = app.container.read(audioControllerProvider.notifier);
    await audio.playChapter(2);
    await settle(tester);
    final both = audioOf(app).queue!.tracks.length;
    await audio.setMode(PlayMode.sanskritOnly);
    await settle(tester);
    expect(audioOf(app).queue!.tracks.length, both ~/ 2);
    expect(audioOf(app).track!.label, '2.1');

    audio.toggleRepeat();
    final first = audioOf(app).queue!.tracks.first.ms;
    await advance(tester, Duration(milliseconds: first + 500));
    // Repeat keeps us on 2.1.
    expect(audioOf(app).track!.label, '2.1');
    await audio.stop();
    await settle(tester);
  });

  testWidgets('sleep timer: end of this verse pauses', (tester) async {
    final app = await pumpApp(tester);
    final audio = app.container.read(audioControllerProvider.notifier);
    await audio.playChapter(2);
    await settle(tester);
    audio.setSleep(SleepOption.endOfVerse);
    final q = audioOf(app).queue!;
    await advance(
      tester,
      Duration(milliseconds: q.tracks[0].ms + q.tracks[1].ms + 750),
    );
    final s = audioOf(app);
    expect(s.playing, isFalse);
    expect(s.sleep, isNull);
    expect(s.track!.label, '2.2'); // ready at the next verse
  });

  testWidgets('the end of a chapter flows into the next chapter', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final audio = app.container.read(audioControllerProvider.notifier);
    await audio.playChapter(1);
    await settle(tester);
    final q = audioOf(app).queue!;
    final last = q.tracks.length - 1;
    await app.container
        .read(audioEngineProvider)
        .seek(last, q.tracks[last].ms - 300);
    await advance(tester, const Duration(seconds: 1));
    await settle(tester);
    expect(audioOf(app).queue!.chapter, 2);
    expect(audioOf(app).playing, isTrue);
    await audio.stop();
    await settle(tester);
  });

  testWidgets('summary: plays from the summary screen, then offers to resume', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final audio = app.container.read(audioControllerProvider.notifier);
    await audio.playChapter(2, verseId: 'bg-02-047');
    await settle(tester);
    unawaited(app.container.read(routerProvider).push('/gita/summary/2'));
    await settle(tester, 4);
    await tapVisible(tester, find.text('Listen to this summary'));
    var s = audioOf(app);
    expect(s.kind, AudioKind.summary);
    expect(s.resumePlace!.verseId, 'bg-02-047');
    expect(s.paragraph, 0);

    // Jump near the end, let it finish.
    await app.container.read(audioEngineProvider).seek(0, s.summaryMs - 300);
    await advance(tester, const Duration(seconds: 1));
    await settle(tester);
    expect(audioOf(app).summaryEnded, isTrue);
    expect(find.text('Resume Chapter 2'), findsOneWidget);
    await tester.tap(find.text('Resume Chapter 2'));
    await settle(tester);
    s = audioOf(app);
    expect(s.kind, AudioKind.chapter);
    expect(s.track!.verseId, 'bg-02-047');
    await audio.stop();
    await settle(tester);
  });

  for (final dark in [false, true]) {
    testWidgets('library and player fit at text scale 2.0 on 360 px '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      final app = await pumpApp(
        tester,
        size: const Size(360, 740),
        textScale: 2.0,
        brightness: dark ? Brightness.dark : Brightness.light,
      );
      await openListen(tester);
      expect(tester.takeException(), isNull);
      await app.container.read(audioControllerProvider.notifier).playChapter(2);
      unawaited(app.container.read(routerProvider).push('/player'));
      await settle(tester, 4);
      expect(tester.takeException(), isNull);
      // The pretend engine's timer must stop before the test ends.
      await app.container.read(audioControllerProvider.notifier).stop();
      await settle(tester);
    });
  }

  testWidgets('reduced motion: nothing keeps animating when paused', (
    tester,
  ) async {
    final app = await pumpApp(tester, reducedMotion: true);
    await app.container.read(audioControllerProvider.notifier).playChapter(2);
    unawaited(app.container.read(routerProvider).push('/player'));
    await settle(tester, 4);
    await app.container.read(audioControllerProvider.notifier).toggle();
    await settle(tester);
    expect(audioOf(app).playing, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
  });

  test('pretend engine: track finished, then queue finished', () async {
    final e = PretendAudioEngine(tick: const Duration(milliseconds: 1));
    final events = <EngineEvent>[];
    e.events.listen(events.add);
    await e.load(const [
      AudioTrack(verseId: 'a', label: 'a', phase: AudioPhase.sanskrit, ms: 3),
      AudioTrack(
        verseId: 'a',
        label: 'a',
        phase: AudioPhase.translation,
        ms: 3,
      ),
    ]);
    await e.play();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(events.whereType<TrackFinished>().map((x) => x.index), [0, 1]);
    expect(events.last, isA<QueueFinished>());
    expect(e.state.playing, isFalse);
    e.dispose();
  });

  testWidgets('without Shravan, real recordings open the paywall', (
    tester,
  ) async {
    final app = await pumpApp(tester, audioManifest: _FakeManifest());
    await openListen(tester);
    expect(find.text('Unlock Shravan'), findsOneWidget);
    // No download buttons on the Listen page (owner, 2026-11-27).
    expect(find.bySemanticsLabel(RegExp('^Download')), findsNothing);
    await tapVisible(tester, tileOf(2));
    expect(find.text('The audio library is part of Shravan'), findsOneWidget);
    expect(audioOf(app).active, isFalse);

    // With Shravan the same tap plays.
    await app.container
        .read(shravanEntitlementProvider.notifier)
        .setPretendPremium(true);
    app.container.read(routerProvider).pop();
    await settle(tester, 4);
    expect(find.text('Unlock Shravan'), findsNothing);
    await tapVisible(tester, tileOf(2));
    expect(audioOf(app).queue!.chapter, 2);
    await app.container.read(audioControllerProvider.notifier).stop();
    await settle(tester);
  });
}

/// A "real" manifest with one recording per verse of chapter 2.
class _FakeManifest extends ManifestSource {
  _FakeManifest() : super('https://example.invalid');

  @override
  Future<AudioManifest?> load() async => AudioManifest(
    sanskrit: {
      for (var v = 1; v <= 72; v++)
        'bg-02-${v.toString().padLeft(3, '0')}': ManifestTrack(
          file: 'ch02/$v.m4a',
          ms: 5000,
          bytes: 1,
          sha256: 'x',
          entries: const [],
        ),
    },
    translation: const {},
  );
}

/// A manifest that arrives only when [release] is called (a slow network).
class _SlowManifest extends ManifestSource {
  _SlowManifest() : super('https://example.invalid');

  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<AudioManifest?> load() async {
    await _gate.future;
    return _FakeManifest().load();
  }
}
