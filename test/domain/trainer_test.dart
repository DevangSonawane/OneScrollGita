import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/trainer/trainer.dart';

void main() {
  group('parts', () {
    test('short verses are learned whole', () {
      expect(trainerParts(2), [
        [0, 1],
      ]);
      expect(trainerParts(4), [
        [0, 1, 2, 3],
      ]);
      expect(trainerParts(0), isEmpty);
    });

    test('long verses in pairs; an odd last line joins the last pair', () {
      expect(trainerParts(6), [
        [0, 1],
        [2, 3],
        [4, 5],
      ]);
      expect(trainerParts(5), [
        [0, 1],
        [2, 3, 4],
      ]);
    });
  });

  group('hiding', () {
    final words = wordsOf('karmaṇy evādhikāras te mā phaleṣu kadācana ।');

    test('the same verse always hides the same words', () {
      List<bool> m() => hiddenMask(
        verseId: 'bg-02-047',
        step: TrainerStep.someHidden,
        part: 0,
        words: words,
      );
      expect(m(), m());
      final other = hiddenMask(
        verseId: 'bg-02-048',
        step: TrainerStep.someHidden,
        part: 0,
        words: words,
      );
      // Different verse, (almost certainly) a different pattern; at least the
      // count is the same.
      expect(other.where((x) => x).length, m().where((x) => x).length);
    });

    test('about 30% and 70%; never the danda', () {
      final some = hiddenMask(
        verseId: 'v',
        step: TrainerStep.someHidden,
        part: 0,
        words: words,
      );
      final most = hiddenMask(
        verseId: 'v',
        step: TrainerStep.mostHidden,
        part: 0,
        words: words,
      );
      // 6 hideable words: 30% -> 2, 70% -> 4.
      expect(some.where((x) => x).length, 2);
      expect(most.where((x) => x).length, 4);
      expect(some.last, isFalse);
      expect(most.last, isFalse);
    });

    test('recite hides every word but punctuation; understand hides none', () {
      final recite = hiddenMask(
        verseId: 'v',
        step: TrainerStep.recite,
        part: 0,
        words: words,
      );
      expect(recite, [true, true, true, true, true, true, false]);
      expect(
        hiddenMask(
          verseId: 'v',
          step: TrainerStep.understand,
          part: 0,
          words: words,
        ),
        everyElement(isFalse),
      );
    });

    test('Devanagari words and numbers', () {
      expect(isHideable('कर्मण्येवाधिकारस्ते'), isTrue);
      expect(isHideable('॥४७॥'), isFalse);
      expect(firstLetterOf('कर्मण्ये'), 'क');
      expect(firstLetterOf('ārjuna'), 'ā');
      expect(firstLetterOf("'stv"), "'s");
    });

    test('a very short line still hides one word on step 2', () {
      final m = hiddenMask(
        verseId: 'v',
        step: TrainerStep.someHidden,
        part: 0,
        words: const ['om'],
      );
      expect(m, [true]);
    });

    test('more than two reveals repeats the step', () {
      expect(shouldRepeatStep(2), isFalse);
      expect(shouldRepeatStep(3), isTrue);
    });
  });

  group('review schedule', () {
    final t0 = DateTime(2026, 11, 12, 9);
    ShlokaState learnedState() {
      var s = ShlokaState.start('bg-02-047', t0);
      for (var i = 0; i < 5; i++) {
        s = ReviewSchedule.stepDone(s, t0, '2026-11-12');
      }
      return s;
    }

    test('steps 1 to 5, then learned with the first review tomorrow', () {
      var s = ShlokaState.start('bg-02-047', t0);
      for (var i = 1; i < 5; i++) {
        s = ReviewSchedule.stepDone(s, t0, '2026-11-12');
        expect(s.step, i + 1);
        expect(s.status, ShlokaStatus.learning);
      }
      s = ReviewSchedule.stepDone(s, t0, '2026-11-12');
      expect(s.status, ShlokaStatus.learned);
      expect(s.nextReview, '2026-11-13');
      expect(s.isDue('2026-11-12'), isFalse);
      expect(s.isDue('2026-11-13'), isTrue);
    });

    test('not yet on recite goes back to first letters', () {
      final s = ReviewSchedule.reciteMissed(
        ShlokaState.start('x', t0).copyWith(step: 5),
      );
      expect(s.step, 4);
    });

    test('passing walks 1, 3, 7, 21, 60 days, then mastered', () {
      var s = learnedState();
      var today = '2026-11-13';
      for (final wait in [3, 7, 21, 60]) {
        s = ReviewSchedule.reviewed(s, passed: true, now: t0, today: today);
        final p = DateTime.parse(today).add(Duration(days: wait));
        final key =
            '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
        expect(s.nextReview, key);
        today = s.nextReview!;
      }
      s = ReviewSchedule.reviewed(s, passed: true, now: t0, today: today);
      expect(s.status, ShlokaStatus.mastered);
      expect(s.nextReview, isNull);
      expect(s.isDue('2099-01-01'), isFalse);
    });

    test('missing moves back one wait, never below the first', () {
      var s = learnedState();
      s = ReviewSchedule.reviewed(
        s,
        passed: true,
        now: t0,
        today: '2026-11-13',
      );
      expect(s.reviewIndex, 1);
      s = ReviewSchedule.reviewed(
        s,
        passed: false,
        now: t0,
        today: '2026-11-16',
      );
      expect(s.reviewIndex, 0);
      expect(s.nextReview, '2026-11-17');
      s = ReviewSchedule.reviewed(
        s,
        passed: false,
        now: t0,
        today: '2026-11-17',
      );
      expect(s.reviewIndex, 0);
    });

    test('dates cross DST and leap days by calendar days', () {
      var s = ShlokaState.start('x', t0).copyWith(step: 5);
      s = ReviewSchedule.stepDone(s, t0, '2028-02-28');
      expect(s.nextReview, '2028-02-29');
      s = ShlokaState.start('y', t0).copyWith(step: 5);
      s = ReviewSchedule.stepDone(s, t0, '2026-03-28'); // EU DST weekend
      expect(s.nextReview, '2026-03-29');
    });

    test('step numbers map to steps', () {
      expect(TrainerStep.of(1), TrainerStep.understand);
      expect(TrainerStep.of(5), TrainerStep.recite);
      expect(TrainerStep.of(9), TrainerStep.recite);
    });
  });
}
