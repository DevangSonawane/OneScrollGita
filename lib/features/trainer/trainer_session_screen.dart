import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/streak_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/copy_on_tap.dart' show showToast;
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/premium.dart';
import '../../domain/trainer/trainer.dart';
import '../common/common_widgets.dart';
import '../gita/share_card.dart';
import '../premium/paywall_screen.dart';
import '../premium/sadhak_art.dart';
import 'word_bank.dart';

/// Learning one verse through the five steps.
class TrainerLearnScreen extends ConsumerStatefulWidget {
  const TrainerLearnScreen({super.key, required this.verseId});

  final String verseId;

  @override
  ConsumerState<TrainerLearnScreen> createState() => _TrainerLearnScreenState();
}

class _TrainerLearnScreenState extends ConsumerState<TrainerLearnScreen> {
  late final StudyController _study = ref.read(studyControllerProvider);
  ShlokaState? _state;
  int _part = 0;
  int _reveals = 0;
  bool _repeated = false;
  bool _shown = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _study.startLearning(widget.verseId).then((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  void _resetStepView() {
    _part = 0;
    _reveals = 0;
    _shown = false;
  }

  Future<void> _finishStep() async {
    final s = _state!;
    final step = TrainerStep.of(s.step);
    if (step.byParts && shouldRepeatStep(_reveals) && !_repeated) {
      setState(() {
        _repeated = true;
        _resetStepView();
      });
      showToast(context, 'Let us go over this step once more.');
      return;
    }
    ref.read(readTrackerProvider.notifier).qualify(widget.verseId).ignore();
    final next = await _study.stepDone(s);
    if (!mounted) return;
    setState(() {
      _state = next;
      _repeated = false;
      _resetStepView();
      _done = next.status != ShlokaStatus.learning;
    });
  }

  Future<void> _missed() async {
    final next = await _study.reciteMissed(_state!);
    if (!mounted) return;
    setState(() {
      _state = next;
      _resetStepView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(entryProvider(widget.verseId)).value;
    final allowed = canUse(
      PremiumFeature.trainerAnyVerse,
      ref.watch(entitlementProvider),
      verseId: widget.verseId,
    );
    final s = _state;
    final title = entry == null ? 'Learn by heart' : 'Learn ${entry.label}';

    Widget body;
    if (!allowed) {
      body = _Locked(
        onUnlock: () =>
            openPaywall(context, reason: PremiumFeature.trainerAnyVerse),
      );
    } else if (entry == null || s == null) {
      body = const SizedBox.expand();
    } else if (_done) {
      body = _LearnedView(entry: entry, state: s);
    } else {
      body = _StepView(
        key: ValueKey('${s.step}-$_part-$_repeated'),
        entry: entry,
        step: TrainerStep.of(s.step),
        part: _part,
        shown: _shown,
        onReveal: () => _reveals++,
        onNextPart: () => setState(() => _part++),
        onShow: () => setState(() => _shown = true),
        onDone: _finishStep,
        onMissed: _missed,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: LucideBackButton(onPressed: () => context.pop()),
        actions: const [_ScriptToggle()],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: Motion.of(context).pageSwap,
          child: body,
        ),
      ),
    );
  }
}

/// Reviewing every due verse in turn: recite, show, mark.
class TrainerReviewScreen extends ConsumerStatefulWidget {
  const TrainerReviewScreen({super.key});

  @override
  ConsumerState<TrainerReviewScreen> createState() =>
      _TrainerReviewScreenState();
}

class _TrainerReviewScreenState extends ConsumerState<TrainerReviewScreen> {
  late final StudyController _study = ref.read(studyControllerProvider);
  List<ShlokaState>? _queue;
  int _i = 0;
  int _passed = 0;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    final entitlement = ref.read(entitlementProvider);
    _queue = [
      for (final s in ref.read(dueReviewsProvider))
        if (canUse(
          PremiumFeature.trainerReviews,
          entitlement,
          verseId: s.verseId,
        ))
          s,
    ];
  }

  Future<void> _mark(bool passed) async {
    final s = _queue![_i];
    ref.read(readTrackerProvider.notifier).qualify(s.verseId).ignore();
    await _study.reviewed(s, passed: passed);
    if (!mounted) return;
    setState(() {
      if (passed) _passed++;
      _i++;
      _shown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final queue = _queue ?? const [];
    final finished = _i >= queue.length;
    Widget body;
    if (finished) {
      body = _Centered(
        children: [
          const LotusMark(size: PaywallMetrics.lotusIcon * 1.4),
          const SizedBox(height: Space.s16),
          Text(
            queue.isEmpty ? 'Nothing to review' : 'Reviews done',
            style: ui.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.s8),
          Text(
            queue.isEmpty
                ? 'Verses you learn come back here just before you might '
                      'forget them.'
                : 'You remembered $_passed of ${queue.length}. Each verse '
                      'will come back at the right time.',
            style: ui.body(size: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.s24),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ],
      );
    } else {
      final s = queue[_i];
      final entry = ref.watch(entryProvider(s.verseId)).value;
      body = entry == null
          ? const SizedBox.expand()
          : _StepView(
              key: ValueKey('review-${s.verseId}'),
              entry: entry,
              step: TrainerStep.recite,
              part: 0,
              shown: _shown,
              review: true,
              progressLabel: 'Review ${_i + 1} of ${queue.length}',
              onReveal: () {},
              onNextPart: () {},
              onShow: () => setState(() => _shown = true),
              onDone: () => _mark(true),
              onMissed: () => _mark(false),
            );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        leading: LucideBackButton(onPressed: () => context.pop()),
        actions: const [_ScriptToggle()],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: Motion.of(context).pageSwap,
          child: body,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ScriptToggle extends ConsumerWidget {
  const _ScriptToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final devanagari = ref.watch(trainerDevanagariProvider);
    // A compact glyph button, so large text never crowds the app bar.
    return Semantics(
      button: true,
      label: devanagari ? 'Show transliteration' : 'Show Devanagari',
      excludeSemantics: true,
      child: InkResponse(
        onTap: () =>
            ref.read(trainerDevanagariProvider.notifier).set(!devanagari),
        radius: Touch.minTarget / 2,
        child: SizedBox.square(
          dimension: Touch.minTarget,
          child: Center(
            child: Text(
              devanagari ? 'Aa' : 'अ',
              textScaler: TextScaler.noScaling,
              style: devanagari
                  ? UiStyles(c).label(size: 17, color: c.accentText)
                  : ReadingStyles(c, 1).sanskrit.copyWith(
                      fontSize: 20,
                      height: 1.2,
                      color: c.accentText,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(Space.s32),
      child: ContentWidth(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
  );
}

class _Locked extends StatelessWidget {
  const _Locked({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return _Centered(
      children: [
        const LotusMark(size: PaywallMetrics.lotusIcon * 1.4),
        const SizedBox(height: Space.s16),
        Text(
          'Learn every shloka with Sadhak',
          style: ui.emptyTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.s8),
        Text(
          'Free: ${FreeLimits.trainerVerses.length} verses to try the trainer.',
          style: ui.body(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.s24),
        FilledButton(onPressed: onUnlock, child: const Text('See Sadhak')),
      ],
    );
  }
}

/// Five dots: done, current (wide), to come.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final duration = Motion.of(context).reduced
        ? AppDurations.instant
        : AppDurations.base;
    return Semantics(
      label: 'Step $current of 5',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            AnimatedContainer(
              duration: duration,
              curve: AppCurves.standard,
              margin: const EdgeInsets.symmetric(horizontal: Space.s4 / 2),
              width: i == current
                  ? TrainerMetrics.stepDotActive
                  : TrainerMetrics.stepDot,
              height: TrainerMetrics.stepDot,
              decoration: BoxDecoration(
                color: i <= current ? c.accent : c.hairline,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
        ],
      ),
    );
  }
}

/// One step of one verse. Words come from the dataset exactly; the trainer
/// only hides some of them.
class _StepView extends ConsumerStatefulWidget {
  const _StepView({
    super.key,
    required this.entry,
    required this.step,
    required this.part,
    required this.shown,
    required this.onReveal,
    required this.onNextPart,
    required this.onShow,
    required this.onDone,
    required this.onMissed,
    this.review = false,
    this.progressLabel,
  });

  final VerseEntry entry;
  final TrainerStep step;
  final int part;
  final bool shown;
  final bool review;
  final String? progressLabel;
  final VoidCallback onReveal;
  final VoidCallback onNextPart;
  final VoidCallback onShow;
  final VoidCallback onDone;
  final VoidCallback onMissed;

  @override
  ConsumerState<_StepView> createState() => _StepViewState();
}

class _StepViewState extends ConsumerState<_StepView> {
  final _revealed = <String>{};

  /// Steps 2 to 4 fill their blanks from a bank of 3D word buttons (owner,
  /// 2026-11-23), the same as the first-launch demo.
  WordBankController? _bank;
  String? _bankFor;

  bool get _usesBank =>
      !widget.review &&
      (widget.step == TrainerStep.someHidden ||
          widget.step == TrainerStep.mostHidden ||
          widget.step == TrainerStep.firstLetters);

  /// The hidden words of the lines on screen, in reading order.
  WordBankController? _bankFor0(List<String> lines, List<int> lineIdx) {
    if (!_usesBank) return null;
    final sig = '${lines.hashCode}|$lineIdx';
    if (_bankFor == sig && _bank != null) return _bank;
    final firstLetters = widget.step == TrainerStep.firstLetters;
    final slots = <BankSlot>[
      for (final li in lineIdx)
        for (final (i, w) in _hiddenOf(lines[li], li, firstLetters))
          (key: '$li-$i', word: w),
    ];
    _bankFor = sig;
    return _bank = slots.isEmpty
        ? null
        : WordBankController(widget.entry.id, slots);
  }

  List<(int, String)> _hiddenOf(String line, int li, bool firstLetters) {
    final words = wordsOf(line);
    final mask = hiddenMask(
      verseId: widget.entry.id,
      step: widget.step,
      part: li,
      words: words,
    );
    return [
      for (var i = 0; i < words.length; i++)
        if (mask[i] || (firstLetters && isHideable(words[i]))) (i, words[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final devanagari = ref.watch(trainerDevanagariProvider);
    final lang = ref.watch(languageProvider);
    final lines = devanagari
        ? widget.entry.sanskrit
        : widget.entry.transliteration;
    final parts = trainerParts(lines.length);
    final step = widget.step;
    final byParts = step.byParts && parts.length > 1;
    final lineIdx = byParts
        ? parts[widget.part.clamp(0, parts.length - 1)]
        : [for (var i = 0; i < lines.length; i++) i];
    final lastPart = !byParts || widget.part >= parts.length - 1;
    final wordStyle = readingStyles(
      context,
      ref,
    ).trainerWord(devanagari: devanagari);
    final bank = _bankFor0(lines, lineIdx);

    final prompt = switch (step) {
      TrainerStep.understand =>
        'Read the verse slowly, with its meaning and the word meanings.',
      TrainerStep.someHidden || TrainerStep.mostHidden =>
        'Tap the words below in order to fill the blanks. Tap a blank if '
            'you need help.',
      TrainerStep.firstLetters =>
        'Only first letters now. Tap the words below in order.',
      TrainerStep.recite =>
        widget.shown
            ? 'How did it go?'
            : 'Recite the whole verse aloud or in your mind, then check.',
    };

    final verse = Column(
      children: [
        for (final li in lineIdx)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s8),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.s8,
              runSpacing: Space.s4,
              children: [
                ..._lineWords(
                  lines[li],
                  li,
                  parts.indexWhere((p) => p.contains(li)),
                  wordStyle,
                  c,
                ),
              ],
            ),
          ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s16,
        Space.readingSide,
        Space.s32,
      ),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.review)
                Text(
                  widget.progressLabel ?? '',
                  textAlign: TextAlign.center,
                  style: ui.overline.copyWith(color: c.textSecondary),
                )
              else ...[
                _StepDots(current: step.number),
                const SizedBox(height: Space.s12),
                Text(
                  'Step ${step.number} of 5 · ${step.title}'
                  '${byParts ? ' · part ${widget.part + 1} of ${parts.length}' : ''}',
                  textAlign: TextAlign.center,
                  style: ui.overline.copyWith(color: c.textSecondary),
                ),
              ],
              const SizedBox(height: Space.s8),
              Text(
                prompt,
                textAlign: TextAlign.center,
                style: ui.body(size: 15),
              ),
              const SizedBox(height: Space.s24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s16,
                  vertical: Space.s24,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(Radii.card),
                  border: Border.all(color: c.hairline),
                ),
                child: verse,
              ),
              if (bank != null) ...[
                const SizedBox(height: Space.s24),
                AnimatedSwitcher(
                  duration: Motion.of(context).crossFade,
                  child: bank.done
                      ? Row(
                          key: const ValueKey('bankDone'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.circle_check,
                              color: PremiumColors.of(context).gold,
                            ),
                            const SizedBox(width: Space.s8),
                            Flexible(
                              child: Text(
                                'Every word in place',
                                style: ui.label(color: c.accentText),
                              ),
                            ),
                          ],
                        )
                      : WordBank(
                          key: const ValueKey('bank'),
                          controller: bank,
                          style: wordStyle.copyWith(
                            fontSize: TrainerMetrics.bankWord,
                            height: 1.3,
                          ),
                          onPick: (p) => setState(() {
                            // A wrong word counts like asking for help.
                            if (!bank.pick(p)) widget.onReveal();
                          }),
                        ),
                ),
              ],
              if (step == TrainerStep.understand) ...[
                const SizedBox(height: Space.s24),
                Text(
                  widget.entry.translation(lang),
                  style: readingStyles(context, ref).translation(lang),
                ),
                const SizedBox(height: Space.s16),
                _AllMeanings(entry: widget.entry),
              ],
              const SizedBox(height: Space.s32),
              ..._actions(step, lastPart),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _lineWords(
    String line,
    int lineIndex,
    int partIndex,
    TextStyle style,
    AppColors c,
  ) {
    final words = wordsOf(line);
    final step = widget.step;
    final showAll =
        step == TrainerStep.understand ||
        (step == TrainerStep.recite && widget.shown);
    final mask = showAll
        ? List<bool>.filled(words.length, false)
        : hiddenMask(
            verseId: widget.entry.id,
            step: step,
            // One mask per line, so the same verse always hides the same
            // words whichever part it is shown in.
            part: lineIndex,
            words: words,
          );
    final firstLetters = step == TrainerStep.firstLetters;
    return [
      for (var i = 0; i < words.length; i++)
        _Word(
          word: words[i],
          style: style,
          hidden:
              (mask[i] || (firstLetters && isHideable(words[i]))) &&
              !_revealed.contains('$lineIndex-$i') &&
              !(_bank?.filled.contains('$lineIndex-$i') ?? false),
          current: _bank?.next?.key == '$lineIndex-$i',
          firstLetterOnly: firstLetters,
          tappable: step != TrainerStep.recite,
          onReveal: () {
            setState(() {
              _revealed.add('$lineIndex-$i');
              _bank?.reveal('$lineIndex-$i');
            });
            widget.onReveal();
          },
        ),
    ];
  }

  List<Widget> _actions(TrainerStep step, bool lastPart) {
    final c = AppColors.of(context);
    final primary = FilledButton.styleFrom(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      minimumSize: const Size.fromHeight(PaywallMetrics.ctaHeight - 4),
    );
    if (step == TrainerStep.recite) {
      if (!widget.shown) {
        return [
          FilledButton(
            style: primary,
            onPressed: widget.onShow,
            child: const Text('Show the verse'),
          ),
        ];
      }
      return [
        FilledButton(
          style: primary,
          onPressed: widget.onDone,
          child: const Text('I got it'),
        ),
        const SizedBox(height: Space.s8),
        TextButton(onPressed: widget.onMissed, child: const Text('Not yet')),
      ];
    }
    return [
      FilledButton(
        style: primary,
        onPressed: lastPart ? widget.onDone : widget.onNextPart,
        child: Text(
          step == TrainerStep.understand
              ? 'I have read it'
              : lastPart
              ? 'Next step'
              : 'Next part',
        ),
      ),
    ];
  }
}

/// One word: shown, a blank (tap to reveal) or its first letter.
class _Word extends StatelessWidget {
  const _Word({
    required this.word,
    required this.style,
    required this.hidden,
    this.current = false,
    required this.firstLetterOnly,
    required this.tappable,
    required this.onReveal,
  });

  final String word;
  final TextStyle style;
  final bool hidden;

  /// The blank the next bank word goes into.
  final bool current;
  final bool firstLetterOnly;
  final bool tappable;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final duration = Motion.of(context).reduced
        ? AppDurations.instant
        : AppDurations.wordReveal;
    // Shown and hidden words share one box (same padding, same 2 px
    // underline, transparent when shown) so every word sits on one baseline.
    final first = hidden && firstLetterOnly ? firstLetterOf(word) : '';
    final rest = hidden ? word.substring(first.length) : '';
    final content = Container(
      key: ValueKey(hidden),
      constraints: const BoxConstraints(minWidth: TrainerMetrics.blankMinWidth),
      decoration: BoxDecoration(
        color: hidden && current ? c.accentSoft : null,
        borderRadius: hidden && current
            ? const BorderRadius.vertical(top: Radius.circular(Radii.chip))
            : null,
        border: Border(
          bottom: BorderSide(
            color: hidden ? c.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: hidden
          ? Text.rich(
              TextSpan(
                children: [
                  if (first.isNotEmpty)
                    TextSpan(
                      text: first,
                      style: style.copyWith(color: c.accentText),
                    ),
                  // The rest keeps its width but is invisible: the shape of
                  // the word stays, the word does not.
                  TextSpan(
                    text: rest,
                    style: style.copyWith(color: Colors.transparent),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            )
          : Text(word, style: style, textAlign: TextAlign.center),
    );
    final child = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Touch.minTarget),
      child: Align(
        widthFactor: 1,
        child: AnimatedSwitcher(duration: duration, child: content),
      ),
    );
    if (!hidden || !tappable) {
      return Semantics(label: hidden ? 'Hidden word' : null, child: child);
    }
    return Semantics(
      button: true,
      label: 'Hidden word. Tap to show',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onReveal,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}

/// Every word meaning of the verse, always open (step 1).
class _AllMeanings extends ConsumerWidget {
  const _AllMeanings({required this.entry});

  final VerseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final styles = readingStyles(context, ref);
    final lang = ref.watch(languageProvider);
    final meanings = entry.wordMeaningsFor(lang);
    final mlang = meanings.isEnglishFallback ? 'en' : lang;
    if (meanings.pairs.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(Space.s16),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WORD MEANINGS', style: ui.overline),
          const SizedBox(height: Space.s8),
          for (final m in meanings.pairs)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: m.word,
                      style: styles.wordMeaningWord(
                        devanagari: RegExp(r'[ऀ-ॿ]').hasMatch(m.word),
                      ),
                    ),
                    TextSpan(
                      text: ' — ${m.meaning}',
                      style: styles.wordMeaningText(mlang),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The verse is learned: a quiet celebration and the first review date.
class _LearnedView extends ConsumerWidget {
  const _LearnedView({required this.entry, required this.state});

  final VerseEntry entry;
  final ShlokaState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    return _Centered(
      children: [
        const LotusBloom(),
        const SizedBox(height: Space.s16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            '${entry.label} is learned',
            style: ui.title,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Space.s8),
        Text(
          'It will come back for a short review tomorrow, then less and less '
          'often.',
          style: ui.body(size: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.s24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              minimumSize: const Size.fromHeight(PaywallMetrics.ctaHeight - 4),
            ),
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ),
        const SizedBox(height: Space.s8),
        TextButton.icon(
          onPressed: () async {
            final format = await pickShareFormat(context);
            if (format == null || !context.mounted) return;
            try {
              await shareVerse(context, entry, lang, format: format);
            } catch (_) {
              if (context.mounted) {
                showToast(context, 'Could not share. Please try again.');
              }
            }
          },
          icon: const Icon(LucideIcons.share_2, size: IconSizes.small),
          label: const Text('Share this verse'),
        ),
      ],
    );
  }
}
