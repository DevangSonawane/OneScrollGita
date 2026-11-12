import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/study_items.dart';
import '../../domain/premium.dart';
import '../common/common_widgets.dart';
import 'study_actions.dart';

/// Highlights, grouped by colour, newest first.
class HighlightsScreen extends ConsumerWidget {
  const HighlightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final h = HighlightColors.of(context);
    final items = ref.watch(highlightsProvider);
    final list = items.value ?? const <VerseHighlight>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlights'),
        leading: LucideBackButton(onPressed: () => context.go('/profile')),
      ),
      body: !items.hasValue
          ? const SizedBox.expand()
          : list.isEmpty
          ? EmptyState(
              icon: LucideIcons.highlighter,
              title: 'No highlights yet',
              sentence:
                  'Tap the highlighter on any verse to colour it and keep it '
                  'here.',
              buttonLabel: 'Open the Gita',
              onPressed: () => context.go('/gita'),
            )
          : NavHideOnScroll(
              child: ContentWidth(
                child: ListView(
                  padding: EdgeInsets.only(bottom: navBarInset(context)),
                  children: [
                    for (final color in HighlightColor.values)
                      if (list.any((x) => x.color == color)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.readingSide,
                            Space.s24,
                            Space.readingSide,
                            Space.s8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: Space.s12,
                                height: Space.s12,
                                decoration: BoxDecoration(
                                  color: h.swatches[color.index],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: Space.s8),
                              Semantics(
                                header: true,
                                child: Text(
                                  color.label.toUpperCase(),
                                  style: ui.overline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final item in list.where((x) => x.color == color))
                          _VerseTile(
                            verseId: item.verseId,
                            onTap: () => openInReader(context, item.verseId),
                            onLongPress: () =>
                                showHighlightSheet(context, item.verseId),
                          ),
                      ],
                  ],
                ),
              ),
            ),
    );
  }
}

/// Notes, newest first. Free users see how many of their notes are left.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final items = ref.watch(notesProvider);
    final list = items.value ?? const <VerseNote>[];
    final premium = ref.watch(isPremiumProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My notes'),
        leading: LucideBackButton(onPressed: () => context.go('/profile')),
      ),
      body: !items.hasValue
          ? const SizedBox.expand()
          : list.isEmpty
          ? EmptyState(
              icon: LucideIcons.notebook_pen,
              title: 'No notes yet',
              sentence:
                  'Tap the note icon on any verse to write what it means to '
                  'you.',
              buttonLabel: 'Open the Gita',
              onPressed: () => context.go('/gita'),
            )
          : NavHideOnScroll(
              child: ContentWidth(
                child: ListView(
                  padding: EdgeInsets.only(bottom: navBarInset(context)),
                  children: [
                    if (!premium)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.readingSide,
                          Space.s8,
                          Space.readingSide,
                          Space.s8,
                        ),
                        child: Text(
                          '${list.length} of ${FreeLimits.maxNotes} free notes. '
                          'Sadhak has no limit.',
                          style: ui.body(size: 13, color: c.textTertiary),
                        ),
                      ),
                    for (final note in list)
                      _VerseTile(
                        verseId: note.verseId,
                        preview: previewOf(note.body),
                        onTap: () => openNote(context, note.verseId),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A verse row: its label, chapter and either [preview] (the user's own
/// text) or the translation.
class _VerseTile extends ConsumerWidget {
  const _VerseTile({
    required this.verseId,
    required this.onTap,
    this.onLongPress,
    this.preview,
  });

  final String verseId;
  final String? preview;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(entryProvider(verseId)).value;
    final index = ref.watch(chaptersIndexProvider).value;
    final lang = ref.watch(languageProvider);
    if (entry == null || index == null) return const SizedBox.shrink();
    return VerseListTile(
      reference: entry.label,
      chapterTitle: index.chapter(entry.chapter).title(lang),
      preview: preview ?? entry.translation(lang),
      previewLocale: preview == null && lang == 'hi'
          ? const Locale('hi')
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
