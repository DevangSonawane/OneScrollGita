import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/audio/audio.dart';

List<VerseTiming> verses(int n) => [
  for (var i = 1; i <= n; i++)
    VerseTiming(
      verseId: 'bg-02-${i.toString().padLeft(3, '0')}',
      label: '2.$i',
      sanskritMs: 10000,
      translationMs: 5000,
    ),
];

void main() {
  group('queue', () {
    test('recitation then translation, verse by verse', () {
      final q = buildChapterQueue(2, verses(3));
      expect(q.tracks.map((t) => '${t.label}${t.phase.code}'), [
        '2.1sa',
        '2.1en',
        '2.2sa',
        '2.2en',
        '2.3sa',
        '2.3en',
      ]);
      expect(q.totalMs, 45000);
    });

    test('Sanskrit only drops translations', () {
      final q = buildChapterQueue(2, verses(3), mode: PlayMode.sanskritOnly);
      expect(q.tracks, hasLength(3));
      expect(q.tracks.every((t) => t.phase == AudioPhase.sanskrit), isTrue);
    });

    test('English only keeps just the translations', () {
      final q = buildChapterQueue(2, verses(3), mode: PlayMode.translationOnly);
      expect(q.tracks, hasLength(3));
      expect(q.tracks.every((t) => t.phase == AudioPhase.translation), isTrue);
      expect(q.tracks.map((t) => t.verseId).toSet(), hasLength(3));
    });

    test('locate maps chapter time to track and offset', () {
      final q = buildChapterQueue(2, verses(3));
      expect(q.locate(0), (index: 0, offsetMs: 0));
      expect(q.locate(12000), (index: 1, offsetMs: 2000));
      expect(q.locate(15000), (index: 2, offsetMs: 0));
      expect(q.locate(999999).index, 5);
      expect(q.locate(-5).index, 0);
    });

    test('next and previous verse', () {
      final q = buildChapterQueue(2, verses(3));
      expect(q.nextVerseIndex(0), 2);
      expect(q.nextVerseIndex(1), 2);
      expect(q.nextVerseIndex(4), isNull);
      // 4 s into verse 2 (index 2): restart verse 2.
      expect(q.previousVerseIndex(2, 4000), 2);
      // 1 s into verse 2: go to verse 1.
      expect(q.previousVerseIndex(2, 1000), 0);
      // In verse 2's translation: restart verse 2.
      expect(q.previousVerseIndex(3, 0), 2);
      expect(q.previousVerseIndex(0, 0), 0);
    });

    test('verse marks for the scrubber', () {
      final q = buildChapterQueue(2, verses(3));
      final m = q.verseMarks;
      expect(m.map((x) => x.label), ['2.1', '2.2', '2.3']);
      expect(m[1].at, closeTo(15000 / 45000, 1e-9));
      expect(q.indexOfVerse('bg-02-002'), 2);
      expect(q.indexOfVerse('bg-03-001'), isNull);
    });
  });

  group('sleep timer', () {
    final q = buildChapterQueue(2, verses(2));
    final now = DateTime(2026, 11, 19, 22);

    test('end of verse stops after the verse\'s last track', () {
      expect(
        sleepDue(
          option: SleepOption.endOfVerse,
          endsAt: null,
          now: now,
          queue: q,
          finishedTrack: 0,
        ),
        isFalse,
      );
      expect(
        sleepDue(
          option: SleepOption.endOfVerse,
          endsAt: null,
          now: now,
          queue: q,
          finishedTrack: 1,
        ),
        isTrue,
      );
    });

    test('end of chapter stops after the last track', () {
      expect(
        sleepDue(
          option: SleepOption.endOfChapter,
          endsAt: null,
          now: now,
          queue: q,
          finishedTrack: 1,
        ),
        isFalse,
      );
      expect(
        sleepDue(
          option: SleepOption.endOfChapter,
          endsAt: null,
          now: now,
          queue: q,
          finishedTrack: 3,
        ),
        isTrue,
      );
    });

    test('minutes stop when the time is reached', () {
      final ends = now.add(SleepOption.min15.duration!);
      expect(
        sleepDue(option: SleepOption.min15, endsAt: ends, now: now),
        isFalse,
      );
      expect(
        sleepDue(option: SleepOption.min15, endsAt: ends, now: ends),
        isTrue,
      );
      expect(sleepDue(option: null, endsAt: null, now: now), isFalse);
    });
  });

  group('formatting and places', () {
    test('durations, sizes, Devanagari numbers', () {
      expect(formatDuration(65000), '1:05');
      expect(formatDuration(3723000), '1:02:03');
      expect(formatBytes(18400000), '18 MB');
      expect(formatBytes(850000), '850 KB');
      expect(devanagariNumber(18), '१८');
      expect(devanagariNumber(2), '२');
      expect(estimatedBytes(10000, AudioPhase.sanskrit), 120000);
    });

    test('placeholder timings are bounded', () {
      expect(placeholderSanskritMs(['om']), 4000);
      expect(placeholderTranslationMs('a b c'), greaterThanOrEqualTo(3000));
    });

    test('place round trip and rejects junk', () {
      const p = AudioPlace(chapter: 2, verseId: 'bg-02-047');
      final back = AudioPlace.decode(p.encode())!;
      expect(back.chapter, 2);
      expect(back.verseId, 'bg-02-047');
      expect(AudioPlace.decode('99|x'), isNull);
      expect(AudioPlace.decode(null), isNull);
    });
  });

  group('manifest', () {
    test('parses tracks and finds verses inside another recording', () {
      final m = AudioManifest.fromJson({
        'version': 1,
        'sa': {
          'bg-01-026': {
            'file': 'ch01/bg-01-026.sa.m4a',
            'ms': 90000,
            'bytes': 1,
            'sha256': 'x',
            'entries': ['bg-01-026', 'bg-01-027'],
          },
        },
        'en': <String, dynamic>{},
      });
      expect(m.sanskrit['bg-01-026']!.ms, 90000);
      expect(m.coveredElsewhere, {'bg-01-027'});
    });

    test('verses with no recording are skipped by the queue', () {
      final q = buildChapterQueue(1, const [
        VerseTiming(
          verseId: 'a',
          label: '1.26',
          sanskritMs: 9000,
          translationMs: 0,
        ),
        VerseTiming(
          verseId: 'b',
          label: '1.27',
          sanskritMs: 0,
          translationMs: 0,
        ),
        VerseTiming(
          verseId: 'c',
          label: '1.28',
          sanskritMs: 5000,
          translationMs: 4000,
        ),
      ]);
      expect(q.tracks.map((t) => '${t.label}${t.phase.code}'), [
        '1.26sa',
        '1.28sa',
        '1.28en',
      ]);
    });
  });
}
