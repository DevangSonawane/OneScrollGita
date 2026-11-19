import '../../domain/audio/audio.dart';
import '../scripture/scripture_repository.dart';
import 'manifest_source.dart';

/// Which recordings exist and how long they are.
///
/// Until the owner's recordings and manifest exist (PRD_v4 stage V4-3), this
/// builds **placeholder** timings from the dataset's text length so the UI
/// can be tried. [isPlaceholder] is true and the release build hides Listen.
class AudioCatalog {
  AudioCatalog(this._scripture, {ManifestSource? manifest})
    // ignore: prefer_initializing_formals
    : _manifest = manifest;

  final ScriptureRepository _scripture;
  final ManifestSource? _manifest;
  final _cache = <int, List<VerseTiming>>{};

  /// True while no audio host is configured (estimated lengths, silent).
  bool get isPlaceholder => _manifest == null;

  Future<List<VerseTiming>> chapter(int chapter) async {
    final cached = _cache[chapter];
    if (cached != null) return cached;
    final entries = await _scripture.chapterEntries(chapter);
    final m = await _manifest?.load();
    final List<VerseTiming> out;
    if (m == null) {
      out = [
        for (final e in entries)
          VerseTiming(
            verseId: e.id,
            label: e.label,
            sanskritMs: placeholderSanskritMs(e.transliteration),
            translationMs: placeholderTranslationMs(e.translationEn),
          ),
      ];
    } else {
      // Real recordings. A verse inside another verse's recording, or one
      // without a recording yet, gets length 0 and is skipped by the queue.
      out = [
        for (final e in entries)
          VerseTiming(
            verseId: e.id,
            label: e.label,
            sanskritMs: m.sanskrit[e.id]?.ms ?? 0,
            translationMs: m.translation[e.id]?.ms ?? 0,
            sanskritFile: m.sanskrit[e.id]?.file,
            translationFile: m.translation[e.id]?.file,
          ),
      ];
    }
    // Only cache once the manifest (or the preview) has decided.
    if (m != null || _manifest == null) _cache[chapter] = out;
    return out;
  }

  /// Total length of a chapter in [mode].
  Future<int> chapterMs(
    int chapter, {
    PlayMode mode = PlayMode.withTranslation,
  }) async {
    var total = 0;
    for (final v in await this.chapter(chapter)) {
      total += v.sanskritMs;
      if (mode == PlayMode.withTranslation) total += v.translationMs;
    }
    return total;
  }

  /// Planned download size of a chapter (both recordings).
  Future<int> chapterBytes(int chapter) async {
    var bytes = 0;
    for (final v in await this.chapter(chapter)) {
      bytes += estimatedBytes(v.sanskritMs, AudioPhase.sanskrit);
      bytes += estimatedBytes(v.translationMs, AudioPhase.translation);
      // (Real sizes come from the manifest's byte counts in V4-6.)
    }
    return bytes;
  }

  /// The real narration for [chapter], if the host has one.
  Future<ManifestTrack?> narration(int chapter) async =>
      (await _manifest?.load())?.narrations[chapter];

  /// A summary's length and where each paragraph starts.
  ({int ms, List<int> paragraphStarts}) summary(List<String> paragraphs) {
    final starts = <int>[];
    var t = 0;
    for (final p in paragraphs) {
      starts.add(t);
      t += placeholderTranslationMs(p);
    }
    return (ms: t, paragraphStarts: starts);
  }
}
