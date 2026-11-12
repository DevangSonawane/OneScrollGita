import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/user/database.dart';
import 'package:versescroll/data/user/study_repository.dart';
import 'package:versescroll/domain/models/study_items.dart';
import 'package:versescroll/domain/trainer/trainer.dart';

void main() {
  late AppDatabase db;
  late StudyRepository repo;
  var now = DateTime(2026, 11, 12, 9);
  setUp(() {
    db = AppDatabase.memory();
    repo = StudyRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('highlight set, change, remove', () async {
    await repo.setHighlight('bg-02-047', HighlightColor.saffron);
    await repo.setHighlight('bg-02-047', HighlightColor.sky);
    expect(
      (await repo.watchHighlights().first).single.color,
      HighlightColor.sky,
    );
    await repo.setHighlight('bg-02-047', null);
    expect(await repo.watchHighlights().first, isEmpty);
  });

  test(
    'notes keep their creation time, blank deletes, limit is enforced',
    () async {
      await repo.saveNote('bg-02-047', 'first');
      final created = (await repo.note('bg-02-047'))!.createdAt;
      now = now.add(const Duration(hours: 1));
      await repo.saveNote('bg-02-047', 'second');
      final n = (await repo.note('bg-02-047'))!;
      expect(n.body, 'second');
      expect(n.createdAt, created);
      expect(n.updatedAt, now);
      await repo.saveNote('bg-02-047', 'x' * (StudyLimits.noteMaxChars + 50));
      expect(
        (await repo.note('bg-02-047'))!.body.length,
        StudyLimits.noteMaxChars,
      );
      await repo.saveNote('bg-02-047', '   ');
      expect(await repo.note('bg-02-047'), isNull);
    },
  );

  test('journal create, update, delete by blank', () async {
    final id = await repo.saveJournal(verseId: 'bg-02-047', body: 'hello');
    expect(id, isNotNull);
    expect(await repo.saveJournal(id: id, body: 'hello again'), id);
    final e = (await repo.journalEntry(id!))!;
    expect(e.body, 'hello again');
    expect(e.verseId, 'bg-02-047');
    expect(await repo.saveJournal(id: id, body: ' '), isNull);
    expect(await repo.journalEntry(id), isNull);
    expect(await repo.saveJournal(body: ''), isNull);
  });

  test('shloka progress round trip and reset clears the study layer', () async {
    final s = ReviewSchedule.stepDone(
      ShlokaState.start('bg-02-047', now).copyWith(step: 5),
      now,
      '2026-11-12',
    );
    await repo.saveProgress(s);
    final back = (await repo.progress('bg-02-047'))!;
    expect(back.status, ShlokaStatus.learned);
    expect(back.nextReview, '2026-11-13');
    expect(back.learnedAt, now);
    await repo.setHighlight('bg-02-047', HighlightColor.leaf);
    await repo.saveNote('bg-02-047', 'n');
    await repo.saveJournal(body: 'j');
    await repo.resetAll();
    expect(await repo.watchProgress().first, isEmpty);
    expect(await repo.watchHighlights().first, isEmpty);
    expect(await repo.watchNotes().first, isEmpty);
    expect(await repo.watchJournal().first, isEmpty);
  });
}
