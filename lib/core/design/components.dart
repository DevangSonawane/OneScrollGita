import 'package:flutter/material.dart';

import 'glass.dart';
import 'motion.dart';
import 'tokens.dart';
import 'typography.dart';

/// "Bhagavad-gita 2.47".
class ReferenceChip extends StatelessWidget {
  const ReferenceChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s4 + 2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Text(label, style: UiStyles(c).reference),
    );
  }
}

/// Small spaced uppercase-free section label ("TODAY'S VERSE", "READING").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding:
        padding ??
        const EdgeInsets.fromLTRB(
          Space.readingSide,
          Space.s32,
          Space.readingSide,
          Space.s8,
        ),
    child: Semantics(
      header: true,
      child: Text(text, style: UiStyles(AppColors.of(context)).overline),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.sentence,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String sentence;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: IconSizes.large, color: c.accentText),
              ),
            ),
            const SizedBox(height: Space.s24),
            Text(title, style: ui.emptyTitle, textAlign: TextAlign.center),
            const SizedBox(height: Space.s8),
            Text(sentence, style: ui.body(), textAlign: TextAlign.center),
            const SizedBox(height: Space.s24),
            TextButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

/// A grouped settings row with hairline divider below.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron,
    this.divider = true,
    this.below,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool? showChevron;
  final bool divider;

  /// Content shown under the title row (segmented choices, sliders).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final chevron = showChevron ?? (onTap != null && !destructive);
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.readingSide,
        vertical: Space.s12,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Touch.minTarget - 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ui.label(
                          size: 16,
                          color: destructive ? c.danger : c.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: ui.body(size: 13)),
                      ],
                    ],
                  ),
                ),
                ?trailing,
                if (chevron)
                  Padding(
                    padding: const EdgeInsets.only(left: Space.s4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: c.textTertiary,
                      size: IconSizes.regular,
                    ),
                  ),
              ],
            ),
            if (below != null) ...[const SizedBox(height: Space.s12), below!],
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        onTap == null
            ? row
            : InkWell(onTap: onTap, child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Touch.minTarget),
                child: row,
              )),
        if (divider)
          const Padding(
            padding: EdgeInsets.only(left: Space.readingSide),
            child: Divider(),
          ),
      ],
    );
  }
}

class Choice<T> {
  const Choice(this.value, this.label, {this.semanticLabel});
  final T value;
  final String label;
  final String? semanticLabel;
}

/// Segmented control for language and theme.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.onSurface = false,
  });

  final List<Choice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;

  /// Small version used inside floating pills (EN | हि).
  final bool compact;

  /// Transparent track (when placed on glass).
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final height = compact ? 36.0 : Touch.minTarget;
    final motion = Motion.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onSurface ? Colors.transparent : c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (final ch in choices)
            _wrap(
              compact,
              Semantics(
                selected: ch.value == value,
                button: true,
                label: ch.semanticLabel ?? ch.label,
                excludeSemantics: true,
                child: Pressable(
                  button: false,
                  onTap: () => onChanged(ch.value),
                  child: AnimatedContainer(
                    duration: motion.crossFade,
                    curve: AppCurves.standard,
                    constraints: BoxConstraints(
                      minWidth: compact ? 40 : 0,
                      minHeight: height - 6,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? Space.s8 : Space.s12,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ch.value == value ? c.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      boxShadow: ch.value == value && !onSurface
                          ? [
                              BoxShadow(
                                color: c.shadow,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      ch.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ui.label(
                        size: compact ? 13 : 14,
                        color: ch.value == value
                            ? (compact ? c.accentText : c.textPrimary)
                            : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrap(bool compact, Widget child) =>
      compact ? child : Expanded(child: child);
}

/// Confirmation dialog. Returns true when the user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final c = AppColors.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: c.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Bottom sheet with a glass grabber header and a solid list body.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, ScrollController controller)
  builder,
  double initialSize = 0.85,
  double maxSize = 0.85,
}) {
  final motion = Motion.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    sheetAnimationStyle: AnimationStyle(
      duration: motion.sheet,
      reverseDuration: AppDurations.base,
      curve: AppCurves.standard,
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      maxChildSize: maxSize,
      minChildSize: 0.25,
      snap: true,
      builder: (context, controller) {
        final c = AppColors.of(context);
        return Column(
          children: [
            GlassLayer(
              strength: GlassStrength.light,
              child: Padding(
                padding: const EdgeInsets.only(top: Space.s8),
                child: ExcludeSemantics(
                  child: GlassShape(
                    radius: 3,
                    shadow: false,
                    child: SizedBox(
                      width: 40,
                      height: 5,
                      child: ColoredBox(color: c.hairline),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.readingSide,
                Space.s16,
                Space.readingSide,
                Space.s8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(title, style: UiStyles(c).emptyTitle),
                ),
              ),
            ),
            Expanded(child: builder(context, controller)),
          ],
        );
      },
    ),
  );
}

/// Row used by Favourites, Bookmarks and History.
class VerseListTile extends StatelessWidget {
  const VerseListTile({
    super.key,
    required this.reference,
    required this.chapterTitle,
    required this.preview,
    required this.onTap,
    this.onLongPress,
    this.previewLocale,
  });

  final String reference;
  final String chapterTitle;
  final String preview;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Locale? previewLocale;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.readingSide,
          vertical: Space.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(reference, style: ui.label(size: 15, color: c.accentText)),
                const SizedBox(width: Space.s8),
                Expanded(
                  child: Text(
                    chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ui.body(size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              locale: previewLocale,
              style: ui.body(color: c.textPrimary, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}
