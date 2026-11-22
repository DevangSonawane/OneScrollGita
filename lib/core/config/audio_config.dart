import 'build_flags.dart';

/// Shravan audio settings (PRD_v4 section 6).
abstract final class AudioConfig {
  /// The Cloudflare Worker that serves the recordings from the R2 bucket
  /// `one-scroll-gita` (tool/audio/worker.js). Empty means the silent preview.
  static const baseUrl =
      'https://one-scroll-gita-audio.officialaniketjha.workers.dev';

  /// The Listen pill and audio screens. On whenever the real host is set
  /// (real recordings and the just_audio engine, V4-5). With no host the app
  /// would fall back to the pretend engine and placeholder timings, which
  /// must never ship, so then only debug and owner preview builds show it.
  static bool get enabled => baseUrl.isNotEmpty || previewBuild;

  /// Chapter downloads are still pretend until V4-6, so the download button
  /// shows only in debug and owner preview builds.
  static bool get downloads => previewBuild;

  /// The summary screen's player (chapter narrations once uploaded).
  static bool get summaryAudio => enabled;
}
