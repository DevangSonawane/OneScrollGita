import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/chapter.dart';

const _rowHeight = 76.0;

/// Chapter bottom sheet (PRD 5.4). Returns the chosen chapter number.
Future<int?> showChapterSheet(
  BuildContext context, {
  required ChaptersIndex index,
  required int currentChapter,
}) => showAppBottomSheet<int>(
  context,
  title: 'Chapters',
  builder: (context, controller) => _ChapterList(
    index: index,
    current: currentChapter,
    controller: controller,
  ),
);

class _ChapterList extends StatefulWidget {
  const _ChapterList({
    required this.index,
    required this.current,
    required this.controller,
  });

  final ChaptersIndex index;
  final int current;
  final ScrollController controller;

  @override
  State<_ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<_ChapterList> {
  @override
  void initState() {
    super.initState();
    // Scroll to the current chapter on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = widget.controller;
      if (!c.hasClients) return;
      final target = (widget.current - 2) * _rowHeight;
      c.jumpTo(target.clamp(0, c.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final chapters = widget.index.chapters;
    return ListView.builder(
      controller: widget.controller,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + Space.s16,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, i) {
        final ch = chapters[i];
        final selected = ch.number == widget.current;
        return Semantics(
          selected: selected,
          button: true,
          label:
              'Chapter ${ch.number}, ${ch.titleEn}, ${ch.verseCount} verses',
          excludeSemantics: true,
          child: Material(
            color: selected ? c.accentSoft : Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(ch.number);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _rowHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.readingSide,
                    vertical: Space.s12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? c.surface : c.surfaceSoft,
                        ),
                        child: Text(
                          '${ch.number}',
                          style: ui.label(size: 14, color: c.accentText),
                        ),
                      ),
                      const SizedBox(width: Space.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ch.titleEn,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ui.label(size: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ch.verseCount} verses',
                              style: ui.body(size: 13),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded, color: c.accentText),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
