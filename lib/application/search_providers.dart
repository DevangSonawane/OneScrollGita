import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/search/search_index.dart';
import '../domain/models/written_content.dart';
import '../domain/search/sensitive.dart';
import '../domain/search/theme_matcher.dart';
import 'scripture_providers.dart';
import 'streak_providers.dart';

/// True while the one-time index build runs ("Preparing search").
final searchPreparingProvider = NotifierProvider<_Flag, bool>(_Flag.new);

class _Flag extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

/// The FTS5 index; built in an isolate on first launch and whenever the
/// dataset version changes. Overridden in tests.
final searchIndexProvider = FutureProvider<SearchIndex>((ref) async {
  final index = await ref.watch(chaptersIndexProvider.future);
  final content = ref.read(contentRepositoryProvider);
  final aliases = await content.aliases().catchError(
    (Object _) => <String, String>{},
  );
  final preparing = ref.read(searchPreparingProvider.notifier);
  try {
    final search = await SearchIndex.open(
      datasetVersion: index.source.datasetVersion,
      aliases: aliases,
      onBuilding: () => preparing.set(true),
    );
    ref.onDispose(search.close);
    return search;
  } finally {
    preparing.set(false);
  }
});

final themesProvider = FutureProvider<List<SearchTheme>>(
  (ref) => ref.watch(contentRepositoryProvider).themes(),
);

final themeMatcherProvider = FutureProvider<ThemeMatcher>(
  (ref) async => ThemeMatcher(await ref.watch(themesProvider.future)),
);

final summariesProvider = FutureProvider<Map<int, ChapterSummary>>(
  (ref) => ref.watch(contentRepositoryProvider).summaries(),
);

final searchHistoryProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(activityRepositoryProvider).watchSearchHistory(),
);

class SearchOutcome {
  const SearchOutcome({
    required this.query,
    required this.sensitive,
    required this.themes,
    required this.themeEntries,
    required this.results,
  });

  final String query;
  final bool sensitive;
  final List<SearchTheme> themes;

  /// Verses of the matched themes, by theme id, in ranked order.
  final Map<String, List<CatalogueEntry>> themeEntries;
  final SearchResults results;

  bool get isEmpty => themes.isEmpty && results.isEmpty && !sensitive;
}

/// Runs one search: themes first, keyword results below.
final searchProvider = FutureProvider.autoDispose
    .family<SearchOutcome, ({String query, String lang})>((ref, a) async {
      final index = await ref.watch(searchIndexProvider.future);
      final matcher = await ref
          .watch(themeMatcherProvider.future)
          .catchError((Object _) => ThemeMatcher(const []));
      final sensitive = isSensitiveQuery(a.query);
      var themes = matcher.match(a.query);
      if (sensitive) {
        final all = await ref
            .watch(themesProvider.future)
            .catchError((Object _) => <SearchTheme>[]);
        themes = [
          for (final id in sensitiveFallbackThemes)
            ...all.where((t) => t.id == id),
        ];
      }
      return SearchOutcome(
        query: a.query,
        sensitive: sensitive,
        themes: themes,
        themeEntries: {for (final t in themes) t.id: index.entries(t.verseIds)},
        results: sensitive
            ? SearchResults.empty
            : index.search(a.query, lang: a.lang),
      );
    });
