import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/audio_providers.dart';
import '../../application/premium_providers.dart';
import '../../domain/shravan.dart';
import '../premium/paywall_screen.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/audio/audio.dart';
import '../common/common_widgets.dart';

/// The chapter summary's own player, docked at the bottom of the summary
/// screen (PRD_v4 section 4). Starting it pauses the chapter; when it ends it
/// offers to resume the chapter.
class SummaryAudioBar extends ConsumerWidget {
  const SummaryAudioBar({
    super.key,
    required this.chapter,
    required this.paragraphs,
  });

  final int chapter;
  final List<String> paragraphs;

  /// Space the bar takes (for the page's bottom padding).
  static const height = PlayerMetrics.miniHeight + Space.s24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final s = ref.watch(audioControllerProvider);
    final audio = ref.read(audioControllerProvider.notifier);
    final mine = s.kind == AudioKind.summary && s.summaryChapter == chapter;
    final resume = mine && s.summaryEnded ? s.resumePlace : null;
    final preview = ref.read(audioCatalogProvider).isPlaceholder;
    final locked =
        !preview &&
        !canListen(
          ListenFeature.narration,
          ref.watch(shravanEntitlementProvider),
        );

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.readingSide,
            Space.s8,
            Space.readingSide,
            Space.s8,
          ),
          child: ContentWidth(
            child: !mine
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(Touch.minTarget),
                    ),
                    onPressed: () => locked
                        ? openShravanPaywall(
                            context,
                            reason: ListenFeature.narration,
                          )
                        : audio.playSummary(chapter, paragraphs),
                    icon: Icon(
                      locked ? LucideIcons.lock : LucideIcons.headphones,
                    ),
                    label: Text(
                      preview
                          ? 'Listen to this summary'
                          : 'Listen to the chapter narration',
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: s.playing ? 'Pause' : 'Play',
                            onPressed: audio.toggle,
                            icon: Icon(
                              s.playing ? LucideIcons.pause : LucideIcons.play,
                              color: c.accentText,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resume != null
                                      ? 'Summary finished'
                                      : preview
                                      ? 'Chapter $chapter summary'
                                      : 'Chapter $chapter narration',
                                  style: ui.label(size: 14),
                                ),
                                Text(
                                  '${formatDuration(s.positionMs)} / ${formatDuration(s.totalMs)}',
                                  style: ui.body(size: 12),
                                ),
                              ],
                            ),
                          ),
                          if (resume != null)
                            TextButton(
                              onPressed: audio.resumeChapter,
                              child: Text('Resume Chapter ${resume.chapter}'),
                            )
                          else
                            TextButton(
                              onPressed: audio.cycleSpeed,
                              child: Text(
                                '${s.speed == s.speed.roundToDouble() ? s.speed.toStringAsFixed(0) : s.speed}×',
                                semanticsLabel: 'Speed. Tap to change',
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Back 15 seconds',
                            onPressed: () => audio.skipSummary(-15000),
                            icon: Icon(
                              LucideIcons.rotate_ccw,
                              size: IconSizes.small,
                              color: c.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                activeTrackColor: c.accent,
                                inactiveTrackColor: c.hairline,
                                thumbColor: c.accent,
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                value: s.progress,
                                semanticFormatterCallback: (_) =>
                                    '${formatDuration(s.positionMs)} of ${formatDuration(s.totalMs)}',
                                onChanged: (_) {},
                                onChangeEnd: audio.seekFraction,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Forward 15 seconds',
                            onPressed: () => audio.skipSummary(15000),
                            icon: Icon(
                              LucideIcons.rotate_cw,
                              size: IconSizes.small,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
