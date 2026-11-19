import 'dart:async';

import '../../domain/audio/audio.dart';

/// What the engine is doing right now.
class EngineState {
  const EngineState({
    this.playing = false,
    this.index = 0,
    this.offsetMs = 0,
    this.speed = 1,
  });

  final bool playing;

  /// Current track in the loaded list.
  final int index;

  /// Position inside the current track.
  final int offsetMs;
  final double speed;
}

/// Something the engine reports besides its state.
sealed class EngineEvent {
  const EngineEvent();
}

/// Track [index] played to its end (the engine then moves on by itself).
class TrackFinished extends EngineEvent {
  const TrackFinished(this.index);
  final int index;
}

/// The last track finished.
class QueueFinished extends EngineEvent {
  const QueueFinished();
}

/// Plays a list of tracks in order. The real one (V4-5) wraps just_audio
/// and the system media session; [PretendAudioEngine] stands in until the
/// recordings exist.
abstract class AudioEngine {
  Stream<EngineState> get states;
  Stream<EngineEvent> get events;
  EngineState get state;

  Future<void> load(List<AudioTrack> tracks, {int index = 0, int offsetMs = 0});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(int index, int offsetMs);
  Future<void> setSpeed(double speed);
  Future<void> stop();
  void dispose();
}

/// Moves a clock through the tracks using their (placeholder) durations.
/// Debug builds and tests only: it makes no sound and must never ship.
class PretendAudioEngine implements AudioEngine {
  PretendAudioEngine({this.tick = const Duration(milliseconds: 250)});

  final Duration tick;
  final _states = StreamController<EngineState>.broadcast();
  final _events = StreamController<EngineEvent>.broadcast(sync: true);
  List<AudioTrack> _tracks = const [];
  EngineState _state = const EngineState();
  Timer? _timer;

  /// Bumped on every load and seek, so a listener's seek during
  /// [TrackFinished] is never overridden by the automatic advance.
  int _gen = 0;

  @override
  Stream<EngineState> get states => _states.stream;
  @override
  Stream<EngineEvent> get events => _events.stream;
  @override
  EngineState get state => _state;

  void _emit(EngineState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  @override
  Future<void> load(
    List<AudioTrack> tracks, {
    int index = 0,
    int offsetMs = 0,
  }) async {
    _tracks = tracks;
    _gen++;
    _emit(
      EngineState(
        playing: _state.playing,
        index: index.clamp(0, tracks.isEmpty ? 0 : tracks.length - 1),
        offsetMs: offsetMs,
        speed: _state.speed,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_tracks.isEmpty) return;
    _timer ??= Timer.periodic(tick, (_) => _advance());
    _emit(_copy(playing: true));
  }

  @override
  Future<void> pause() async {
    _timer?.cancel();
    _timer = null;
    _emit(_copy(playing: false));
  }

  @override
  Future<void> seek(int index, int offsetMs) async {
    if (_tracks.isEmpty) return;
    _gen++;
    _emit(_copy(index: index.clamp(0, _tracks.length - 1), offsetMs: offsetMs));
  }

  @override
  Future<void> setSpeed(double speed) async => _emit(_copy(speed: speed));

  @override
  Future<void> stop() async {
    await pause();
    _tracks = const [];
    _emit(const EngineState());
  }

  void _advance() {
    if (_tracks.isEmpty) return;
    var offset = _state.offsetMs + (tick.inMilliseconds * _state.speed).round();
    var index = _state.index;
    if (offset >= _tracks[index].ms) {
      final gen = _gen;
      if (!_events.isClosed) _events.add(TrackFinished(index));
      // The listener may have paused or moved us in response (synchronous
      // listeners run before this line).
      if (!_state.playing || gen != _gen) return;
      if (index == _tracks.length - 1) {
        _timer?.cancel();
        _timer = null;
        _emit(_copy(playing: false, offsetMs: _tracks[index].ms));
        if (!_events.isClosed) _events.add(const QueueFinished());
        return;
      }
      index++;
      offset = 0;
    }
    _emit(_copy(index: index, offsetMs: offset));
  }

  EngineState _copy({
    bool? playing,
    int? index,
    int? offsetMs,
    double? speed,
  }) => EngineState(
    playing: playing ?? _state.playing,
    index: index ?? _state.index,
    offsetMs: offsetMs ?? _state.offsetMs,
    speed: speed ?? _state.speed,
  );

  @override
  void dispose() {
    _timer?.cancel();
    _states.close();
    _events.close();
  }
}
