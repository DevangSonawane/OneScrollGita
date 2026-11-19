/// The Shravan audio library (PRD_v4). Pure Dart: queues, positions, sleep
/// timer rules and placeholder timings. Never touches scripture text; it only
/// orders recordings by verse id.
library;

enum AudioPhase {
  sanskrit('sa', 'Sanskrit'),
  translation('en', 'Translation');

  const AudioPhase(this.code, this.label);
  final String code;
  final String label;
}

/// One recording: a verse's recitation or its translation.
class AudioTrack {
  const AudioTrack({
    required this.verseId,
    required this.label,
    required this.phase,
    required this.ms,
    this.file,
  });

  final String verseId;

  /// The verse label from the dataset ("2.47").
  final String label;
  final AudioPhase phase;
  final int ms;

  /// Path on the audio host (null for placeholder tracks).
  final String? file;
}

enum PlayMode {
  withTranslation('Sanskrit + translation'),
  sanskritOnly('Sanskrit only');

  const PlayMode(this.label);
  final String label;
}

/// Durations of one verse's two recordings.
class VerseTiming {
  const VerseTiming({
    required this.verseId,
    required this.label,
    required this.sanskritMs,
    required this.translationMs,
    this.sanskritFile,
    this.translationFile,
  });

  final String verseId;
  final String label;
  final int sanskritMs;
  final int translationMs;
  final String? sanskritFile;
  final String? translationFile;
}

/// A chapter in play order: recitation, translation, next verse…
class ChapterQueue {
  ChapterQueue({
    required this.chapter,
    required this.tracks,
    this.mode = PlayMode.withTranslation,
  }) : _starts = _prefix(tracks);

  final int chapter;
  final List<AudioTrack> tracks;
  final PlayMode mode;
  final List<int> _starts;

  static List<int> _prefix(List<AudioTrack> t) {
    final out = <int>[];
    var sum = 0;
    for (final x in t) {
      out.add(sum);
      sum += x.ms;
    }
    return out;
  }

  bool get isEmpty => tracks.isEmpty;
  int get totalMs => tracks.isEmpty ? 0 : _starts.last + tracks.last.ms;

  /// Where track [index] starts in the chapter.
  int startMs(int index) => _starts[index];

  /// The track and offset at [ms] into the chapter (clamped).
  ({int index, int offsetMs}) locate(int ms) {
    if (tracks.isEmpty) return (index: 0, offsetMs: 0);
    final t = ms.clamp(0, totalMs - 1);
    var lo = 0, hi = tracks.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_starts[mid] <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return (index: lo, offsetMs: t - _starts[lo]);
  }

  /// First track of the verse that track [index] belongs to.
  int verseStartIndex(int index) {
    var i = index;
    while (i > 0 && tracks[i - 1].verseId == tracks[index].verseId) {
      i--;
    }
    return i;
  }

  /// Last track of the verse that track [index] belongs to.
  int verseEndIndex(int index) {
    var i = index;
    while (i < tracks.length - 1 &&
        tracks[i + 1].verseId == tracks[index].verseId) {
      i++;
    }
    return i;
  }

  /// First track of the next verse, or null at the last verse.
  int? nextVerseIndex(int index) {
    final end = verseEndIndex(index);
    return end + 1 < tracks.length ? end + 1 : null;
  }

  /// "Previous": back to the start of this verse if more than [restartAfter]
  /// in, else the start of the previous verse.
  int previousVerseIndex(int index, int offsetMs, {int restartAfterMs = 3000}) {
    final start = verseStartIndex(index);
    final intoVerse = startMs(index) + offsetMs - startMs(start);
    if (intoVerse > restartAfterMs || start == 0) return start;
    return verseStartIndex(start - 1);
  }

  /// The first track of [verseId], or null if it is not in this chapter.
  int? indexOfVerse(String verseId) {
    final i = tracks.indexWhere((t) => t.verseId == verseId);
    return i < 0 ? null : i;
  }

  /// Distinct verses, in order, with where each starts (0..1 of the chapter).
  List<({String verseId, String label, double at})> get verseMarks {
    final out = <({String verseId, String label, double at})>[];
    final total = totalMs;
    for (var i = 0; i < tracks.length; i++) {
      if (i == 0 || tracks[i - 1].verseId != tracks[i].verseId) {
        out.add((
          verseId: tracks[i].verseId,
          label: tracks[i].label,
          at: total == 0 ? 0 : startMs(i) / total,
        ));
      }
    }
    return out;
  }
}

/// Tracks with no recording (length 0) are left out: a verse whose
/// recitation is part of the previous verse's block, or a translation not
/// yet recorded.
ChapterQueue buildChapterQueue(
  int chapter,
  List<VerseTiming> verses, {
  PlayMode mode = PlayMode.withTranslation,
}) => ChapterQueue(
  chapter: chapter,
  mode: mode,
  tracks: [
    for (final v in verses) ...[
      if (v.sanskritMs > 0)
        AudioTrack(
          verseId: v.verseId,
          label: v.label,
          phase: AudioPhase.sanskrit,
          ms: v.sanskritMs,
          file: v.sanskritFile,
        ),
      if (mode == PlayMode.withTranslation && v.translationMs > 0)
        AudioTrack(
          verseId: v.verseId,
          label: v.label,
          phase: AudioPhase.translation,
          ms: v.translationMs,
          file: v.translationFile,
        ),
    ],
  ],
);

// ---------------------------------------------------------------------------
// Sleep timer.

enum SleepOption {
  endOfVerse('End of this verse'),
  endOfChapter('End of this chapter'),
  min15('15 minutes'),
  min30('30 minutes'),
  min60('60 minutes');

  const SleepOption(this.label);
  final String label;

  Duration? get duration => switch (this) {
    SleepOption.min15 => const Duration(minutes: 15),
    SleepOption.min30 => const Duration(minutes: 30),
    SleepOption.min60 => const Duration(minutes: 60),
    _ => null,
  };
}

/// Whether playback should stop now.
///
/// [finishedTrack] is the track that just ended (null when called on a
/// clock tick), [queue] its chapter.
bool sleepDue({
  required SleepOption? option,
  required DateTime? endsAt,
  required DateTime now,
  ChapterQueue? queue,
  int? finishedTrack,
}) {
  switch (option) {
    case null:
      return false;
    case SleepOption.endOfVerse:
      return queue != null &&
          finishedTrack != null &&
          queue.verseEndIndex(finishedTrack) == finishedTrack;
    case SleepOption.endOfChapter:
      return queue != null &&
          finishedTrack != null &&
          finishedTrack == queue.tracks.length - 1;
    case SleepOption.min15 || SleepOption.min30 || SleepOption.min60:
      return endsAt != null && !now.isBefore(endsAt);
  }
}

const playbackSpeeds = [0.75, 1.0, 1.25, 1.5];

// ---------------------------------------------------------------------------
// Placeholder timings (UI preview only; isPlaceholder).

/// A believable length for a recitation, from the number of syllable-ish
/// letters in the transliteration. Never shown as real data.
int placeholderSanskritMs(List<String> transliteration) {
  final letters = transliteration
      .join(' ')
      .replaceAll(RegExp(r'[^a-zāīūṛṝḷḹṅñṭḍṇśṣṁḥ]', caseSensitive: false), '')
      .length;
  return (2500 + letters * 110).clamp(4000, 60000);
}

/// A believable length for a narrated translation (about 150 words a
/// minute).
int placeholderTranslationMs(String translation) {
  final words = translation
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;
  return (1500 + words * 400).clamp(3000, 120000);
}

/// Approximate download size at the planned bitrates (96/64 kbps).
int estimatedBytes(int ms, AudioPhase phase) =>
    (ms * (phase == AudioPhase.sanskrit ? 96 : 64) / 8).round();

/// "1:05", "12:40", "1:02:03".
String formatDuration(int ms) {
  final s = (ms / 1000).floor();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final ss = sec.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// "18 MB", "850 KB".
String formatBytes(int bytes) {
  if (bytes >= 1000000) return '${(bytes / 1000000).round()} MB';
  return '${(bytes / 1000).round()} KB';
}

const _devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

/// 18 → "१८".
String devanagariNumber(int n) =>
    n.toString().split('').map((d) => _devanagariDigits[int.parse(d)]).join();

/// Where the listener stopped (saved between sessions).
class AudioPlace {
  const AudioPlace({required this.chapter, required this.verseId});

  final int chapter;
  final String verseId;

  String encode() => '$chapter|$verseId';

  static AudioPlace? decode(String? s) {
    if (s == null) return null;
    final parts = s.split('|');
    final ch = parts.length == 2 ? int.tryParse(parts[0]) : null;
    if (ch == null || ch < 1 || ch > 18) return null;
    return AudioPlace(chapter: ch, verseId: parts[1]);
  }
}

/// One recording on the audio host (`manifest.json`, PRD_v4 section 5).
class ManifestTrack {
  const ManifestTrack({
    required this.file,
    required this.ms,
    required this.bytes,
    required this.sha256,
    required this.entries,
  });

  final String file;
  final int ms;
  final int bytes;
  final String sha256;

  /// Verse ids this recording covers (more than one where the recording's
  /// edition splits lines differently).
  final List<String> entries;

  factory ManifestTrack.fromJson(Map<String, dynamic> j) => ManifestTrack(
    file: j['file'] as String,
    ms: j['ms'] as int,
    bytes: j['bytes'] as int,
    sha256: j['sha256'] as String,
    entries: List<String>.from(j['entries'] as List? ?? const []),
  );
}

class AudioManifest {
  const AudioManifest({
    required this.sanskrit,
    required this.translation,
    this.narrations = const {},
  });

  /// Keyed by the first verse id each recording covers.
  final Map<String, ManifestTrack> sanskrit;
  final Map<String, ManifestTrack> translation;

  /// Chapter narrations for the summary screen; 0 is the introduction.
  final Map<int, ManifestTrack> narrations;

  factory AudioManifest.fromJson(Map<String, dynamic> j) {
    Map<String, ManifestTrack> read(Object? m) => {
      for (final e in ((m as Map?) ?? const {}).cast<String, dynamic>().entries)
        e.key: ManifestTrack.fromJson(e.value as Map<String, dynamic>),
    };
    return AudioManifest(
      sanskrit: read(j['sa']),
      translation: read(j['en']),
      narrations: {
        for (final e in read(j['summaries']).entries)
          ?int.tryParse(e.key): e.value,
      },
    );
  }

  /// Verse ids whose recitation is inside another verse's recording.
  Set<String> get coveredElsewhere => {
    for (final e in sanskrit.entries)
      for (final id in e.value.entries)
        if (id != e.key) id,
  };
}
