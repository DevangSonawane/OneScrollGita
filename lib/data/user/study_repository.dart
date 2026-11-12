import 'package:drift/drift.dart';

import '../../domain/models/study_items.dart';
import '../../domain/trainer/trainer.dart';
import 'database.dart';

/// Highlights, notes, journal and shloka progress in SQLite. User data only;
/// verse ids are the only link to scripture.
class StudyRepository {
  StudyRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  int get _now => _clock().millisecondsSinceEpoch;
  static DateTime _t(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  // Highlights ---------------------------------------------------------------

  Stream<List<VerseHighlight>> watchHighlights() {
    final q = _db.select(_db.verseHighlights)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAtMs)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          if (HighlightColor.fromName(r.color) case final color?)
            VerseHighlight(
              verseId: r.verseId,
              color: color,
              updatedAt: _t(r.updatedAtMs),
            ),
      ],
    );
  }

  Future<void> setHighlight(String verseId, HighlightColor? color) =>
      color == null
      ? (_db.delete(
          _db.verseHighlights,
        )..where((t) => t.verseId.equals(verseId))).go()
      : _db
            .into(_db.verseHighlights)
            .insertOnConflictUpdate(
              VerseHighlightsCompanion.insert(
                verseId: verseId,
                color: color.name,
                updatedAtMs: _now,
              ),
            );

  // Notes --------------------------------------------------------------------

  Stream<List<VerseNote>> watchNotes() {
    final q = _db.select(_db.verseNotes)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAtMs)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          VerseNote(
            verseId: r.verseId,
            body: r.body,
            createdAt: _t(r.createdAtMs),
            updatedAt: _t(r.updatedAtMs),
          ),
      ],
    );
  }

  Future<VerseNote?> note(String verseId) async {
    final r = await (_db.select(
      _db.verseNotes,
    )..where((t) => t.verseId.equals(verseId))).getSingleOrNull();
    return r == null
        ? null
        : VerseNote(
            verseId: r.verseId,
            body: r.body,
            createdAt: _t(r.createdAtMs),
            updatedAt: _t(r.updatedAtMs),
          );
  }

  /// Saves the note; an empty (blank) body deletes it. Text over the limit is
  /// cut to the limit.
  Future<void> saveNote(String verseId, String body) async {
    final text = body.length > StudyLimits.noteMaxChars
        ? body.substring(0, StudyLimits.noteMaxChars)
        : body;
    if (text.trim().isEmpty) return deleteNote(verseId);
    final existing = await note(verseId);
    await _db
        .into(_db.verseNotes)
        .insertOnConflictUpdate(
          VerseNotesCompanion.insert(
            verseId: verseId,
            body: text,
            createdAtMs: existing?.createdAt.millisecondsSinceEpoch ?? _now,
            updatedAtMs: _now,
          ),
        );
  }

  Future<void> deleteNote(String verseId) => (_db.delete(
    _db.verseNotes,
  )..where((t) => t.verseId.equals(verseId))).go();

  // Journal ------------------------------------------------------------------

  Stream<List<JournalEntry>> watchJournal() {
    final q = _db.select(_db.journalEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]);
    return q.watch().map((rows) => [for (final r in rows) _journal(r)]);
  }

  Future<JournalEntry?> journalEntry(int id) async {
    final r = await (_db.select(
      _db.journalEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _journal(r);
  }

  static JournalEntry _journal(JournalRow r) => JournalEntry(
    id: r.id,
    verseId: r.verseId,
    body: r.body,
    createdAt: _t(r.createdAtMs),
    updatedAt: _t(r.updatedAtMs),
  );

  /// Creates (when [id] is null) or updates an entry and returns its id.
  /// A blank body deletes an existing entry and returns null.
  Future<int?> saveJournal({int? id, String? verseId, required String body}) {
    final text = body.length > StudyLimits.journalMaxChars
        ? body.substring(0, StudyLimits.journalMaxChars)
        : body;
    if (text.trim().isEmpty) {
      return id == null ? Future.value() : deleteJournal(id).then((_) => null);
    }
    if (id == null) {
      return _db
          .into(_db.journalEntries)
          .insert(
            JournalEntriesCompanion.insert(
              verseId: Value(verseId),
              body: text,
              createdAtMs: _now,
              updatedAtMs: _now,
            ),
          );
    }
    return (_db.update(_db.journalEntries)..where((t) => t.id.equals(id)))
        .write(
          JournalEntriesCompanion(body: Value(text), updatedAtMs: Value(_now)),
        )
        .then((_) => id);
  }

  Future<void> deleteJournal(int id) =>
      (_db.delete(_db.journalEntries)..where((t) => t.id.equals(id))).go();

  // Shloka progress ----------------------------------------------------------

  Stream<List<ShlokaState>> watchProgress() {
    final q = _db.select(_db.shlokaProgress)
      ..orderBy([(t) => OrderingTerm.desc(t.startedAtMs)]);
    return q.watch().map((rows) => [for (final r in rows) _progress(r)]);
  }

  Future<ShlokaState?> progress(String verseId) async {
    final r = await (_db.select(
      _db.shlokaProgress,
    )..where((t) => t.verseId.equals(verseId))).getSingleOrNull();
    return r == null ? null : _progress(r);
  }

  static ShlokaState _progress(ShlokaProgressRow r) => ShlokaState(
    verseId: r.verseId,
    step: r.step,
    status: ShlokaStatus.fromName(r.status),
    reviewIndex: r.reviewIndex,
    nextReview: r.nextReview,
    startedAt: _t(r.startedAtMs),
    learnedAt: r.learnedAtMs == null ? null : _t(r.learnedAtMs!),
    lastReviewedAt: r.lastReviewedAtMs == null ? null : _t(r.lastReviewedAtMs!),
  );

  Future<void> saveProgress(ShlokaState s) => _db
      .into(_db.shlokaProgress)
      .insertOnConflictUpdate(
        ShlokaProgressCompanion.insert(
          verseId: s.verseId,
          step: s.step,
          status: s.status.name,
          reviewIndex: s.reviewIndex,
          nextReview: Value(s.nextReview),
          startedAtMs: s.startedAt.millisecondsSinceEpoch,
          learnedAtMs: Value(s.learnedAt?.millisecondsSinceEpoch),
          lastReviewedAtMs: Value(s.lastReviewedAt?.millisecondsSinceEpoch),
        ),
      );

  Future<void> deleteProgress(String verseId) => (_db.delete(
    _db.shlokaProgress,
  )..where((t) => t.verseId.equals(verseId))).go();

  // Housekeeping -------------------------------------------------------------

  /// "Reset all saved data" clears the whole study layer.
  Future<void> resetAll() => _db.transaction(() async {
    await _db.delete(_db.verseHighlights).go();
    await _db.delete(_db.verseNotes).go();
    await _db.delete(_db.journalEntries).go();
    await _db.delete(_db.shlokaProgress).go();
  });
}
