import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/verse_navigation.dart';

/// Verse selector (PRD 5.5). Returns the chosen entry index.
Future<int?> showVerseSelector(
  BuildContext context, {
  required Chapter chapter,
  required List<VerseEntry> entries,
  required int currentIndex,
}) => showAppBottomSheet<int>(
  context,
  title: 'Chapter ${chapter.number} - ${chapter.verseCount} verses',
  initialSize: 0.45,
  maxSize: 0.7,
  builder: (context, controller) => _VerseGrid(
    entries: entries,
    current: currentIndex,
    controller: controller,
  ),
);

class _VerseGrid extends ConsumerWidget {
  const _VerseGrid({
    required this.entries,
    required this.current,
    required this.controller,
  });

  final List<VerseEntry> entries;
  final int current;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        Space.s16,
        Space.s8,
        Space.s16,
        MediaQuery.paddingOf(context).bottom + Space.s24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 5 per row on a 360 dp screen, at least 48 wide.
          const gap = Space.s8;
          final perRow = ((constraints.maxWidth + gap) / (56 + gap))
              .floor()
              .clamp(5, 10);
          final w = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < entries.length; i++)
                _Chip(
                  width: w,
                  entry: entries[i],
                  selected: i == current,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(i);
                  },
                  textStyle: ui.label(size: 15),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends ConsumerWidget {
  const _Chip({
    required this.width,
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.textStyle,
  });

  final double width;
  final VerseEntry entry;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final saved = ref.watch(savedStateProvider(entry.id));
    final hasDot = saved.isFavourite || saved.isBookmarked;
    final label = shortLabel(entry);
    return Pressable(
      onTap: onTap,
      radius: Radii.chip,
      selected: selected,
      semanticLabel:
          'Verse ${entry.label}${hasDot ? ', saved' : ''}'
          '${selected ? ', current' : ''}',
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surfaceSoft,
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: textStyle.copyWith(
                    color: selected ? c.onAccent : c.textPrimary,
                  ),
                ),
              ),
            ),
            if (hasDot)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? c.onAccent : c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
