import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/audio_catalog.dart';
import '../core/config/audio_config.dart';
import '../data/audio/audio_engine.dart';
import '../data/audio/just_audio_engine.dart';
import '../data/audio/manifest_source.dart';
import '../domain/audio/audio.dart';
import '../domain/shravan.dart';
import '../domain/verse_navigation.dart';
import 'core_providers.dart';
import 'premium_providers.dart';

/// The player: real streaming once the audio host is configured, the silent
/// pretend engine before that (and in tests).
final audioEngineProvider = Provider<AudioEngine>((ref) {
  final AudioEngine e = AudioConfig.baseUrl.isEmpty
      ? PretendAudioEngine()
      : JustAudioEngine(AudioConfig.baseUrl);
  ref.onDispose(e.dispose);
  return e;
});

final audioCatalogProvider = Provider<AudioCatalog>(
  (ref) => AudioCatalog(
    ref.watch(scriptureRepositoryProvider),
    manifest: AudioConfig.baseUrl.isEmpty
        ? null
        : ManifestSource(AudioConfig.baseUrl),
  ),
);

/// A chapter's length and planned download size.
final chapterAudioInfoProvider =
    FutureProvider.family<({int ms, int bytes}), int>((ref, chapter) async {
      final catalog = ref.watch(audioCatalogProvider);
      return (
        ms: await catalog.chapterMs(chapter),
        bytes: await catalog.chapterBytes(chapter),
      );
    });

enum AudioKind { chapter, summary }

@immutable
class AudioUiState {
  const AudioUiState({
    this.kind = AudioKind.chapter,
    this.queue,
    this.index = 0,
    this.offsetMs = 0,
    this.playing = false,
    this.speed = 1,
    this.mode = PlayMode.withTranslation,
    this.repeatVerse = false,
    this.sleep,
    this.sleepEndsAt,
    this.summaryChapter,
    this.summaryMs = 0,
    this.paragraphStarts = const [],
    this.summaryEnded = false,
    this.resumePlace,
    this.finished = false,
  });

  final AudioKind kind;

  /// The chapter queue (kept while a summary plays, for "Resume").
  final ChapterQueue? queue;
  final int index;
  final int offsetMs;
  final bool playing;
  final double speed;
  final PlayMode mode;
  final bool repeatVerse;
  final SleepOption? sleep;
  final DateTime? sleepEndsAt;

  final int? summaryChapter;
  final int summaryMs;
  final List<int> paragraphStarts;
  final bool summaryEnded;

  /// Where to go back to after a summary.
  final AudioPlace? resumePlace;

  /// The last chapter (18) played to its end.
  final bool finished;

  bool get active =>
      (kind == AudioKind.chapter && queue != null) ||
      (kind == AudioKind.summary && summaryChapter != null);

  int? get chapter =>
      kind == AudioKind.summary ? summaryChapter : queue?.chapter;

  AudioTrack? get track =>
      kind == AudioKind.chapter && queue != null && !queue!.isEmpty
      ? queue!.tracks[index.clamp(0, queue!.tracks.length - 1)]
      : null;

  int get positionMs => kind == AudioKind.summary
      ? offsetMs
      : (queue == null || queue!.isEmpty
            ? 0
            : queue!.startMs(index) + offsetMs);

  int get totalMs =>
      kind == AudioKind.summary ? summaryMs : queue?.totalMs ?? 0;

  double get progress =>
      totalMs == 0 ? 0 : (positionMs / totalMs).clamp(0.0, 1.0);

  /// The summary paragraph being read (-1 when the audio is a narration
  /// whose words differ from the written summary).
  int get paragraph {
    if (paragraphStarts.isEmpty) return -1;
    var p = 0;
    for (var i = 0; i < paragraphStarts.length; i++) {
      if (offsetMs >= paragraphStarts[i]) p = i;
    }
    return p;
  }

  AudioUiState copyWith({
    AudioKind? kind,
    ChapterQueue? queue,
    bool clearQueue = false,
    int? index,
    int? offsetMs,
    bool? playing,
    double? speed,
    PlayMode? mode,
    bool? repeatVerse,
    SleepOption? sleep,
    DateTime? sleepEndsAt,
    bool clearSleep = false,
    int? summaryChapter,
    bool clearSummary = false,
    int? summaryMs,
    List<int>? paragraphStarts,
    bool? summaryEnded,
    AudioPlace? resumePlace,
    bool clearResume = false,
    bool? finished,
  }) => AudioUiState(
    kind: kind ?? this.kind,
    queue: clearQueue ? null : (queue ?? this.queue),
    index: index ?? this.index,
    offsetMs: offsetMs ?? this.offsetMs,
    playing: playing ?? this.playing,
    speed: speed ?? this.speed,
    mode: mode ?? this.mode,
    repeatVerse: repeatVerse ?? this.repeatVerse,
    sleep: clearSleep ? null : (sleep ?? this.sleep),
    sleepEndsAt: clearSleep ? null : (sleepEndsAt ?? this.sleepEndsAt),
    summaryChapter: clearSummary
        ? null
        : (summaryChapter ?? this.summaryChapter),
    summaryMs: summaryMs ?? this.summaryMs,
    paragraphStarts: paragraphStarts ?? this.paragraphStarts,
    summaryEnded: summaryEnded ?? this.summaryEnded,
    resumePlace: clearResume ? null : (resumePlace ?? this.resumePlace),
    finished: finished ?? this.finished,
  );
}

final audioControllerProvider = NotifierProvider<AudioController, AudioUiState>(
  AudioController.new,
);

/// The only way screens control playback.
class AudioController extends Notifier<AudioUiState> {
  StreamSubscription<EngineState>? _states;
  StreamSubscription<EngineEvent>? _events;
  String? _savedVerse;

  AudioEngine get _engine => ref.read(audioEngineProvider);

  @override
  AudioUiState build() {
    final engine = ref.watch(audioEngineProvider);
    _states = engine.states.listen(_onState);
    _events = engine.events.listen(_onEvent);
    ref.onDispose(() {
      _states?.cancel();
      _events?.cancel();
    });
    return const AudioUiState();
  }

  /// Where the listener last stopped.
  AudioPlace? get lastPlace =>
      AudioPlace.decode(ref.read(settingsRepositoryProvider).lastAudioPlace);

  void _onState(EngineState s) {
    state = state.copyWith(
      index: s.index,
      offsetMs: s.offsetMs,
      playing: s.playing,
      speed: s.speed,
    );
    final now = ref.read(clockProvider)();
    if (s.playing &&
        sleepDue(option: state.sleep, endsAt: state.sleepEndsAt, now: now)) {
      _engine.pause();
      state = state.copyWith(clearSleep: true);
    }
    _savePlace();
  }

  void _onEvent(EngineEvent e) {
    final q = state.queue;
    switch (e) {
      case TrackFinished(:final index):
        if (state.kind != AudioKind.chapter || q == null) return;
        final verseEnds = q.verseEndIndex(index) == index;
        if (state.repeatVerse && verseEnds) {
          _engine.seek(q.verseStartIndex(index), 0);
          return;
        }
        if (sleepDue(
          option: state.sleep,
          endsAt: state.sleepEndsAt,
          now: ref.read(clockProvider)(),
          queue: q,
          finishedTrack: index,
        )) {
          _engine.pause();
          final next = index + 1 < q.tracks.length ? index + 1 : index;
          _engine.seek(next, 0);
          state = state.copyWith(clearSleep: true);
        }
      case QueueFinished():
        if (state.kind == AudioKind.summary) {
          state = state.copyWith(summaryEnded: true, playing: false);
          return;
        }
        final ch = q?.chapter ?? 0;
        if (ch > 0 && ch < chapterCount) {
          playChapter(ch + 1);
        } else {
          state = state.copyWith(finished: true, playing: false);
        }
    }
  }

  void _savePlace() {
    final t = state.track;
    final q = state.queue;
    if (state.kind != AudioKind.chapter || t == null || q == null) return;
    if (t.verseId == _savedVerse) return;
    _savedVerse = t.verseId;
    ref
        .read(settingsRepositoryProvider)
        .setLastAudioPlace(
          AudioPlace(chapter: q.chapter, verseId: t.verseId).encode(),
        );
  }

  Future<ChapterQueue> _queue(int chapter, PlayMode mode) async =>
      buildChapterQueue(
        chapter,
        await ref.read(audioCatalogProvider).chapter(chapter),
        mode: mode,
      );

  /// Whether Listen is locked (real recordings without Shravan). The silent
  /// preview stays open in debug builds.
  bool get locked =>
      !ref.read(audioCatalogProvider).isPlaceholder &&
      !canListen(
        ListenFeature.recitation,
        ref.read(shravanEntitlementProvider),
      );

  /// Plays [chapter] from [verseId] (or the start).
  Future<void> playChapter(int chapter, {String? verseId}) async {
    if (locked) return;
    final q = await _queue(chapter, state.mode);
    final index = verseId == null ? 0 : (q.indexOfVerse(verseId) ?? 0);
    state = state.copyWith(
      kind: AudioKind.chapter,
      queue: q,
      index: index,
      offsetMs: 0,
      clearSummary: true,
      summaryEnded: false,
      clearResume: true,
      finished: false,
    );
    await _engine.load(q.tracks, index: index);
    await _engine.play();
  }

  Future<void> toggle() async {
    if (state.playing) return _engine.pause();
    if (state.finished && state.queue != null) {
      return playChapter(state.queue!.chapter);
    }
    if (state.kind == AudioKind.summary && state.summaryEnded) {
      await _engine.seek(0, 0);
      state = state.copyWith(summaryEnded: false);
    }
    await _engine.play();
  }

  Future<void> nextVerse() async {
    final q = state.queue;
    if (q == null) return;
    final next = q.nextVerseIndex(state.index);
    if (next != null) {
      await _engine.seek(next, 0);
    } else if (q.chapter < chapterCount) {
      await playChapter(q.chapter + 1);
    }
  }

  Future<void> previousVerse() async {
    final q = state.queue;
    if (q == null) return;
    await _engine.seek(q.previousVerseIndex(state.index, state.offsetMs), 0);
  }

  Future<void> seekToVerse(String verseId) async {
    final i = state.queue?.indexOfVerse(verseId);
    if (i != null) await _engine.seek(i, 0);
  }

  /// Drag on the scrubber: 0..1 of the chapter (or summary).
  Future<void> seekFraction(double f) async {
    if (state.kind == AudioKind.summary) {
      return _engine.seek(0, (state.summaryMs * f).round());
    }
    final q = state.queue;
    if (q == null) return;
    final at = q.locate((q.totalMs * f).round());
    await _engine.seek(at.index, at.offsetMs);
  }

  /// 0.75 → 1 → 1.25 → 1.5 → 0.75.
  Future<void> cycleSpeed() async {
    final i = playbackSpeeds.indexOf(state.speed);
    await _engine.setSpeed(playbackSpeeds[(i + 1) % playbackSpeeds.length]);
  }

  /// Switches mode and keeps the current verse.
  Future<void> setMode(PlayMode mode) async {
    if (mode == state.mode) return;
    final q = state.queue;
    state = state.copyWith(mode: mode);
    if (q == null) return;
    final verse = state.track?.verseId;
    final nq = await _queue(q.chapter, mode);
    final index = verse == null ? 0 : (nq.indexOfVerse(verse) ?? 0);
    final wasPlaying = state.playing;
    state = state.copyWith(queue: nq, index: index, offsetMs: 0);
    await _engine.load(nq.tracks, index: index);
    if (wasPlaying) await _engine.play();
  }

  void toggleRepeat() =>
      state = state.copyWith(repeatVerse: !state.repeatVerse);

  void setSleep(SleepOption? option) {
    if (option == null) {
      state = state.copyWith(clearSleep: true);
      return;
    }
    final d = option.duration;
    state = state.copyWith(
      sleep: option,
      sleepEndsAt: d == null ? null : ref.read(clockProvider)().add(d),
    );
  }

  /// Stops and closes the mini player. The saved place is kept.
  Future<void> stop() async {
    await _engine.stop();
    state = AudioUiState(
      speed: state.speed,
      mode: state.mode,
      repeatVerse: state.repeatVerse,
    );
  }

  /// Plays the chapter's summary audio; pauses the chapter and remembers
  /// where it was. With real recordings this is the chapter narration (its
  /// words differ from the written summary, so no paragraph highlight).
  Future<void> playSummary(int chapter, List<String> paragraphs) async {
    final catalog = ref.read(audioCatalogProvider);
    // Real narrations are part of Shravan (the preview stays open in debug).
    if (!catalog.isPlaceholder &&
        !canListen(
          ListenFeature.narration,
          ref.read(shravanEntitlementProvider),
        )) {
      return;
    }
    final real = catalog.isPlaceholder
        ? null
        : await catalog.narration(chapter);
    if (!catalog.isPlaceholder && real == null) return;
    final s = catalog.summary(paragraphs);
    final ms = real?.ms ?? s.ms;
    final t = state.track;
    final resume = state.kind == AudioKind.chapter && t != null
        ? AudioPlace(chapter: state.queue!.chapter, verseId: t.verseId)
        : state.resumePlace;
    state = state.copyWith(
      kind: AudioKind.summary,
      summaryChapter: chapter,
      summaryMs: ms,
      paragraphStarts: real == null ? s.paragraphStarts : const [],
      summaryEnded: false,
      offsetMs: 0,
      index: 0,
      resumePlace: resume,
    );
    await _engine.load([
      AudioTrack(
        verseId: 'summary-$chapter',
        label: 'Summary',
        phase: AudioPhase.translation,
        ms: ms,
        file: real?.file,
      ),
    ]);
    await _engine.play();
  }

  /// Jumps [ms] forward (or back when negative) in the summary narration.
  Future<void> skipSummary(int ms) async {
    if (state.kind != AudioKind.summary) return;
    await _engine.seek(0, (state.offsetMs + ms).clamp(0, state.summaryMs));
  }

  Future<void> resumeChapter() async {
    final p = state.resumePlace;
    if (p != null) await playChapter(p.chapter, verseId: p.verseId);
  }
}

/// Pretend chapter downloads for the UI preview (debug only; real downloads
/// arrive in V4-6). Chapter → progress 0..1, where 1 is downloaded.
final audioDownloadsProvider =
    NotifierProvider<PretendDownloads, Map<int, double>>(PretendDownloads.new);

class PretendDownloads extends Notifier<Map<int, double>> {
  final _timers = <int, Timer>{};

  @override
  Map<int, double> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
    });
    return const {};
  }

  void download(int chapter) {
    if (state.containsKey(chapter)) return;
    state = {...state, chapter: 0.0};
    _timers[chapter] = Timer.periodic(const Duration(milliseconds: 120), (t) {
      final p = (state[chapter] ?? 0) + 0.04;
      if (p >= 1) {
        t.cancel();
        _timers.remove(chapter);
      }
      state = {...state, chapter: p >= 1 ? 1.0 : p};
    });
  }

  void delete(int chapter) {
    _timers.remove(chapter)?.cancel();
    state = {...state}..remove(chapter);
  }
}

// ---------------------------------------------------------------------------
// First-launch Shravan preview (owner, 2026-11-23): one verse, Sanskrit then
// translation, played once. It never touches the Listen queue or the saved
// listening place.

/// The verse the first-launch preview plays.
const previewVerseId = 'bg-01-001';

enum VersePreviewStatus { idle, loading, playing, paused, done, failed }

@immutable
class VersePreviewState {
  const VersePreviewState({
    this.status = VersePreviewStatus.idle,
    this.progress = 0,
  });

  final VersePreviewStatus status;

  /// 0 to 1 through the verse's recordings.
  final double progress;

  bool get playing => status == VersePreviewStatus.playing;
}

final versePreviewProvider =
    NotifierProvider.autoDispose<VersePreview, VersePreviewState>(
      VersePreview.new,
    );

class VersePreview extends Notifier<VersePreviewState> {
  StreamSubscription<EngineState>? _states;
  StreamSubscription<EngineEvent>? _events;
  List<int> _starts = const [];
  int _totalMs = 0;
  Future<bool>? _preparing;

  late AudioEngine _engine;

  @override
  VersePreviewState build() {
    final engine = _engine = ref.watch(audioEngineProvider);
    ref.onDispose(() {
      _states?.cancel();
      _events?.cancel();
      if (_totalMs > 0) engine.stop();
    });
    return const VersePreviewState();
  }

  /// Fetches the recording list and loads 1.1 into the player ahead of
  /// time (from the start of first launch), so Play starts at once.
  /// Safe to call more than once; a failure is retried on the next call.
  Future<bool> prepare() => _preparing ??= _load().then((ok) {
    if (!ok) _preparing = null;
    return ok;
  });

  Future<bool> _load() async {
    try {
      final chapter = chapterOfId(previewVerseId)!;
      final queue = buildChapterQueue(
        chapter,
        await ref.read(audioCatalogProvider).chapter(chapter),
        mode: PlayMode.withTranslation,
      );
      final tracks = [
        for (final t in queue.tracks)
          if (t.verseId == previewVerseId) t,
      ];
      if (tracks.isEmpty || !ref.mounted) return false;
      var at = 0;
      _starts = [for (final t in tracks) (at += t.ms) - t.ms];
      _totalMs = at;
      await _states?.cancel();
      await _events?.cancel();
      _states = _engine.states.listen(_onState);
      _events = _engine.events.listen((e) {
        if (e is QueueFinished && ref.mounted) {
          state = const VersePreviewState(
            status: VersePreviewStatus.done,
            progress: 1,
          );
        }
      });
      await _engine.load(tracks);
      return ref.mounted;
    } catch (_) {
      return false;
    }
  }

  /// Play, pause or resume; after the end it plays again.
  Future<void> toggle() async {
    switch (state.status) {
      case VersePreviewStatus.loading:
        return;
      case VersePreviewStatus.playing:
        state = VersePreviewState(
          status: VersePreviewStatus.paused,
          progress: state.progress,
        );
        return _engine.pause();
      case VersePreviewStatus.paused:
        state = VersePreviewState(
          status: VersePreviewStatus.playing,
          progress: state.progress,
        );
        return _engine.play();
      case VersePreviewStatus.done:
        state = const VersePreviewState(status: VersePreviewStatus.playing);
        await _engine.seek(0, 0);
        return _engine.play();
      case VersePreviewStatus.idle:
      case VersePreviewStatus.failed:
        state = const VersePreviewState(status: VersePreviewStatus.loading);
        if (!await prepare()) {
          if (ref.mounted) {
            state = const VersePreviewState(status: VersePreviewStatus.failed);
          }
          return;
        }
        if (!ref.mounted) return;
        state = const VersePreviewState(status: VersePreviewStatus.playing);
        return _engine.play();
    }
  }

  Future<void> pause() async {
    if (state.playing) await toggle();
  }

  void _onState(EngineState s) {
    if (!ref.mounted || _totalMs == 0) return;
    final st = state.status;
    // Loading ahead of time must not show up as "paused".
    if (st == VersePreviewStatus.done ||
        st == VersePreviewStatus.idle ||
        st == VersePreviewStatus.loading) {
      return;
    }
    final i = s.index.clamp(0, _starts.length - 1);
    final p = ((_starts[i] + s.offsetMs) / _totalMs).clamp(0.0, 1.0);
    state = VersePreviewState(
      status: s.playing
          ? VersePreviewStatus.playing
          : VersePreviewStatus.paused,
      progress: p,
    );
  }
}
