import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/premium_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/study_items.dart';
import '../../domain/premium.dart';
import '../premium/paywall_screen.dart';

void openNote(BuildContext context, String verseId) =>
    context.push('/note/${Uri.encodeComponent(verseId)}');

/// Opens the note for [verseId], or the paywall when a free user is at the
/// note limit. Existing notes always open.
void openNoteOrPaywall(BuildContext context, WidgetRef ref, String verseId) {
  if (ref.read(canWriteNoteProvider(verseId))) {
    openNote(context, verseId);
  } else {
    openPaywall(context, reason: PremiumFeature.unlimitedNotes);
  }
}

/// "Reflect on this chapter" (PRD_v5 section 5): a journal entry linked to
/// the chapter's last verse for Sadhak, otherwise a free note on it (or the
/// paywall once the free note limit is reached, as everywhere else).
void reflectOnChapter(BuildContext context, WidgetRef ref, String verseId) {
  if (canUse(PremiumFeature.journal, ref.read(entitlementProvider))) {
    context.push('/journal-edit?verse=${Uri.encodeQueryComponent(verseId)}');
  } else {
    openNoteOrPaywall(context, ref, verseId);
  }
}

/// The verse action that opens the highlight picker. Filled with the colour
/// when the verse is highlighted.
class HighlightButton extends ConsumerWidget {
  const HighlightButton({super.key, required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final color = ref.watch(highlightForProvider(verseId));
    final swatch = color == null
        ? null
        : HighlightColors.of(context).swatches[color.index];
    return Pressable(
      onTap: () => showHighlightSheet(context, verseId),
      semanticLabel: color == null
          ? 'Highlight verse'
          : 'Highlighted ${color.label}. Change highlight',
      child: SizedBox.square(
        dimension: Touch.minTarget,
        child: Icon(
          LucideIcons.highlighter,
          size: IconSizes.regular,
          color: swatch ?? c.textSecondary,
        ),
      ),
    );
  }
}

/// The verse action that opens the note. Shows a small dot when a note
/// exists.
class NoteButton extends ConsumerWidget {
  const NoteButton({super.key, required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final has = ref.watch(noteForProvider(verseId)) != null;
    return Pressable(
      onTap: () => openNoteOrPaywall(context, ref, verseId),
      semanticLabel: has ? 'Open your note' : 'Add a note',
      child: SizedBox.square(
        dimension: Touch.minTarget,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              has ? LucideIcons.notebook_text : LucideIcons.notebook_pen,
              size: IconSizes.regular,
              color: has ? c.accentText : c.textSecondary,
            ),
            if (has)
              Positioned(
                top: Space.s12 - 2,
                right: Space.s12 - 2,
                child: Container(
                  width: Space.s8,
                  height: Space.s8,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showHighlightSheet(BuildContext context, String verseId) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _HighlightSheet(verseId: verseId),
    );

class _HighlightSheet extends ConsumerWidget {
  const _HighlightSheet({required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final h = HighlightColors.of(context);
    final current = ref.watch(highlightForProvider(verseId));
    final study = ref.read(studyControllerProvider);
    final duration = Motion.of(context).reduced
        ? AppDurations.instant
        : AppDurations.fast;

    Future<void> pick(HighlightColor? color) async {
      Navigator.of(context).pop();
      await study.setHighlight(verseId, color);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.readingSide,
          Space.s16,
          Space.readingSide,
          Space.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Highlight', style: ui.emptyTitle),
            ),
            const SizedBox(height: Space.s16),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: Space.s12,
              runSpacing: Space.s12,
              children: [
                for (final color in HighlightColor.values)
                  Semantics(
                    button: true,
                    selected: current == color,
                    label: color.label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => pick(color),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: duration,
                            width: Touch.minTarget + Space.s8,
                            height: Touch.minTarget + Space.s8,
                            decoration: BoxDecoration(
                              color: h.bands[color.index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: h.swatches[color.index],
                                width: current == color ? 3 : 1.5,
                              ),
                            ),
                            child: current == color
                                ? Icon(
                                    LucideIcons.check,
                                    color: h.swatches[color.index],
                                  )
                                : null,
                          ),
                          const SizedBox(height: Space.s4),
                          Text(color.label, style: ui.body(size: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: Space.s16),
              TextButton(
                onPressed: () => pick(null),
                child: const Text('Remove highlight'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
