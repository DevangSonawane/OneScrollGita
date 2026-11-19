import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../application/audio_providers.dart';
import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/search_providers.dart';
import '../../core/config/audio_config.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/written_content.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';
import 'summary_audio_bar.dart';

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
    final paragraphs = summary == null
        ? const <String>[]
        : [
            for (final p in summary.text.of(textLang).split(RegExp(r'\n\s*\n')))
              p.trim(),
          ];
    // English narration only: the docked player reads the English summary.
    final englishParagraphs = summary == null
        ? const <String>[]
        : [for (final p in summary.text.en.split(RegExp(r'\n\s*\n'))) p.trim()];
    final audio = AudioConfig.enabled
        ? ref.watch(audioControllerProvider)
        : const AudioUiState();
    final hearing =
        audio.kind == AudioKind.summary && audio.summaryChapter == chapter;
    final heard = hearing && textLang == 'en' ? audio.paragraph : -1;
    final bandDuration = Motion.of(context).crossFade;

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
                MediaQuery.paddingOf(context).bottom +
                    Space.s48 +
                    (AudioConfig.summaryAudio ? SummaryAudioBar.height : 0),
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
                        for (final (i, para) in paragraphs.indexed)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: Space.paragraph,
                            ),
                            // The paragraph being heard gets a soft band.
                            child: AnimatedContainer(
                              duration: bandDuration,
                              padding: i == heard
                                  ? const EdgeInsets.all(Space.s12)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: i == heard ? c.accentSoft : null,
                                borderRadius: BorderRadius.circular(
                                  Radii.input,
                                ),
                              ),
                              child: Text(
                                para,
                                locale: textLang == 'hi'
                                    ? const Locale('hi')
                                    : null,
                                style: ReadingStyles(
                                  c,
                                  scale,
                                ).purport(textLang),
                              ),
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
          if (AudioConfig.summaryAudio && englishParagraphs.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SummaryAudioBar(
                chapter: chapter,
                paragraphs: englishParagraphs,
              ),
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
