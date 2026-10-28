import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core_providers.dart';
import '../../domain/markup.dart';
import '../../domain/models/verse_entry.dart';
import 'copy_on_tap.dart';
import 'motion.dart';
import 'tokens.dart';
import 'typography.dart';

ReadingStyles readingStyles(BuildContext context, WidgetRef ref) =>
    ReadingStyles(AppColors.of(context), ref.watch(readingScaleProvider));

/// Sanskrit shloka, centred, never letter-spaced.
class ShlokaView extends ConsumerWidget {
  const ShlokaView({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = readingStyles(context, ref).sanskrit;
    return Semantics(
      attributedLabel: AttributedString(
        lines.join('\n'),
        attributes: [
          LocaleStringAttribute(
            range: TextRange(start: 0, end: lines.join('\n').length),
            locale: const Locale('sa'),
          ),
        ],
      ),
      excludeSemantics: true,
      child: Text(
        lines.join('\n'),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class TransliterationView extends ConsumerWidget {
  const TransliterationView({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
    lines.join('\n'),
    textAlign: TextAlign.center,
    style: readingStyles(context, ref).transliteration,
  );
}

/// Translation in the selected language; cross-fades on language change.
class TranslationView extends ConsumerWidget {
  const TranslationView({super.key, required this.entry});

  final VerseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageProvider);
    // No Hindi in the source: show English with a quiet note.
    final fallback = !entry.hasTranslation(selected);
    final lang = fallback ? 'en' : selected;
    final style = readingStyles(context, ref).translation(lang);
    final c = AppColors.of(context);
    return AnimatedSwitcher(
      duration: Motion.of(context).crossFade,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      child: SizedBox(
        key: ValueKey('${entry.id}-$selected'),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fallback)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s8),
                child: Text(
                  'Hindi translation is not available yet. Showing English.',
                  style: UiStyles(c).body(size: 13, color: c.textTertiary),
                ),
              ),
            Text(
              entry.translation(lang),
              style: style,
              locale: lang == 'hi' ? const Locale('hi') : const Locale('en'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sanskrit, transliteration and translation, in that order.
class VerseTextBlock extends ConsumerWidget {
  const VerseTextBlock({
    super.key,
    required this.entry,
    this.gap = Space.s32,
    this.copyable = false,
  });

  final VerseEntry entry;
  final double gap;

  /// Tapping each part copies it (the reader).
  final bool copyable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final ref_ = '— Bhagavad-gītā ${entry.label}';
    Widget copy(String what, String text, Widget child) => copyable
        ? CopyOnTap(what: what, text: '$text\n$ref_', child: child)
        : child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        copy(
          'Sanskrit',
          entry.sanskrit.join('\n'),
          ShlokaView(lines: entry.sanskrit),
        ),
        SizedBox(height: gap * 0.75),
        copy(
          'Transliteration',
          entry.transliteration.join('\n'),
          TransliterationView(lines: entry.transliteration),
        ),
        SizedBox(height: gap),
        copy(
          'Translation',
          entry.translation(lang),
          TranslationView(entry: entry),
        ),
      ],
    );
  }
}

/// Turns `<i>`/`<b>` markup into spans. Never HTML.
List<InlineSpan> markupSpans(String text, TextStyle base) => [
  for (final s in parseMarkup(text))
    TextSpan(
      text: s.text,
      style: base.copyWith(
        fontStyle: s.italic ? FontStyle.italic : null,
        fontWeight: s.bold ? FontWeight.w700 : null,
        fontVariations: s.bold ? const [FontVariation('wght', 700)] : null,
      ),
    ),
];

/// One purport block (paragraph, quotation or Sanskrit line).
class PurportBlockView extends ConsumerWidget {
  const PurportBlockView({super.key, required this.block, required this.lang});

  final PurportBlock block;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final styles = readingStyles(context, ref);
    switch (block.type) {
      case PurportBlockType.paragraph:
        return Text.rich(
          TextSpan(children: markupSpans(block.text, styles.purport(lang))),
        );
      case PurportBlockType.quote:
        return Padding(
          padding: const EdgeInsets.only(left: Space.s8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.hairline, width: 2)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: Space.s16),
              child: Text.rich(
                TextSpan(
                  children: markupSpans(
                    block.text,
                    styles
                        .purport(lang)
                        .copyWith(
                          fontStyle: FontStyle.italic,
                          color: c.textSecondary,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      case PurportBlockType.sanskrit:
        return Text(
          stripMarkup(block.text),
          textAlign: TextAlign.center,
          style: styles.purportSanskrit,
        );
    }
  }
}
