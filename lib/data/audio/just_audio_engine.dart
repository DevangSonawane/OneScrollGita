import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../domain/audio/audio.dart';
import 'audio_engine.dart';

/// Real playback: streams from the audio host through just_audio, with the
/// system media session (lock screen, notification, Dynamic Island) from
/// just_audio_background. `JustAudioBackground.init` runs in main().
class JustAudioEngine implements AudioEngine {
  JustAudioEngine(this.baseUrl) {
    _subs = [
      _p.positionStream.listen((_) => _emit()),
      _p.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && !_completed) {
          _completed = true;
          _events.add(TrackFinished(_lastIndex ?? 0));
          _events.add(const QueueFinished());
        }
        _emit();
      }),
      _p.currentIndexStream.listen((i) {
        final last = _lastIndex;
        // A natural move to the next track means the previous one finished.
        if (i != null && last != null && i == last + 1 && !_seeking) {
          _events.add(TrackFinished(last));
        }
        _lastIndex = i;
      }),
    ];
  }

  final String baseUrl;
  final _p = AudioPlayer();
  final _states = StreamController<EngineState>.broadcast();
  final _events = StreamController<EngineEvent>.broadcast(sync: true);
  late final List<StreamSubscription<Object?>> _subs;
  int? _lastIndex;
  bool _seeking = false;
  bool _completed = false;
  EngineState _state = const EngineState();

  @override
  Stream<EngineState> get states => _states.stream;
  @override
  Stream<EngineEvent> get events => _events.stream;
  @override
  EngineState get state => _state;

  void _emit() {
    _state = EngineState(
      playing: _p.playing && _p.processingState != ProcessingState.completed,
      index: _p.currentIndex ?? 0,
      offsetMs: _p.position.inMilliseconds,
      speed: _p.speed,
    );
    if (!_states.isClosed) _states.add(_state);
  }

  @override
  Future<void> load(
    List<AudioTrack> tracks, {
    int index = 0,
    int offsetMs = 0,
  }) async {
    _completed = false;
    _seeking = true;
    _lastIndex = index;
    await _p.setAudioSources(
      [
        for (final t in tracks)
          AudioSource.uri(
            Uri.parse('$baseUrl/${t.file}'),
            tag: MediaItem(
              id: '${t.verseId}.${t.phase.code}',
              title: t.label == 'Summary'
                  ? 'Chapter summary'
                  : 'Bhagavad-gītā ${t.label}',
              artist: t.phase.label,
              album: 'Shravan',
            ),
          ),
      ],
      initialIndex: index,
      initialPosition: Duration(milliseconds: offsetMs),
    );
    _seeking = false;
  }

  @override
  Future<void> play() async {
    _completed = false;
    unawaited(_p.play());
  }

  @override
  Future<void> pause() => _p.pause();

  @override
  Future<void> seek(int index, int offsetMs) async {
    _seeking = true;
    _completed = false;
    _lastIndex = index;
    await _p.seek(Duration(milliseconds: offsetMs), index: index);
    _seeking = false;
  }

  @override
  Future<void> setSpeed(double speed) => _p.setSpeed(speed);

  @override
  Future<void> stop() => _p.stop();

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _p.dispose();
    _states.close();
    _events.close();
  }
}
