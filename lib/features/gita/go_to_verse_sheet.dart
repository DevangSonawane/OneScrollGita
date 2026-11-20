import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core_providers.dart';
import '../../application/library_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/streak_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass.dart' show Pressable;
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/verse_navigation.dart';
import '../summary/summary_screen.dart';

/// "Go to verse" (PRD_v7 section 3): a reference box ("2.47"), the chapters
/// with their reading progress, and the chosen chapter's verses (read ones
/// tinted, the current one outlined, favourites marked). Returns the id of
/// the chosen verse.
Future<String?> showGoToVerseSheet(
  BuildContext context, {
  required ChaptersIndex index,
  required int currentChapter,
  String? currentId,
}) => showAppBottomSheet<String>(
  context,
  title: 'Go to verse',
  builder: (context, controller) => _GoToVerse(
    index: index,
    currentChapter: currentChapter,
    currentId: currentId,
    controller: controller,
  ),
);

class _GoToVerse extends ConsumerStatefulWidget {
  const _GoToVerse({
    required this.index,
    required this.currentChapter,
    required this.currentId,
    required this.controller,
  });

  final ChaptersIndex index;
  final int currentChapter;
  final String? currentId;
  final ScrollController controller;

  @override
  ConsumerState<_GoToVerse> createState() => _GoToVerseState();
}

class _GoToVerseState extends ConsumerState<_GoToVerse> {
  late int _chapter = widget.currentChapter;
  final _query = TextEditingController();
  final _strip = ScrollController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Bring the current chapter's tile into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_strip.hasClients) return;
      final x =
          (widget.currentChapter - 1) * (GoToMetrics.tileWidth + Space.s8);
      _strip.jumpTo(x.clamp(0, _strip.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _strip.dispose();
    super.dispose();
  }

  void _submit() {
    final ref_ = parseVerseReference(_query.text);
    final ch = ref_ == null
        ? null
        : widget.index.chapters.where((c) => c.number == ref_.$1).firstOrNull;
    if (ref_ == null || ch == null || ref_.$2 > ch.verseCount) {
      setState(() => _error = 'Try a reference like 2.47');
      return;
    }
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(formatVerseId(ref_.$1, ref_.$2));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final chapter = widget.index.chapters.firstWhere(
      (ch) => ch.number == _chapter,
      orElse: () => widget.index.chapters.first,
    );
    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + Space.s24,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
          child: TextField(
            controller: _query,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: 'Chapter.verse, like 2.47',
              prefixIcon: const Icon(LucideIcons.search),
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: 'Go',
                onPressed: _submit,
                icon: const Icon(LucideIcons.arrow_right),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.s16),
        SizedBox(
          // Grows with large text so tile titles never clip.
          height:
              GoToMetrics.tileHeight *
              (0.4 +
                  0.6 *
                      MediaQuery.textScalerOf(context)
                          .scale(1)
                          .clamp(1.0, 2.0)),
          child: ListView.separated(
            controller: _strip,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
            itemCount: widget.index.chapters.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.s8),
            itemBuilder: (context, i) {
              final ch = widget.index.chapters[i];
              return _ChapterTile(
                chapter: ch,
                selected: ch.number == _chapter,
                onTap: () => setState(() => _chapter = ch.number),
              );
            },
          ),
        ),
        const SizedBox(height: Space.s16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Chapter ${chapter.number} · ${chapter.verseCount} verses',
                  style: ui.label(size: 16),
                ),
              ),
              TextButton(
                onPressed: () => openSummary(context, chapter.number),
                child: const Text('Summary'),
              ),
            ],
          ),
        ),
        _VerseGrid(chapter: chapter.number, currentId: widget.currentId),
        const SizedBox(height: Space.s12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.readingSide),
          child: Wrap(
            spacing: Space.s16,
            runSpacing: Space.s4,
            children: [
              _Legend(swatch: _Swatch.read, label: 'Read'),
              _Legend(swatch: _Swatch.current, label: 'You are here'),
              _Legend(swatch: _Swatch.favourite, label: 'Favourite'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChapterTile extends ConsumerWidget {
  const _ChapterTile({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final Chapter chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    // Entry ids carry their chapter, so no chapter file has to load here.
    final done = ref
        .watch(readVerseIdsProvider)
        .where((id) => chapterOfId(id) == chapter.number)
        .length;
    final total = chapter.entryCount;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final title = lang == 'hi' && (chapter.titleHi?.isNotEmpty ?? false)
        ? chapter.titleHi!
        : chapter.titleEn;
    final fg = selected ? c.accentText : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Chapter ${chapter.number}, $title, $done of '
          '$total read',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        radius: Radii.card,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: GoToMetrics.tileWidth,
          padding: const EdgeInsets.all(Space.s12),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(
              color: selected ? c.accent : c.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // One number format, in the reading language.
                lang == 'hi'
                    ? 'अध्याय ${_devanagariDigits('${chapter.number}')}'
                    : 'Chapter ${chapter.number}',
                style: ui.label(size: 15, color: fg),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ui.body(size: 12, color: fg),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: selected ? c.surface : c.surfaceSoft,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseGrid extends ConsumerWidget {
  const _VerseGrid({required this.chapter, required this.currentId});

  final int chapter;
  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(chapterEntriesProvider(chapter)).value;
    if (entries == null) {
      return const SizedBox(height: Touch.minTarget * 3);
    }
    final read = ref.watch(readVerseIdsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = Space.s8;
          final perRow = ((box.maxWidth + gap) / (GoToMetrics.chip + gap))
              .floor()
              .clamp(4, 10);
          final w = (box.maxWidth - gap * (perRow - 1)) / perRow;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final e in entries)
                SizedBox(
                  width: w,
                  child: _VerseChip(
                    entry: e,
                    read: read.contains(e.id),
                    current: e.id == currentId,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VerseChip extends ConsumerWidget {
  const _VerseChip({
    required this.entry,
    required this.read,
    required this.current,
  });

  final VerseEntry entry;
  final bool read;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final favourite = ref.watch(savedStateProvider(entry.id)).isFavourite;
    final hindi = ref.watch(languageProvider) == 'hi';
    return Semantics(
      button: true,
      selected: current,
      label:
          'Verse ${entry.label}${read ? ', read' : ''}'
          '${favourite ? ', favourite' : ''}${current ? ', you are here' : ''}',
      excludeSemantics: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(entry.id);
        },
        radius: Radii.input,
        child: Container(
          constraints: const BoxConstraints(minHeight: Touch.minTarget),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: read ? c.accentSoft : null,
            borderRadius: BorderRadius.circular(Radii.input),
            border: Border.all(
              color: current ? c.accent : c.hairline,
              width: current ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (favourite) ...[
                Icon(
                  LucideIcons.heart,
                  size: IconSizes.small - 8,
                  color: c.accentText,
                ),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  hindi
                      ? _devanagariDigits(shortLabel(entry))
                      : shortLabel(entry),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: ui.label(
                    size: 14,
                    color: read || current ? c.accentText : c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Swatch { read, current, favourite }

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});

  final _Swatch swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final mark = switch (swatch) {
      _Swatch.favourite => Icon(
        LucideIcons.heart,
        size: IconSizes.small - 6,
        color: c.accentText,
      ),
      _ => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: swatch == _Swatch.read ? c.accentSoft : null,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: swatch == _Swatch.current ? c.accent : c.hairline,
            width: swatch == _Swatch.current ? 2 : 1,
          ),
        ),
      ),
    };
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: Space.s4),
          Text(label, style: UiStyles(c).body(size: 12)),
        ],
      ),
    );
  }
}

/// Latin digits to Devanagari ("16-18" -> "१६-१८"); other characters stay.
String _devanagariDigits(String s) =>
    s.replaceAllMapped(RegExp('[0-9]'), (m) => '०१२३४५६७८९'[int.parse(m[0]!)]);
