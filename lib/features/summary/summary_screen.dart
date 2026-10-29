import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/search_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/written_content.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';

/// Chapter summary page (PRD_v2 section 9). Written content, always
/// labelled as not part of Srila Prabhupada's text.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.chapter});

  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final scale = ref.watch(readingScaleProvider);
    final summaries = ref.watch(summariesProvider);
    final index = ref.watch(chaptersIndexProvider).value;
    final top = MediaQuery.paddingOf(context).top;
    final summary = summaries.value?[chapter];
    final textLang = lang == 'hi' && (summary?.text.hi?.isNotEmpty ?? false)
        ? 'hi'
        : 'en';

    return Scaffold(
      body: Stack(
        children: [
          if (summaries.hasError)
            LoadError(
              error: summaries.error,
              onRetry: () => ref.invalidate(summariesProvider),
            )
          else
            ListView(
              padding: EdgeInsets.fromLTRB(
                0,
                top + 72,
                0,
                MediaQuery.paddingOf(context).bottom + Space.s48,
              ),
              children: [
                ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.readingSide,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('CHAPTER $chapter', style: ui.overline),
                        const SizedBox(height: Space.s8),
                        if (index != null)
                          Semantics(
                            header: true,
                            child: Text(
                              index.chapter(chapter).title(lang),
                              style: ui.title,
                            ),
                          ),
                        const SizedBox(height: Space.s16),
                        const SummaryLabel(),
                        const SizedBox(height: Space.s24),
                        if (summary != null)
                          for (final para
                              in summary.text
                                  .of(textLang)
                                  .split(RegExp(r'\n\s*\n')))
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Space.paragraph,
                              ),
                              child: Text(
                                para.trim(),
                                locale: textLang == 'hi'
                                    ? const Locale('hi')
                                    : null,
                                style: ReadingStyles(
                                  c,
                                  scale,
                                ).purport(textLang),
                              ),
                            ),
                        const SizedBox(height: Space.s24),
                        Center(
                          child: FilledButton(
                            onPressed: () => openInReader(
                              context,
                              formatVerseId(chapter, 1),
                            ),
                            child: const Text('Start chapter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          Positioned(
            top: top + Space.s8,
            left: Space.s16,
            child: GlassLayer(
              strength: GlassStrength.light,
              child: GlassIconButton(
                icon: LucideIcons.chevron_left,
                semanticLabel: 'Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Summary. Not part of Srila Prabhupada's text."
class SummaryLabel extends StatelessWidget {
  const SummaryLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s8,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Text(summaryLabel, style: UiStyles(c).body(size: 13)),
    );
  }
}

void openSummary(BuildContext context, int chapter) =>
    context.push('/gita/summary/$chapter');
