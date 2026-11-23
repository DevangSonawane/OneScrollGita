import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/audio_providers.dart';
import '../../application/auth_providers.dart';
import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/streak_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/read_rule.dart';
import '../common/common_widgets.dart';
import '../common/qualifying_read.dart';
import '../premium/sadhak_art.dart';
import 'onboarding_demos.dart';
import 'onboarding_parts.dart';

/// Guided first launch (owner, 2026-11-23): the app in numbers, the first
/// verse lighting the streak, swiping through verses, the Sadhak trainer,
/// Shravan listening (1.1), then the account step (PRD_v9) when this build
/// has accounts. No Skip: every step has one clear action and Back.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  /// Steps shown in the dots: these five, plus sign-up when available.
  static const ownSteps = 5;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Step { intro, verse, scroll, sadhak, shravan }

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// The translation language follows the phone (Hindi phones get Hindi);
  /// it can be changed in Profile.
  late final String _lang =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'hi'
      ? 'hi'
      : 'en';
  _Step _step = _Step.intro;
  bool _forward = true;
  String? _firstVerseId;
  bool _streakLit = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    // Keep the 1.1 preview alive through first launch and load it now, so
    // the Shravan step plays at once.
    ref.listenManual(versePreviewProvider, (_, _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(versePreviewProvider.notifier).prepare());
    });
  }

  void _go(_Step s) {
    if (_step == _Step.shravan) {
      unawaited(ref.read(versePreviewProvider.notifier).pause());
    }
    setState(() {
      _forward = s.index > _step.index;
      _step = s;
    });
  }

  void _next() => _go(_Step.values[_step.index + 1]);

  void _back() {
    if (_step.index == 0 || _finishing) return;
    _go(_Step.values[_step.index - 1]);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    unawaited(ref.read(versePreviewProvider.notifier).pause());
    setState(() => _finishing = true);
    final settings = ref.read(settingsProvider.notifier);
    if (_firstVerseId != null) await settings.setLastVerseId(_firstVerseId);
    await settings.completeFirstLaunch(
      _lang,
      askAccount: ref.read(authGatewayProvider).available,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final motion = Motion.of(context);
    final accounts = ref.watch(authGatewayProvider).available;
    final total = WelcomeScreen.ownSteps + (accounts ? 1 : 0);
    final body = switch (_step) {
      _Step.intro => _introStep(ui, c),
      _Step.verse => _verseStep(ui, c),
      _Step.scroll => _scrollStep(ui),
      _Step.sadhak => _sadhakStep(ui),
      _Step.shravan => _shravanStep(ui),
    };
    final slide = motion.slide(Space.s24);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // The aura sits behind the opening step only; the reading steps
            // keep a plain page under their verse text.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OnboardingBackdrop(visible: _step == _Step.intro),
            ),
            SafeArea(
              child: ContentWidth(
                child: Column(
                  children: [
                    SizedBox(
                      height: Touch.minTarget,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedOpacity(
                              opacity: _step.index > 0 ? 1 : 0,
                              duration: motion.crossFade,
                              child: IgnorePointer(
                                ignoring: _step.index == 0,
                                child: LucideBackButton(onPressed: _back),
                              ),
                            ),
                          ),
                          OnboardingDots(index: _step.index, count: total),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: motion.pageSwap,
                        switchInCurve: AppCurves.standard,
                        switchOutCurve: AppCurves.standard,
                        transitionBuilder: (child, animation) {
                          final incoming = child.key == ValueKey(_step);
                          final dx = (incoming == _forward ? 1 : -1) * slide;
                          return FadeTransition(
                            opacity: animation,
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset((1 - animation.value) * dx, 0),
                                child: child,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(key: ValueKey(_step), child: body),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A step: content centred and scrollable (survives large text), with
  /// the step's main action pinned at the bottom.
  Widget _page(List<Widget> children, {required Widget footer}) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: StaggeredEntrance(children: children)),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.readingSide,
          Space.s12,
          Space.readingSide,
          Space.s16,
        ),
        child: footer,
      ),
    ],
  );

  Widget _heading(UiStyles ui, String text, {double? size}) => Semantics(
    header: true,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: ui.title.copyWith(fontSize: size ?? OnboardingMetrics.title),
    ),
  );

  Widget _sentence(UiStyles ui, String text) =>
      Text(text, textAlign: TextAlign.center, style: ui.body());

  // 1. The app in numbers.
  Widget _introStep(UiStyles ui, AppColors c) {
    final index = ref.watch(chaptersIndexProvider).value;
    final verses = index?.chapters.fold<int>(0, (s, ch) => s + ch.verseCount);
    return _page(
      [
        const SizedBox(height: Space.s24),
        const Center(child: LotusMark(size: OnboardingMetrics.lotus)),
        const SizedBox(height: Space.s16),
        Text(
          'BHAGAVAD-GĪTĀ AS IT IS',
          textAlign: TextAlign.center,
          style: ui.overline,
        ),
        const SizedBox(height: Space.s8),
        _heading(ui, 'One Scroll Gita', size: OnboardingMetrics.heroTitle),
        const SizedBox(height: Space.s12),
        Text(
          'Timeless wisdom, one verse at a time.',
          textAlign: TextAlign.center,
          style: ui.body(size: 16),
        ),
        const SizedBox(height: Space.s32),
        // Counted from the dataset, never typed in.
        AnimatedOpacity(
          opacity: index == null ? 0 : 1,
          duration: Motion.of(context).crossFade,
          child: Column(
            children: [
              OnboardingStatRow(
                stats: [
                  OnboardingStat(value: '${verses ?? ''}', label: 'verses'),
                  OnboardingStat(
                    value: '${index?.chapters.length ?? ''}',
                    label: 'chapters',
                  ),
                ],
              ),
              const SizedBox(height: Space.s12),
              const OnboardingStatRow(
                stats: [
                  OnboardingStat(value: '2', label: 'languages'),
                  OnboardingStat(value: '100%', label: 'free to read'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s24),
      ],
      footer: OnboardingCta(
        label: 'Begin',
        onPressed: () async {
          await ref.read(settingsProvider.notifier).setLanguage(_lang);
          _next();
        },
      ),
    );
  }

  // 2. The first verse; reading it lights the streak.
  Widget _verseStep(UiStyles ui, AppColors c) {
    final entry = ref.watch(dailyEntryProvider).value;
    _firstVerseId = entry?.id;
    return _page(
      [
        const SizedBox(height: Space.s16),
        _heading(ui, 'Your first verse'),
        const SizedBox(height: Space.s8),
        _sentence(ui, 'Take a slow breath and read it once.'),
        const SizedBox(height: Space.s24),
        if (entry == null)
          const SizedBox(height: Touch.minTarget * 4)
        else
          QualifyingRead(
            verseId: entry.id,
            dwell: ReadRule.homeDwell,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VerseTextBlock(entry: entry, gap: Space.s24),
                const SizedBox(height: Space.s16),
                Center(
                  child: ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.s16),
      ],
      footer: OnboardingCta(
        label: _streakLit ? 'Continue' : 'I have read it',
        onPressed: entry == null
            ? null
            : () {
                if (_streakLit) return _next();
                unawaited(HapticFeedback.mediumImpact());
                ref.read(readTrackerProvider.notifier).qualify(entry.id);
                setState(() => _streakLit = true);
              },
      ),
    );
  }

  // 3. Swiping through verses, as in the reader.
  Widget _scrollStep(UiStyles ui) => _page([
    _heading(ui, 'One swipe, one verse'),
    const SizedBox(height: Space.s8),
    _sentence(
      ui,
      'Move through the Gita like a feed. Each verse with its Sanskrit, '
      'translation and purport.',
    ),
    const SizedBox(height: Space.s24),
    const ScrollDemo(),
    const SizedBox(height: Space.s16),
  ], footer: OnboardingCta(label: 'Continue', onPressed: _next));

  // 4. Sadhak: the shloka trainer.
  Widget _sadhakStep(UiStyles ui) => _page([
    const PlanBadge('SADHAK'),
    const SizedBox(height: Space.s12),
    _heading(ui, 'Learn shlokas by heart'),
    const SizedBox(height: Space.s8),
    _sentence(
      ui,
      'The trainer hides a few words at a time until you can recite the '
      'whole verse. Try it.',
    ),
    const SizedBox(height: Space.s24),
    const TrainerDemo(),
    const SizedBox(height: Space.s16),
  ], footer: OnboardingCta(label: 'Continue', onPressed: _next));

  // 5. Shravan: listen to 1.1.
  Widget _shravanStep(UiStyles ui) => _page(
    [
      const PlanBadge('SHRAVAN'),
      const SizedBox(height: Space.s12),
      _heading(ui, 'Listen to every shloka'),
      const SizedBox(height: Space.s8),
      _sentence(
        ui,
        'Every verse recited in Sanskrit with its translation. Listen to '
        'the first one.',
      ),
      const SizedBox(height: Space.s24),
      const ListenDemo(),
      const SizedBox(height: Space.s16),
    ],
    footer: OnboardingCta(
      label: 'Continue',
      busy: _finishing,
      onPressed: _finish,
    ),
  );
}
