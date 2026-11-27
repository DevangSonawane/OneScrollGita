import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/library_providers.dart';
import 'package:versescroll/application/watch_sync.dart';
import 'package:versescroll/data/platform/watch_channel.dart';
import 'package:versescroll/domain/models/user_items.dart';

class _RecordingChannel extends WatchChannel {
  final sent = <Map<String, Object?>>[];

  @override
  Future<void> update(Map<String, Object?> state) async => sent.add(state);
}

SavedItem _item(String id, int ms) =>
    SavedItem(verseId: id, at: DateTime.fromMillisecondsSinceEpoch(ms));

void main() {
  late StreamController<List<SavedItem>> bookmarks;
  late _RecordingChannel channel;

  ProviderContainer make({bool enabled = true, String? last = 'bg-02-047'}) {
    final c = ProviderContainer(
      overrides: [
        watchSyncEnabledProvider.overrideWithValue(enabled),
        watchChannelProvider.overrideWithValue(channel),
        bookmarksProvider.overrideWith((_) => bookmarks.stream),
        languageProvider.overrideWithValue('en'),
        watchLastVerseIdProvider.overrideWithValue(last),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    bookmarks = StreamController<List<SavedItem>>();
    channel = _RecordingChannel();
  });

  test('waits for bookmarks, then sends IDs newest first', () async {
    final c = make();
    c.listen(watchSyncProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(channel.sent, isEmpty);

    bookmarks.add([_item('bg-18-066', 2), _item('bg-01-016-018', 1)]);
    await Future<void>.delayed(Duration.zero);
    expect(channel.sent, [
      {
        'v': 1,
        'lang': 'en',
        'lastVerseId': 'bg-02-047',
        'bookmarks': ['bg-18-066', 'bg-01-016-018'],
      },
    ]);
  });

  test('does not resend the same state', () async {
    final c = make();
    c.listen(watchSyncProvider, (_, _) {});
    bookmarks.add([_item('bg-02-047', 1)]);
    await Future<void>.delayed(Duration.zero);
    bookmarks.add([_item('bg-02-047', 1)]);
    await Future<void>.delayed(Duration.zero);
    expect(channel.sent, hasLength(1));
    bookmarks.add(const []);
    await Future<void>.delayed(Duration.zero);
    expect(channel.sent, hasLength(2));
    expect(channel.sent.last['bookmarks'], isEmpty);
  });

  test('does nothing off iOS', () async {
    final c = make(enabled: false);
    c.listen(watchSyncProvider, (_, _) {});
    bookmarks.add([_item('bg-02-047', 1)]);
    await Future<void>.delayed(Duration.zero);
    expect(channel.sent, isEmpty);
  });

  test('caps the mirrored bookmarks', () {
    final many = [for (var i = 0; i < 600; i++) _item('bg-02-047', i)];
    final state = watchState(
      language: 'hi',
      lastVerseId: null,
      bookmarks: many,
    );
    expect(state['bookmarks'], hasLength(watchBookmarkLimit));
    expect(state['lastVerseId'], isNull);
  });
}
