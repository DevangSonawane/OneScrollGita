import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/platform/watch_channel.dart';
import '../domain/models/user_items.dart';
import 'core_providers.dart';
import 'library_providers.dart';

/// Apple Watch companion sync (docs/PRD_v10.md section 4).
///
/// The phone is the only place bookmarks and the reading position are
/// stored; the watch keeps a read-only mirror. The watch ships its own copy
/// of the verse text, so only verse IDs and the language cross over.
final watchChannelProvider = Provider<WatchChannel>((_) => WatchChannel());

/// The watch app exists only next to the iOS app.
final watchSyncEnabledProvider = Provider<bool>(
  (_) => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
);

final watchLastVerseIdProvider = Provider<String?>(
  (ref) => ref.watch(settingsProvider.select((s) => s.lastVerseId)),
);

/// Most bookmarks the watch mirrors (newest first). IDs are short strings,
/// so this stays far under WatchConnectivity's context size limit.
const watchBookmarkLimit = 500;

/// The state the watch mirrors. Keys are read by
/// ios/GitaWatch/Shared/WatchState.swift; bump `v` if their meaning changes.
Map<String, Object?> watchState({
  required String language,
  required String? lastVerseId,
  required List<SavedItem> bookmarks,
}) => {
  'v': 1,
  'lang': language,
  'lastVerseId': lastVerseId,
  'bookmarks': [for (final b in bookmarks.take(watchBookmarkLimit)) b.verseId],
};

final watchSyncProvider = Provider<void>((ref) {
  if (!ref.watch(watchSyncEnabledProvider)) return;
  String? lastSent;

  void push() {
    final bookmarks = ref.read(bookmarksProvider).value;
    // Wait for the database: an empty list before it loads would clear the
    // watch's bookmarks for a moment.
    if (bookmarks == null) return;
    final state = watchState(
      language: ref.read(languageProvider),
      lastVerseId: ref.read(watchLastVerseIdProvider),
      bookmarks: bookmarks,
    );
    final key = state.toString();
    if (key == lastSent) return;
    lastSent = key;
    unawaited(ref.read(watchChannelProvider).update(state));
  }

  ref.listen(bookmarksProvider, (_, _) => push(), fireImmediately: true);
  ref.listen(languageProvider, (_, _) => push());
  ref.listen(watchLastVerseIdProvider, (_, _) => push());
});
