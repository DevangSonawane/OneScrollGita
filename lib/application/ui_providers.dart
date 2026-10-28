import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the reader should show. A [JumpRequest] is issued by
/// `go('/gita?verse=<id>')` and consumed by the reader.
class JumpRequest {
  const JumpRequest(this.verseId, this.serial);
  final String verseId;
  final int serial;
}

final readerJumpProvider = NotifierProvider<ReaderJumpNotifier, JumpRequest?>(
  ReaderJumpNotifier.new,
);

class ReaderJumpNotifier extends Notifier<JumpRequest?> {
  @override
  JumpRequest? build() => null;

  void request(String verseId) =>
      state = JumpRequest(verseId, (state?.serial ?? 0) + 1);
}

/// Whether the floating nav pill is shown (hidden while scrolling down).
final navBarVisibleProvider = NotifierProvider<NavBarVisibility, bool>(
  NavBarVisibility.new,
);

class NavBarVisibility extends Notifier<bool> {
  @override
  bool build() => true;

  void show() {
    if (!state) state = true;
  }

  void hide() {
    if (state) state = false;
  }
}

/// Re-tapping the active tab: (tab index, serial).
final tabReselectProvider =
    NotifierProvider<TabReselectNotifier, ({int tab, int serial})>(
      TabReselectNotifier.new,
    );

class TabReselectNotifier extends Notifier<({int tab, int serial})> {
  @override
  ({int tab, int serial}) build() => (tab: -1, serial: 0);

  void reselect(int tab) => state = (tab: tab, serial: state.serial + 1);
}

/// In-session scroll offsets of purport pages, by verse id.
final purportOffsetsProvider = Provider<Map<String, double>>((_) => {});

enum GlassMode { full, frosted, solid }

/// Forces a glass mode (tests, debugging). Null means automatic.
final glassModeOverrideProvider = Provider<GlassMode?>((_) => null);

/// Trips when frame time exceeds budget for 30 consecutive frames while
/// full glass is on; glass then uses the frosted fallback for the session.
final glassFrameGuardProvider = NotifierProvider<GlassFrameGuard, bool>(
  GlassFrameGuard.new,
);

class GlassFrameGuard extends Notifier<bool> {
  static const _budget = Duration(microseconds: 16667);
  static const _limit = 30;
  int _slow = 0;

  @override
  bool build() {
    // Debug builds are always slow; only guard profile and release.
    if (kReleaseMode || kProfileMode) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      ref.onDispose(
        () => SchedulerBinding.instance.removeTimingsCallback(_onTimings),
      );
    }
    return false;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (state) return;
    for (final t in timings) {
      final slow = t.buildDuration > _budget || t.rasterDuration > _budget;
      _slow = slow ? _slow + 1 : 0;
      if (_slow >= _limit) {
        state = true;
        SchedulerBinding.instance.removeTimingsCallback(_onTimings);
        return;
      }
    }
  }
}
