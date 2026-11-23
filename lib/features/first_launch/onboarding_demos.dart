import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/audio_providers.dart';
import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/trainer/trainer.dart';
import '../trainer/word_bank.dart';

/// The verses the first-launch demos show (owner, 2026-11-23). All text
/// comes from the dataset as it is.
abstract final class DemoVerses {
  /// The scrolling demo: a few verses of chapter 2 from here.
  static const scrollFrom = 'bg-02-020';
  static const scrollCount = 4;

  /// The Sadhak trainer demo.
  static const trainer = 'bg-02-047';
}

/// A small gold pill naming the plan a feature belongs to.
class PlanBadge extends StatelessWidget {
  const PlanBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = PremiumColors.of(context);
    final c = AppColors.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s12,
          vertical: Space.s4,
        ),
        decoration: BoxDecoration(
          color: p.goldSoft,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: p.gold.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: IconSizes.small - 6,
              color: p.gold,
            ),
            const SizedBox(width: Space.s4),
            Text(
              label,
              style: UiStyles(c).overline.copyWith(color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardBox(AppColors c) => BoxDecoration(
  color: c.surface,
  borderRadius: BorderRadius.circular(Radii.card),
  border: Border.all(color: c.hairline),
  boxShadow: [
    BoxShadow(
      color: c.shadow,
      blurRadius: Space.s24,
      offset: const Offset(0, Space.s8),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Scrolling: a few real verses in a card that swipes up like the reader.

class ScrollDemo extends ConsumerStatefulWidget {
  const ScrollDemo({super.key});

  static const cardKey = ValueKey('scrollDemoCard');

  @override
  ConsumerState<ScrollDemo> createState() => _ScrollDemoState();
}

class _ScrollDemoState extends ConsumerState<ScrollDemo> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(settingsProvider.select((s) => s.languageCode));
    final all = ref.watch(chapterEntriesProvider(2)).value;
    final from = all?.indexWhere((e) => e.id == DemoVerses.scrollFrom) ?? -1;
    final entries = all == null
        ? const <VerseEntry>[]
        : all.skip(from < 0 ? 0 : from).take(DemoVerses.scrollCount).toList();
    final motion = Motion.of(context);

    final card = Container(
      key: ScrollDemo.cardKey,
      height: OnboardingMetrics.demoCard,
      decoration: _cardBox(c),
      clipBehavior: Clip.antiAlias,
      child: entries.isEmpty
          ? const SizedBox.shrink()
          : Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: entries.length,
                  onPageChanged: (i) {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _page = i);
                  },
                  itemBuilder: (context, i) =>
                      _DemoVersePage(entry: entries[i], lang: lang),
                ),
                // Where you are, as a column of dots on the right.
                Positioned(
                  right: Space.s12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          AnimatedContainer(
                            duration: motion.crossFade,
                            margin: const EdgeInsets.symmetric(
                              vertical: Space.s4 / 2,
                            ),
                            width: TrainerMetrics.stepDot - 2,
                            height: i == _page
                                ? TrainerMetrics.stepDotActive - 4
                                : TrainerMetrics.stepDot - 2,
                            decoration: BoxDecoration(
                              color: i == _page ? c.accent : c.hairline,
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: Space.s12),
        // "Swipe up" until the first swipe; it keeps its space so nothing
        // jumps when it fades.
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _page == 0 ? 1 : 0,
            duration: motion.crossFade,
            child: _SwipeHint(label: 'Swipe up on the card', ui: ui, c: c),
          ),
        ),
      ],
    );
  }
}

class _DemoVersePage extends StatelessWidget {
  const _DemoVersePage({required this.entry, required this.lang});

  final VerseEntry entry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final reading = ReadingStyles(c, 0.9);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.s24,
        Space.s24,
        Space.s32,
        Space.s24,
      ),
      // Large text shrinks to fit the card instead of overflowing it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - Space.s48 * 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
              const SizedBox(height: Space.s16),
              for (final line in entry.sanskrit)
                Text(
                  line,
                  textAlign: TextAlign.center,
                  style: reading.sanskrit,
                ),
              const SizedBox(height: Space.s16),
              Text(
                entry.translation(lang),
                textAlign: TextAlign.center,
                style: reading.translation(lang),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint({required this.label, required this.ui, required this.c});

  final String label;
  final UiStyles ui;
  final AppColors c;

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: OnboardingMetrics.hintBounce,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).reduced) {
      _a.stop();
    } else if (!_a.isAnimating) {
      _a.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -Space.s8 * Curves.easeInOut.transform(_a.value)),
      child: child,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.chevrons_up,
          size: IconSizes.regular,
          color: widget.c.accentText,
        ),
        Text(
          widget.label,
          style: widget.ui.label(size: 13, color: widget.c.accentText),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Sadhak: fill in the hidden words of 2.47 from a bank of 3D word buttons.

class TrainerDemo extends ConsumerStatefulWidget {
  const TrainerDemo({super.key});

  @override
  ConsumerState<TrainerDemo> createState() => _TrainerDemoState();
}

class _TrainerDemoState extends ConsumerState<TrainerDemo> {
  WordBankController? _bank;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final p = PremiumColors.of(context);
    final motion = Motion.of(context);
    final entry = ref.watch(entryProvider(DemoVerses.trainer)).value;
    if (entry == null) {
      return const SizedBox(height: OnboardingMetrics.demoCard);
    }
    final style = ReadingStyles(c, 1).transliteration.copyWith(
      fontSize: ReadingType.transliteration,
      height: 1.5,
    );

    // The trainer's own choice of hidden words (step 2, about 30%).
    final lines = <List<String>>[];
    final slots = <BankSlot>[];
    for (var l = 0; l < entry.transliteration.length; l++) {
      final words = wordsOf(entry.transliteration[l]);
      final mask = hiddenMask(
        verseId: entry.id,
        step: TrainerStep.someHidden,
        part: l,
        words: words,
      );
      lines.add(words);
      for (var w = 0; w < words.length; w++) {
        if (mask[w]) slots.add((key: '$l-$w', word: words[w]));
      }
    }
    final bank = _bank ??= WordBankController(entry.id, slots);
    final keys = {for (final s in slots) s.key};

    return Container(
      padding: const EdgeInsets.all(Space.s16),
      decoration: _cardBox(c),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
          const SizedBox(height: Space.s12),
          for (var l = 0; l < lines.length; l++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s4),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: Space.s4 + 2,
                runSpacing: Space.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var w = 0; w < lines[l].length; w++)
                    if (keys.contains('$l-$w'))
                      _Blank(
                        word: lines[l][w],
                        filled: bank.filled.contains('$l-$w'),
                        current: bank.next?.key == '$l-$w',
                        style: style,
                      )
                    else
                      Text(lines[l][w], style: style),
                ],
              ),
            ),
          const SizedBox(height: Space.s16),
          Divider(height: 1, color: c.hairline),
          const SizedBox(height: Space.s16),
          AnimatedSwitcher(
            duration: motion.pageSwap,
            child: bank.done
                ? Padding(
                    key: const ValueKey('done'),
                    padding: const EdgeInsets.symmetric(vertical: Space.s8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.circle_check,
                          color: p.gold,
                          size: IconSizes.regular,
                        ),
                        const SizedBox(width: Space.s8),
                        Flexible(
                          child: Text(
                            'Every word in place',
                            style: ui.label(color: c.accentText),
                          ),
                        ),
                      ],
                    ),
                  )
                : WordBank(
                    key: const ValueKey('bank'),
                    controller: bank,
                    style: ui
                        .label(size: 15)
                        .copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                    onPick: (pos) => setState(() {
                      if (bank.pick(pos) && bank.done) {
                        unawaited(HapticFeedback.mediumImpact());
                      }
                    }),
                  ),
          ),
          const SizedBox(height: Space.s12),
          Text(
            bank.done
                ? 'That is how the trainer works, verse by verse.'
                : 'Tap the words in order · ${bank.filled.length} of '
                      '${slots.length}',
            textAlign: TextAlign.center,
            style: ui.body(size: 13),
          ),
        ],
      ),
    );
  }
}

/// A blank in the verse: an empty underline, the next one glowing, or the
/// word once it is placed.
class _Blank extends StatelessWidget {
  const _Blank({
    required this.word,
    required this.filled,
    required this.current,
    required this.style,
  });

  final String word;
  final bool filled;
  final bool current;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final motion = Motion.of(context);
    return Semantics(
      label: filled ? word : 'Blank',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: motion.crossFade,
        padding: const EdgeInsets.symmetric(horizontal: Space.s4),
        decoration: BoxDecoration(
          color: current ? c.accentSoft : null,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border(
            bottom: BorderSide(
              color: filled || current ? c.accent : c.textTertiary,
              width: 2,
            ),
          ),
        ),
        // Keeps the word's width so nothing jumps when it is placed.
        child: AnimatedOpacity(
          opacity: filled ? 1 : 0,
          duration: motion.crossFade,
          child: Text(
            word,
            style: style.copyWith(
              color: c.accentText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shravan: hear 1.1, Sanskrit then translation.

class ListenDemo extends ConsumerWidget {
  const ListenDemo({super.key});

  static const playKey = ValueKey('listenDemoPlay');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final p = PremiumColors.of(context);
    final motion = Motion.of(context);
    final preview = ref.watch(versePreviewProvider);
    final entry = ref.watch(entryProvider(previewVerseId)).value;
    final reading = ReadingStyles(c, 0.95);

    final status = switch (preview.status) {
      VersePreviewStatus.idle => 'Tap to listen',
      VersePreviewStatus.loading => 'Sanskrit, then the translation',
      VersePreviewStatus.playing => 'Sanskrit, then the translation',
      VersePreviewStatus.paused => 'Paused',
      VersePreviewStatus.done => 'Tap to hear it again',
      VersePreviewStatus.failed =>
        'Could not play. Check your internet connection and try again.',
    };

    return Container(
      padding: const EdgeInsets.all(Space.s24),
      decoration: _cardBox(c),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry != null) ...[
            ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
            const SizedBox(height: Space.s16),
            for (final line in entry.sanskrit)
              Text(line, textAlign: TextAlign.center, style: reading.sanskrit),
            const SizedBox(height: Space.s24),
          ],
          Pressable(
            key: playKey,
            onTap: () {
              unawaited(HapticFeedback.lightImpact());
              ref.read(versePreviewProvider.notifier).toggle();
            },
            semanticLabel: preview.playing ? 'Pause' : 'Play verse 1.1',
            child: SizedBox.square(
              dimension: OnboardingMetrics.playButton,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: preview.status == VersePreviewStatus.loading
                          ? null
                          : preview.progress,
                      strokeWidth: OnboardingMetrics.playRing,
                      color: p.gold,
                      backgroundColor: c.hairline,
                    ),
                  ),
                  AnimatedContainer(
                    duration: motion.crossFade,
                    width: OnboardingMetrics.playButton - Space.s16,
                    height: OnboardingMetrics.playButton - Space.s16,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: p.glow,
                          blurRadius: preview.playing
                              ? PaywallMetrics.glowBlur
                              : Space.s12,
                        ),
                      ],
                    ),
                    child: Icon(
                      preview.playing ? LucideIcons.pause : LucideIcons.play,
                      color: c.onAccent,
                      size: IconSizes.large,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.s12),
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: motion.crossFade,
              child: Text(
                status,
                key: ValueKey(preview.status),
                textAlign: TextAlign.center,
                style: ui.body(
                  size: 14,
                  color: preview.status == VersePreviewStatus.failed
                      ? c.danger
                      : c.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
