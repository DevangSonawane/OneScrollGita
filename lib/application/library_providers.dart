import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/user_items.dart';
import 'core_providers.dart';
import 'ui_providers.dart';

final favouritesProvider = StreamProvider<List<SavedItem>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchFavourites(),
);
final bookmarksProvider = StreamProvider<List<SavedItem>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchBookmarks(),
);
final historyProvider = StreamProvider<List<SavedItem>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchHistory(),
);

final _favouriteIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final i in ref.watch(favouritesProvider).value ?? const <SavedItem>[]) i.verseId,
  },
);
final _bookmarkIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final i in ref.watch(bookmarksProvider).value ?? const <SavedItem>[]) i.verseId,
  },
);

/// One source of truth for a verse's saved state on every screen. Includes
/// optimistic changes that are still being written.
final savedStateProvider = Provider.family<SavedState, String>((ref, id) {
  final pending = ref.watch(libraryControllerProvider);
  return SavedState(
    isFavourite:
        pending.favourites[id] ?? ref.watch(_favouriteIdsProvider).contains(id),
    isBookmarked:
        pending.bookmarks[id] ?? ref.watch(_bookmarkIdsProvider).contains(id),
  );
});

class PendingSaves {
  const PendingSaves({this.favourites = const {}, this.bookmarks = const {}});

  final Map<String, bool> favourites;
  final Map<String, bool> bookmarks;
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, PendingSaves>(LibraryController.new);

class LibraryController extends Notifier<PendingSaves> {
  @override
  PendingSaves build() {
    // Drop an optimistic value once the database reflects it.
    ref.listen(_favouriteIdsProvider, (_, ids) => _settle(ids, true));
    ref.listen(_bookmarkIdsProvider, (_, ids) => _settle(ids, false));
    return const PendingSaves();
  }

  void _settle(Set<String> ids, bool favourites) {
    final map = favourites ? state.favourites : state.bookmarks;
    final kept = {
      for (final e in map.entries)
        if (ids.contains(e.key) != e.value) e.key: e.value,
    };
    if (kept.length == map.length) return;
    state = favourites
        ? PendingSaves(favourites: kept, bookmarks: state.bookmarks)
        : PendingSaves(favourites: state.favourites, bookmarks: kept);
  }

  void _setPending(String id, bool? value, {required bool favourite}) {
    final map = Map.of(favourite ? state.favourites : state.bookmarks);
    value == null ? map.remove(id) : map[id] = value;
    state = favourite
        ? PendingSaves(favourites: map, bookmarks: state.bookmarks)
        : PendingSaves(favourites: state.favourites, bookmarks: map);
  }

  /// Returns false if saving failed (the change is reverted).
  Future<bool> setFavourite(String id, bool value, {DateTime? at}) async {
    _setPending(id, value, favourite: true);
    try {
      await ref.read(userDataRepositoryProvider).setFavourite(id, value, at: at);
      return true;
    } catch (_) {
      _setPending(id, null, favourite: true);
      return false;
    }
  }

  Future<bool> setBookmark(String id, bool value, {DateTime? at}) async {
    _setPending(id, value, favourite: false);
    try {
      await ref.read(userDataRepositoryProvider).setBookmark(id, value, at: at);
      return true;
    } catch (_) {
      _setPending(id, null, favourite: false);
      return false;
    }
  }

  // Read the sources directly: savedStateProvider depends on this notifier.
  Future<bool> toggleFavourite(String id) => setFavourite(
    id,
    !(state.favourites[id] ?? ref.read(_favouriteIdsProvider).contains(id)),
  );

  Future<bool> toggleBookmark(String id) => setBookmark(
    id,
    !(state.bookmarks[id] ?? ref.read(_bookmarkIdsProvider).contains(id)),
  );

  Future<void> recordHistory(String id) =>
      ref.read(userDataRepositoryProvider).recordHistory(id);

  Future<void> clearHistory() =>
      ref.read(userDataRepositoryProvider).clearHistory();

  /// Clears favourites, bookmarks, history and settings (back to first
  /// launch).
  Future<void> resetAll() async {
    await ref.read(userDataRepositoryProvider).resetAll();
    await ref.read(settingsProvider.notifier).resetAll();
    ref.invalidate(readerJumpProvider);
    state = const PendingSaves();
  }

  /// Startup cleanup of ids that no longer exist in the dataset.
  Future<void> purgeOrphans() async {
    final scripture = ref.read(scriptureRepositoryProvider);
    await ref.read(userDataRepositoryProvider).purgeOrphans(scripture.exists);
    final last = ref.read(settingsProvider).lastVerseId;
    if (last != null && !await scripture.exists(last)) {
      await ref.read(settingsProvider.notifier).setLastVerseId(null);
    }
  }
}
