import 'package:flutter/foundation.dart';

/// Shravan audio settings (PRD_v4 section 6).
abstract final class AudioConfig {
  /// The Cloudflare Worker that serves the recordings from the R2 bucket
  /// `one-scroll-gita` (tool/audio/worker.js). Empty means the silent preview.
  static const baseUrl =
      'https://one-scroll-gita-audio.officialaniketjha.workers.dev';

  /// The Listen pill and audio screens. Debug builds only until real
  /// playback exists (V4-5): the pretend engine and placeholder timings must
  /// never ship.
  static bool get enabled => kDebugMode;

  /// The summary screen's player (chapter narrations once uploaded).
  static bool get summaryAudio => enabled;
}
