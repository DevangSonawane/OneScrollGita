import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/audio_providers.dart';
import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/audio/audio.dart';
import '../../domain/shravan.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';
import '../premium/paywall_screen.dart';
import '../premium/sadhak_art.dart';
import 'listen_widgets.dart';

/// The Shravan library: hero, continue listening, chapters 1 to 18.
class ListenLibraryScreen extends ConsumerWidget {
  const ListenLibraryScreen({super.key});

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    int chapter, {
    String? verseId,
  }) async {
    final audio = ref.read(audioControllerProvider.notifier);
    if (audio.locked) {
      await openShravanPaywall(context, reason: ListenFeature.recitation);
      return;
    }
    final s = ref.read(audioControllerProvider);
    final loaded =
        s.kind == AudioKind.chapter && s.queue?.chapter == chapter && s.active;
    if (loaded && verseId == null) {
      // Same chapter: keep its place, and make sure it is playing.
      if (!s.playing) await audio.toggle();
    } else {
      await audio.playChapter(chapter, verseId: verseId);
    }
    if (context.mounted) openPlayer(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final p = PremiumColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final index = ref.watch(chaptersIndexProvider).value;
    final lang = ref.watch(languageProvider);
    ref.watch(audioControllerProvider.select((s) => s.track?.verseId));
    final place = ref.read(audioControllerProvider.notifier).lastPlace;
    final heroHeight = top + PaywallMetrics.heroHeight;

    return Scaffold(
      body: NavHideOnScroll(
        child: ListView(
          padding: EdgeInsets.only(bottom: navBarInset(context)),
          children: [
            // The hero grows with large text instead of overflowing.
            Stack(
              children: [
                Positioned.fill(child: SadhakAmbient(height: heroHeight)),
                Container(
                  constraints: BoxConstraints(minHeight: heroHeight),
                  padding: EdgeInsets.only(
                    top: top + Space.s24,
                    bottom: Space.s24,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        container: true,
                        label: 'Shravan',
                        header: true,
                        excludeSemantics: true,
                        child: Shimmer(
                          base: c.accentText,
                          highlight: p.gold,
                          child: Text(
                            'श्रवण',
                            style: ReadingStyles(c, 1).sanskrit.copyWith(
                              fontSize: PaywallMetrics.titleSize,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'SHRAVAN',
                        style: ui.overline.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: Space.s12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s32,
                        ),
                        child: Text(
                          'The Gita, recited. Each shloka, then its meaning.',
                          textAlign: TextAlign.center,
                          style: ui.body(size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ref.read(audioCatalogProvider).isPlaceholder)
                    const _PreviewNote()
                  else if (ref.watch(
                    shravanEntitlementProvider.select(
                      (e) => !canListen(ListenFeature.recitation, e),
                    ),
                  ))
                    const _UnlockCard(),
                  if (place != null && index != null)
                    _ContinueCard(
                      chapter: place.chapter,
                      label: parseVerseId(place.verseId) == null
                          ? ''
                          : formatLabel(
                              parseVerseId(place.verseId)!.chapter,
                              parseVerseId(place.verseId)!.verseStart,
                              parseVerseId(place.verseId)!.verseEnd,
                            ),
                      title: index.chapter(place.chapter).title(lang),
                      onTap: () => _play(
                        context,
                        ref,
                        place.chapter,
                        verseId: place.verseId,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.readingSide,
                      Space.s24,
                      Space.readingSide,
                      Space.s8,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text('CHAPTERS', style: ui.overline),
                    ),
                  ),
                  if (index != null)
                    for (final ch in index.chapters)
                      _ChapterCard(
                        chapter: ch.number,
                        title: ch.title(lang),
                        verses: ch.verseCount,
                        onTap: () => _play(context, ref, ch.number),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewNote extends StatelessWidget {
  const _PreviewNote();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s8,
        Space.readingSide,
        0,
      ),
      padding: const EdgeInsets.all(Space.s12),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.input),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: IconSizes.small, color: c.textSecondary),
          const SizedBox(width: Space.s12),
          Expanded(
            child: Text(
              'Preview: silent stand-in audio with estimated lengths. The '
              'recordings arrive later.',
              style: UiStyles(c).body(size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown to listeners without Shravan: one calm invitation, no nagging.
class _UnlockCard extends StatelessWidget {
  const _UnlockCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s8,
        Space.readingSide,
        0,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(Radii.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openShravanPaywall(context),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.cardTop, p.cardBottom],
              ),
              border: Border.all(color: p.gold.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            padding: const EdgeInsets.all(Space.s16),
            child: Row(
              children: [
                const LotusMark(size: PaywallMetrics.lotusIcon),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Shravan',
                        style: ui.label(size: 16, color: c.accentText),
                      ),
                      Text(
                        'The whole audio library. One payment, yours to keep.',
                        style: ui.body(size: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevron_right,
                  size: IconSizes.small,
                  color: c.accentText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.chapter,
    required this.label,
    required this.title,
    required this.onTap,
  });

  final int chapter;
  final String label;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s16,
        Space.readingSide,
        0,
      ),
      child: Material(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.s16),
            child: Row(
              children: [
                ChapterNumeral(
                  chapter: chapter,
                  size: PlayerMetrics.chapterTile,
                ),
                const SizedBox(width: Space.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTINUE LISTENING',
                        style: ui.overline.copyWith(color: c.accentText),
                      ),
                      const SizedBox(height: Space.s4),
                      Text(
                        'Chapter $chapter · $label',
                        style: ui.label(size: 16, color: c.accentText),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ui.body(size: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s8),
                Container(
                  width: Touch.minTarget,
                  height: Touch.minTarget,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.play, color: c.onAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends ConsumerWidget {
  const _ChapterCard({
    required this.chapter,
    required this.title,
    required this.verses,
    required this.onTap,
  });

  final int chapter;
  final String title;
  final int verses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final info = ref.watch(chapterAudioInfoProvider(chapter)).value;
    final playingHere = ref.watch(
      audioControllerProvider.select(
        (s) =>
            s.kind == AudioKind.chapter &&
            s.queue?.chapter == chapter &&
            s.active,
      ),
    );
    final playing = ref.watch(audioControllerProvider.select((s) => s.playing));
    final length = info == null ? '' : ' · ${formatDuration(info.ms)}';
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Chapter $chapter, $title, $verses verses$length',
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.readingSide,
                  Space.s8 + 2,
                  Space.s8,
                  Space.s8 + 2,
                ),
                child: Row(
                  children: [
                    ChapterNumeral(
                      chapter: chapter,
                      size: PlayerMetrics.chapterTile,
                    ),
                    const SizedBox(width: Space.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ui.label(size: 15),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (playingHere) ...[
                                SoundWave(
                                  playing: playing,
                                  color: c.accentText,
                                ),
                                const SizedBox(width: Space.s8),
                              ],
                              Flexible(
                                child: Text(
                                  'Chapter $chapter · $verses verses$length',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ui.body(
                                    size: 12,
                                    color: c.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Outside the card's label, so a screen reader can reach it.
        Padding(
          padding: const EdgeInsets.only(right: Space.s16),
          child: _DownloadButton(chapter: chapter, bytes: info?.bytes),
        ),
      ],
    );
  }
}

/// Download, downloading (ring), downloaded (check). Pretend in the preview.
class _DownloadButton extends ConsumerWidget {
  const _DownloadButton({required this.chapter, required this.bytes});

  final int chapter;
  final int? bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final progress = ref.watch(
      audioDownloadsProvider.select((m) => m[chapter]),
    );
    final downloads = ref.read(audioDownloadsProvider.notifier);
    if (ref.read(audioControllerProvider.notifier).locked) {
      return IconButton(
        tooltip: 'Downloading is part of Shravan',
        onPressed: () =>
            openShravanPaywall(context, reason: ListenFeature.download),
        icon: Icon(
          LucideIcons.lock,
          size: IconSizes.small,
          color: c.textTertiary,
        ),
      );
    }
    if (progress != null && progress >= 1) {
      return IconButton(
        tooltip: 'Downloaded. Tap to remove',
        onPressed: () => downloads.delete(chapter),
        icon: Icon(LucideIcons.circle_check, color: c.accentText),
      );
    }
    if (progress != null) {
      return Semantics(
        container: true,
        label: 'Downloading, ${(progress * 100).round()} percent',
        child: SizedBox.square(
          dimension: Touch.minTarget,
          child: Padding(
            padding: const EdgeInsets.all(Space.s12),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: c.accent,
              backgroundColor: c.hairline,
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: bytes == null
          ? 'Download chapter'
          : 'Download chapter, ${formatBytes(bytes!)}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => downloads.download(chapter),
        radius: Touch.minTarget / 2,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Touch.minTarget + Space.s8,
            minHeight: Touch.minTarget,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.arrow_down_to_line,
                size: IconSizes.small,
                color: c.textSecondary,
              ),
              if (bytes != null)
                Text(
                  formatBytes(bytes!),
                  textScaler: TextScaler.noScaling,
                  style: ui.body(size: 11, color: c.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
