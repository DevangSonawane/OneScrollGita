import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user/study_repository.dart';
import '../domain/local_date.dart';
import '../domain/models/study_items.dart';
import '../domain/premium.dart';
import '../domain/trainer/trainer.dart';
import 'core_providers.dart';
import 'premium_providers.dart';
import 'scripture_providers.dart';

/// Overridden in main() and in tests.
final studyRepositoryProvider = Provider<StudyRepository>(
  (_) => throw UnimplementedError('studyRepositoryProvider'),
);

final highlightsProvider = StreamProvider<List<VerseHighlight>>(
  (ref) => ref.watch(studyRepositoryProvider).watchHighlights(),
);

final highlightForProvider = Provider.family<HighlightColor?, String>(
  (ref, id) => ref
      .watch(highlightsProvider)
      .value
      ?.where((h) => h.verseId == id)
      .firstOrNull
      ?.color,
);

final notesProvider = StreamProvider<List<VerseNote>>(
  (ref) => ref.watch(studyRepositoryProvider).watchNotes(),
);

final noteForProvider = Provider.family<VerseNote?, String>(
  (ref, id) =>
      ref.watch(notesProvider).value?.where((n) => n.verseId == id).firstOrNull,
);

final journalProvider = StreamProvider<List<JournalEntry>>(
  (ref) => ref.watch(studyRepositoryProvider).watchJournal(),
);

final shlokaProgressProvider = StreamProvider<List<ShlokaState>>(
  (ref) => ref.watch(studyRepositoryProvider).watchProgress(),
);

final shlokaForProvider = Provider.family<ShlokaState?, String>(
  (ref, id) => ref
      .watch(shlokaProgressProvider)
      .value
      ?.where((s) => s.verseId == id)
      .firstOrNull,
);

/// Learned verses whose review is due today or earlier, oldest first.
final dueReviewsProvider = Provider<List<ShlokaState>>((ref) {
  final today = dateKey(ref.watch(todayProvider));
  final all = ref.watch(shlokaProgressProvider).value ?? const [];
  return [...all.where((s) => s.isDue(today))]
    ..sort((a, b) => a.nextReview!.compareTo(b.nextReview!));
});

/// Whether a new note may be created for [verseId] (existing notes are
/// always editable).
final canWriteNoteProvider = Provider.family<bool, String>((ref, id) {
  if (ref.watch(noteForProvider(id)) != null) return true;
  final count = ref.watch(notesProvider).value?.length ?? 0;
  return canUse(
    PremiumFeature.unlimitedNotes,
    ref.watch(entitlementProvider),
    notesCount: count,
  );
});

final studyControllerProvider = Provider<StudyController>(StudyController.new);

/// The only way screens change the study layer.
class StudyController {
  StudyController(this._ref);

  final Ref _ref;
  StudyRepository get _repo => _ref.read(studyRepositoryProvider);

  Future<void> setHighlight(String verseId, HighlightColor? color) =>
      _repo.setHighlight(verseId, color);

  Future<void> saveNote(String verseId, String body) =>
      _repo.saveNote(verseId, body);

  Future<void> deleteNote(String verseId) => _repo.deleteNote(verseId);

  Future<int?> saveJournal({int? id, String? verseId, required String body}) =>
      _repo.saveJournal(id: id, verseId: verseId, body: body);

  Future<void> deleteJournal(int id) => _repo.deleteJournal(id);

  DateTime get _now => _ref.read(clockProvider)();
  String get _today => dateKey(_ref.read(todayProvider));

  /// Starts (or resumes) learning [verseId].
  Future<ShlokaState> startLearning(String verseId) async {
    final existing = await _repo.progress(verseId);
    if (existing != null) return existing;
    final s = ShlokaState.start(verseId, _now);
    await _repo.saveProgress(s);
    return s;
  }

  Future<ShlokaState> stepDone(ShlokaState s) async {
    final next = ReviewSchedule.stepDone(s, _now, _today);
    await _repo.saveProgress(next);
    return next;
  }

  Future<ShlokaState> reciteMissed(ShlokaState s) async {
    final next = ReviewSchedule.reciteMissed(s);
    await _repo.saveProgress(next);
    return next;
  }

  Future<ShlokaState> reviewed(ShlokaState s, {required bool passed}) async {
    final next = ReviewSchedule.reviewed(
      s,
      passed: passed,
      now: _now,
      today: _today,
    );
    await _repo.saveProgress(next);
    return next;
  }

  /// Starts the verse over from step 1 (keeps nothing of the old progress).
  Future<void> forget(String verseId) => _repo.deleteProgress(verseId);
}

/// The trainer shows Devanagari (true) or the transliteration (false).
final trainerDevanagariProvider = NotifierProvider<TrainerScriptNotifier, bool>(
  TrainerScriptNotifier.new,
);

class TrainerScriptNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).trainerDevanagari;

  Future<void> set(bool devanagari) async {
    state = devanagari;
    await ref.read(settingsRepositoryProvider).setTrainerDevanagari(devanagari);
  }
}
