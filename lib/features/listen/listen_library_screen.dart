import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/audio_providers.dart';
import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/audio/audio.dart';
import '../../domain/shravan.dart';
import '../../domain/verse_navigation.dart';
import '../common/common_widgets.dart';
import '../premium/paywall_screen.dart';
import '../premium/sadhak_art.dart';
import 'listen_widgets.dart';

/// One chapter as the deck and the tiles show it.
typedef _ChapterItem = ({int chapter, String title, int verses});

/// The Shravan library: a fanned deck of chapters to swipe through, then
/// every chapter as a tile.
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
    final top = MediaQuery.paddingOf(context).top;
    final index = ref.watch(chaptersIndexProvider).value;
    final lang = ref.watch(languageProvider);
    ref.watch(audioControllerProvider.select((s) => s.track?.verseId));
    final place = ref.read(audioControllerProvider.notifier).lastPlace;
    final placeRef = place == null ? null : parseVerseId(place.verseId);
    final items = <_ChapterItem>[
      if (index != null)
        for (final ch in index.chapters)
          (chapter: ch.number, title: ch.title(lang), verses: ch.verseCount),
    ];

    return Scaffold(
      body: NavHideOnScroll(
        child: ListView(
          padding: EdgeInsets.only(
            top: top + Space.s16,
            bottom: navBarInset(context),
          ),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  if (ref.read(audioCatalogProvider).isPlaceholder)
                    const _PreviewNote()
                  else if (ref.watch(
                    shravanEntitlementProvider.select(
                      (e) => !canListen(ListenFeature.recitation, e),
                    ),
                  ))
                    const _UnlockCard(),
                  if (items.isNotEmpty)
                    _ChapterDeck(
                      items: items,
                      initial: place == null ? 0 : place.chapter - 1,
                      resume: place == null || placeRef == null
                          ? null
                          : (
                              chapter: place.chapter,
                              label: formatLabel(
                                placeRef.chapter,
                                placeRef.verseStart,
                                placeRef.verseEnd,
                              ),
                            ),
                      onPlay: (chapter, {resume = false}) => _play(
                        context,
                        ref,
                        chapter,
                        verseId: resume ? place?.verseId : null,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.readingSide,
                      Space.s24,
                      Space.readingSide,
                      Space.s12,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text('All chapters', style: ui.emptyTitle),
                    ),
                  ),
                ],
              ),
            ),
            if (items.isNotEmpty)
              _ChapterTiles(
                items: items,
                onPlay: (chapter) => _play(context, ref, chapter),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        0,
        Space.readingSide,
        Space.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('Shravan', style: ui.title),
                ),
                Text(
                  'The Gita, recited. Each shloka, then its meaning.',
                  style: ui.body(size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chapters as a fanned stack of cards. Swipe right to send the front card
/// away and bring up the next; swipe left to bring the last one back.
class _ChapterDeck extends StatefulWidget {
  const _ChapterDeck({
    required this.items,
    required this.initial,
    required this.resume,
    required this.onPlay,
  });

  final List<_ChapterItem> items;
  final int initial;
  final ({int chapter, String label})? resume;
  final void Function(int chapter, {bool resume}) onPlay;

  @override
  State<_ChapterDeck> createState() => _ChapterDeckState();
}

class _ChapterDeckState extends State<_ChapterDeck>
    with SingleTickerProviderStateMixin {
  late final _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.initial.clamp(0, widget.items.length - 1).toDouble(),
  );

  int get _last => widget.items.length - 1;

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d, double width) {
    _pos.stop();
    _pos.value = (_pos.value + d.primaryDelta! / width).clamp(
      0.0,
      _last.toDouble(),
    );
  }

  void _release(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final p = _pos.value;
    final target = v > ListenMetrics.deckFlick
        ? p.floor() + 1
        : v < -ListenMetrics.deckFlick
        ? p.ceil() - 1
        : p.round();
    _goTo(target);
  }

  void _goTo(int target) {
    final t = target.clamp(0, _last).toDouble();
    final motion = Motion.of(context);
    if (motion.reduced) {
      _pos.value = t;
    } else {
      _pos.animateTo(t, duration: motion.pageSwap, curve: AppCurves.standard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(
          box.maxWidth * ListenMetrics.deckShare,
          ListenMetrics.deckMaxWidth,
        );
        final h = w * ListenMetrics.deckAspect;
        return AnimatedBuilder(
          animation: _pos,
          builder: (context, _) {
            final p = _pos.value;
            final front = p.round();
            final first = p.floor();
            final cards = <Widget>[];
            // Back to front, so the front card paints last.
            for (
              var i = math.min(_last, first + ListenMetrics.deckBehind);
              i >= first;
              i--
            ) {
              cards.add(_placed(i, i - p, w, h, i == front));
            }
            return Column(
              children: [
                Semantics(
                  container: true,
                  label: 'Chapters',
                  value: 'Chapter ${front + 1} of ${widget.items.length}',
                  increasedValue: front < _last
                      ? 'Chapter ${front + 2} of ${widget.items.length}'
                      : null,
                  decreasedValue: front > 0
                      ? 'Chapter $front of ${widget.items.length}'
                      : null,
                  onIncrease: front < _last ? () => _goTo(front + 1) : null,
                  onDecrease: front > 0 ? () => _goTo(front - 1) : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) => _drag(d, w),
                    onHorizontalDragEnd: _release,
                    child: SizedBox(
                      height: h + Space.s48,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: cards,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.s8),
                _DeckDots(count: widget.items.length, index: front),
              ],
            );
          },
        );
      },
    );
  }

  /// Puts card [i] at offset [d] from the front (negative: leaving).
  Widget _placed(int i, double d, double w, double h, bool isFront) {
    double dx, dy = 0, turn, scale = 1, opacity = 1;
    if (d <= 0) {
      final t = -d;
      dx = t * w * ListenMetrics.deckThrow;
      turn = ListenMetrics.deckTilt + t * ListenMetrics.deckThrowTilt;
    } else {
      dx = -d * ListenMetrics.deckFanShift;
      dy = d * ListenMetrics.deckFanDrop;
      turn = ListenMetrics.deckTilt - d * ListenMetrics.deckFanTilt;
      scale = 1 - d * ListenMetrics.deckFanScale;
      opacity = (ListenMetrics.deckBehind - d + 1).clamp(0.0, 1.0);
    }
    final item = widget.items[i];
    final resume = widget.resume?.chapter == item.chapter
        ? widget.resume!.label
        : null;
    Widget card = SizedBox(
      width: w,
      height: h,
      child: _DeckCard(
        item: item,
        resume: resume,
        onTap: () => widget.onPlay(item.chapter, resume: resume != null),
      ),
    );
    if (!isFront) {
      card = IgnorePointer(child: ExcludeSemantics(child: card));
    }
    return Transform.translate(
      key: ValueKey(item.chapter),
      // The fan peeks out on the left, so the stack sits a little right.
      offset: Offset(dx + ListenMetrics.deckCentre, dy),
      child: Transform.rotate(
        angle: turn,
        child: Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: card),
        ),
      ),
    );
  }
}

class _DeckCard extends ConsumerWidget {
  const _DeckCard({
    required this.item,
    required this.resume,
    required this.onTap,
  });

  final _ChapterItem item;

  /// The verse to continue from, when this is the last chapter heard.
  final String? resume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final info = ref.watch(chapterAudioInfoProvider(item.chapter)).value;
    final length = info == null ? '' : ' · ${formatDuration(info.ms)}';
    final playingHere = ref.watch(
      audioControllerProvider.select(
        (s) =>
            s.kind == AudioKind.chapter &&
            s.queue?.chapter == item.chapter &&
            s.active,
      ),
    );
    final playing = ref.watch(audioControllerProvider.select((s) => s.playing));
    final action = resume == null ? 'Play chapter' : 'Continue $resume';
    final lang = ref.watch(languageProvider);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: ListenMetrics.maxTextScale,
      child: Semantics(
        container: true,
        button: true,
        label:
            'Chapter ${item.chapter}, ${item.title}, ${item.verses} verses'
            '$length. $action',
        excludeSemantics: true,
        child: ChapterArt(
          chapter: item.chapter,
          radius: Radii.sheet,
          numeralSize: ListenMetrics.numeral,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(Space.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The chapter's name in the reading language, then its
                    // number, like a song and its artist.
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: chapterNameStyle(
                          ui.emptyTitle.copyWith(
                            fontSize: ListenMetrics.cardTitle,
                            fontWeight: FontWeight.w700,
                            color: ListenArtColors.onArt,
                          ),
                          lang,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.s4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chapterLabel(item.chapter, lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: chapterNameStyle(
                              ui.label(
                                size: 16,
                                color: ListenArtColors.onArtSoft,
                              ),
                              lang,
                            ),
                          ),
                        ),
                        if (playingHere) ...[
                          const SizedBox(width: Space.s8),
                          SoundWave(
                            playing: playing,
                            color: ListenArtColors.onArt,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    _PlayPill(label: resume == null ? 'Play' : 'Continue'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark pill with a white play disc at the foot of a deck card.
class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = UiStyles(AppColors.of(context));
    return Container(
      constraints: const BoxConstraints(minHeight: Touch.minTarget),
      padding: const EdgeInsets.fromLTRB(
        Space.s4,
        Space.s4,
        Space.s16,
        Space.s4,
      ),
      decoration: BoxDecoration(
        color: ListenArtColors.pill,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: ListenArtColors.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ListenMetrics.playDisc,
            height: ListenMetrics.playDisc,
            decoration: const BoxDecoration(
              color: ListenArtColors.disc,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.play,
              size: IconSizes.small,
              color: ListenArtColors.discIcon,
            ),
          ),
          const SizedBox(width: Space.s12),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ui.label(color: ListenArtColors.onArt),
            ),
          ),
        ],
      ),
    );
  }
}

/// A short window of dots under the deck; the current one is a pill.
class _DeckDots extends StatelessWidget {
  const _DeckDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const shown = ListenMetrics.dotsShown;
    final start = count <= shown
        ? 0
        : (index - shown ~/ 2).clamp(0, count - shown);
    final end = math.min(count, start + shown);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = start; i < end; i++)
            AnimatedContainer(
              duration: Motion.of(context).crossFade,
              margin: const EdgeInsets.symmetric(horizontal: Space.s4 / 2),
              width: i == index ? ListenMetrics.dotActive : ListenMetrics.dot,
              height: ListenMetrics.dot,
              decoration: BoxDecoration(
                color: i == index ? c.accent : c.hairline,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
        ],
      ),
    );
  }
}

/// Every chapter as a rounded tile in one sideways row.
class _ChapterTiles extends StatelessWidget {
  const _ChapterTiles({required this.items, required this.onPlay});

  final List<_ChapterItem> items;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: ListenMetrics.maxTextScale,
      child: SizedBox(
        height: ListenMetrics.tileHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: Space.s12),
          itemBuilder: (context, i) => _ChapterTile(
            item: items[i],
            onTap: () => onPlay(items[i].chapter),
          ),
        ),
      ),
    );
  }
}

class _ChapterTile extends ConsumerWidget {
  const _ChapterTile({required this.item, required this.onTap});

  final _ChapterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final info = ref.watch(chapterAudioInfoProvider(item.chapter)).value;
    final length = info == null ? '' : ' · ${formatDuration(info.ms)}';
    final playingHere = ref.watch(
      audioControllerProvider.select(
        (s) =>
            s.kind == AudioKind.chapter &&
            s.queue?.chapter == item.chapter &&
            s.active,
      ),
    );
    final playing = ref.watch(audioControllerProvider.select((s) => s.playing));
    final lang = ref.watch(languageProvider);
    return SizedBox(
      width: ListenMetrics.tileWidth,
      child: ChapterArt(
        chapter: item.chapter,
        radius: Radii.card,
        numeralSize: ListenMetrics.tileNumeral,
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                container: true,
                button: true,
                label:
                    'Chapter ${item.chapter}, ${item.title}, '
                    '${item.verses} verses$length',
                excludeSemantics: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(Space.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (playingHere)
                            SoundWave(
                              playing: playing,
                              color: ListenArtColors.onArt,
                            ),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: chapterNameStyle(
                              ui
                                  .label(
                                    size: ListenMetrics.tileTitle,
                                    color: ListenArtColors.onArt,
                                  )
                                  .copyWith(fontWeight: FontWeight.w700),
                              lang,
                            ),
                          ),
                          const SizedBox(height: Space.s8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chapterLabel(item.chapter, lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: chapterNameStyle(
                                    ui.label(
                                      size: 13,
                                      color: ListenArtColors.onArtSoft,
                                    ),
                                    lang,
                                  ),
                                ),
                              ),
                              // "Play →" pill, like the reference's "Open →".
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Space.s8,
                                  vertical: Space.s4,
                                ),
                                decoration: BoxDecoration(
                                  color: ListenArtColors.pill,
                                  borderRadius: BorderRadius.circular(
                                    Radii.pill,
                                  ),
                                  border: Border.all(
                                    color: ListenArtColors.pillBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Play',
                                      style: ui.label(
                                        size: 12,
                                        color: ListenArtColors.onArt,
                                      ),
                                    ),
                                    const SizedBox(width: Space.s4),
                                    const Icon(
                                      LucideIcons.arrow_right,
                                      size: IconSizes.small - 6,
                                      color: ListenArtColors.onArt,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
