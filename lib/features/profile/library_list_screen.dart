import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/library_providers.dart';
import '../../application/scripture_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../domain/models/user_items.dart';
import '../common/common_widgets.dart';

enum LibraryKind { favourites, bookmarks, history }

/// Favourites, Bookmarks or History (newest first).
class LibraryListScreen extends ConsumerWidget {
  const LibraryListScreen({super.key, required this.kind});

  final LibraryKind kind;

  String get _title => switch (kind) {
    LibraryKind.favourites => 'Favourites',
    LibraryKind.bookmarks => 'Bookmarks',
    LibraryKind.history => 'History',
  };

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    SavedItem item,
  ) async {
    final library = ref.read(libraryControllerProvider.notifier);
    final fav = kind == LibraryKind.favourites;
    final ok = fav
        ? await library.setFavourite(item.verseId, false)
        : await library.setBookmark(item.verseId, false);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: AppDurations.undo,
        content: Text(
          ok
              ? (fav ? 'Removed from favourites' : 'Bookmark removed')
              : 'Could not remove. Please try again.',
        ),
        action: ok
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () => fav
                    ? library.setFavourite(item.verseId, true, at: item.at)
                    : library.setBookmark(item.verseId, true, at: item.at),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final items = ref.watch(switch (kind) {
      LibraryKind.favourites => favouritesProvider,
      LibraryKind.bookmarks => bookmarksProvider,
      LibraryKind.history => historyProvider,
    });
    final list = items.value ?? const <SavedItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: LucideBackButton(onPressed: () => context.go('/profile')),
        actions: [
          if (kind == LibraryKind.history && list.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Clear your reading history?',
                  message: 'Favourites and bookmarks are kept.',
                  confirmLabel: 'Clear',
                );
                if (ok) {
                  await ref
                      .read(libraryControllerProvider.notifier)
                      .clearHistory();
                }
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: !items.hasValue
          ? const SizedBox.expand()
          : list.isEmpty
          ? _empty(context)
          : NavHideOnScroll(
              child: ContentWidth(
                child: ListView.separated(
                  padding: EdgeInsets.only(bottom: navBarInset(context)),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.only(left: Space.readingSide),
                    child: Divider(),
                  ),
                  itemBuilder: (context, i) {
                    final item = list[i];
                    final tile = _Tile(
                      item: item,
                      onLongPress: kind == LibraryKind.history
                          ? null
                          : () => _showItemMenu(context, ref, item),
                    );
                    if (kind == LibraryKind.history) return tile;
                    return Semantics(
                      customSemanticsActions: {
                        const CustomSemanticsAction(label: 'Remove'): () =>
                            _remove(context, ref, item),
                      },
                      child: Dismissible(
                        key: ValueKey('${kind.name}-${item.verseId}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: c.surfaceSoft,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: Space.s24),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: c.danger,
                          ),
                        ),
                        onDismissed: (_) => _remove(context, ref, item),
                        child: tile,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  void _showItemMenu(BuildContext context, WidgetRef ref, SavedItem item) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Open in Gita'),
              onTap: () {
                Navigator.of(sheet).pop();
                openInReader(context, item.verseId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove'),
              onTap: () {
                Navigator.of(sheet).pop();
                _remove(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => switch (kind) {
    LibraryKind.favourites => EmptyState(
      icon: Icons.favorite_border_rounded,
      title: 'No favourites yet',
      sentence: 'Tap the heart on any verse to keep it here.',
      buttonLabel: 'Open the Gita',
      onPressed: () => context.go('/gita'),
    ),
    LibraryKind.bookmarks => EmptyState(
      icon: Icons.bookmark_border_rounded,
      title: 'Nothing bookmarked',
      sentence: 'Bookmark a verse to find your place again.',
      buttonLabel: 'Open the Gita',
      onPressed: () => context.go('/gita'),
    ),
    LibraryKind.history => EmptyState(
      icon: Icons.schedule_rounded,
      title: 'No reading history',
      sentence: 'Verses you read will appear here.',
      buttonLabel: "Read today's verse",
      onPressed: () => context.go('/home'),
    ),
  };
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.item, this.onLongPress});

  final SavedItem item;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(entryProvider(item.verseId)).value;
    final index = ref.watch(chaptersIndexProvider).value;
    final lang = ref.watch(languageProvider);
    // Orphans (ids no longer in the dataset) are hidden.
    if (entry == null || index == null) {
      return const SizedBox(height: 0);
    }
    return VerseListTile(
      reference: entry.label,
      chapterTitle: index.chapter(entry.chapter).title(lang),
      preview: entry.translation(lang),
      previewLocale: lang == 'hi' ? const Locale('hi') : null,
      onTap: () => openInReader(context, entry.id),
      onLongPress: onLongPress,
    );
  }
}
