import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';
import '../../application/core_providers.dart';
import '../../application/reminder_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/search_providers.dart';
import '../../application/streak_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/first_launch.dart';
import '../../domain/read_rule.dart';
import '../common/common_widgets.dart';
import '../common/qualifying_read.dart';
import '../premium/sadhak_art.dart';
import 'onboarding_parts.dart';

/// Guided first launch (PRD_v5 section 4): language, what brings you here,
/// the first verse (counts day 1), a reminder choice, then the account step
/// when this build has accounts (PRD_v9). There is no Skip: every step is
/// answered (owner, 2026-11-22).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  /// Steps shown in the dots: these four, plus sign-up when available.
  static const ownSteps = 4;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Step { language, intent, verse, reminder }

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  String _lang = 'en';
  _Step _step = _Step.language;
  bool _forward = true;
  FirstIntent? _intent;
  String? _firstVerseId;
  bool _finishing = false;
  bool _advancing = false;

  void _go(_Step s) => setState(() {
    _forward = s.index > _step.index;
    _step = s;
  });

  void _back() {
    if (_step.index == 0 || _finishing) return;
    _go(_Step.values[_step.index - 1]);
  }

  Future<void> _chooseIntent(FirstIntent i) async {
    if (_advancing) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _intent = i;
      _advancing = true;
    });
    await ref.read(settingsRepositoryProvider).setFirstIntent(i.name);
    // A moment to see the choice land before moving on.
    if (mounted) await Future<void>.delayed(Motion.of(context).crossFade);
    if (!mounted) return;
    _advancing = false;
    _go(_Step.verse);
  }

  Future<void> _finish({bool remind = false}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    if (remind) {
      // Asks for permission here, because the user chose it.
      await ref.read(reminderControllerProvider.notifier).setEnabled(true);
    }
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
      _Step.language => _languageStep(ui, c),
      _Step.intent => _intentStep(ui),
      _Step.verse => _verseStep(ui),
      _Step.reminder => _reminderStep(ui, c),
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
            // The aura sits behind the opening and closing steps only; the
            // verse step keeps a plain page under its reading text.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OnboardingBackdrop(
                visible: _step == _Step.language || _step == _Step.reminder,
              ),
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
  Widget _page(List<Widget> children, {Widget? footer}) => Column(
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
      if (footer != null)
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
      style: size == null ? ui.title : ui.title.copyWith(fontSize: size),
    ),
  );

  Widget _languageStep(UiStyles ui, AppColors c) {
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
        _heading(ui, 'One Scroll Gita', size: TitleSizes.hero),
        const SizedBox(height: Space.s12),
        Text(
          'Timeless wisdom, one verse at a time. Every verse is free to read '
          'and works without internet.',
          textAlign: TextAlign.center,
          style: ui.body(size: 17),
        ),
        const SizedBox(height: Space.s24),
        // Counted from the dataset, never typed in.
        AnimatedOpacity(
          opacity: index == null ? 0 : 1,
          duration: Motion.of(context).crossFade,
          child: OnboardingStatRow(
            stats: [
              OnboardingStat(value: '${verses ?? ''}', label: 'verses'),
              OnboardingStat(
                value: '${index?.chapters.length ?? ''}',
                label: 'chapters',
              ),
              const OnboardingStat(value: '2', label: 'languages'),
            ],
          ),
        ),
        const SizedBox(height: Space.s32),
        Text(
          'Choose your language',
          textAlign: TextAlign.center,
          style: ui.label(color: c.textSecondary),
        ),
        const SizedBox(height: Space.s12),
        for (final (code, label, hint) in const [
          ('en', 'English', 'Translation in English'),
          ('hi', 'हिन्दी', 'Translation in Hindi'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s12),
            child: _Option(
              label: label,
              hint: hint,
              semanticLabel: hint,
              fontFamily: code == 'en' ? Fonts.english : Fonts.devanagari,
              selected: _lang == code,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _lang = code);
              },
            ),
          ),
        Text(
          'You can change this later in Profile.',
          textAlign: TextAlign.center,
          style: ui.body(size: 13, color: c.textTertiary),
        ),
      ],
      footer: OnboardingCta(
        label: 'Begin',
        onPressed: () async {
          await ref.read(settingsProvider.notifier).setLanguage(_lang);
          _go(_Step.intent);
        },
      ),
    );
  }

  static IconData _intentIcon(FirstIntent i) => switch (i) {
    FirstIntent.peace => LucideIcons.leaf,
    FirstIntent.guidance => LucideIcons.compass,
    FirstIntent.study => LucideIcons.graduation_cap,
    FirstIntent.heart => LucideIcons.book_heart,
  };

  Widget _intentStep(UiStyles ui) => _page([
    _heading(ui, 'What brings you to the Gita?'),
    const SizedBox(height: Space.s8),
    Text(
      'We will choose your first verse for it. It stays on this phone.',
      textAlign: TextAlign.center,
      style: ui.body(),
    ),
    const SizedBox(height: Space.s32),
    for (final i in FirstIntent.values)
      Padding(
        padding: const EdgeInsets.only(bottom: Space.s12),
        child: _Option(
          icon: _intentIcon(i),
          label: i.label,
          hint: i.hint,
          semanticLabel: '${i.label}. ${i.hint}',
          selected: _intent == i,
          onTap: () => _chooseIntent(i),
        ),
      ),
  ]);

  Widget _verseStep(UiStyles ui) {
    final themes = ref.watch(themesProvider).value ?? const [];
    final themed = firstVerseFor(_intent, themes);
    final entry = themed == null
        ? ref.watch(dailyEntryProvider).value
        : ref.watch(entryProvider(themed)).value;
    _firstVerseId = entry?.id;
    return _page(
      [
        const SizedBox(height: Space.s24),
        _heading(ui, 'Your first verse'),
        const SizedBox(height: Space.s8),
        Text(
          'Take a slow breath and read it once.',
          textAlign: TextAlign.center,
          style: ui.body(),
        ),
        const SizedBox(height: Space.s32),
        if (entry == null)
          const SizedBox(height: Touch.minTarget * 4)
        else
          QualifyingRead(
            verseId: entry.id,
            dwell: ReadRule.homeDwell,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VerseTextBlock(entry: entry),
                const SizedBox(height: Space.s16),
                Center(
                  child: ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.s24),
      ],
      footer: OnboardingCta(
        label: 'I have read it',
        onPressed: entry == null
            ? null
            : () {
                unawaited(HapticFeedback.lightImpact());
                ref.read(readTrackerProvider.notifier).qualify(entry.id);
                _go(_Step.reminder);
              },
      ),
    );
  }

  Widget _reminderStep(UiStyles ui, AppColors c) {
    final t = ref.watch(reminderControllerProvider).settings.reminderTime;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: t.hour, minute: t.minute));
    return _page(
      [
        const SizedBox(height: Space.s24),
        Semantics(
          label: 'Day 1',
          excludeSemantics: true,
          child: Column(
            children: [
              Icon(
                LucideIcons.flame,
                size: IconSizes.large,
                color: c.accentText,
              ),
              Text(
                '1',
                textAlign: TextAlign.center,
                style: ui.title.copyWith(
                  fontSize: OnboardingMetrics.dayNumber,
                  color: c.accentText,
                  height: 1.05,
                ),
              ),
              Text('DAY', textAlign: TextAlign.center, style: ui.overline),
            ],
          ),
        ),
        const SizedBox(height: Space.s24),
        _heading(ui, 'Day 1. A beginning.'),
        const SizedBox(height: Space.s12),
        Text(
          'You have read your first verse. A gentle reminder each day helps '
          'it become a habit. You can change the time or turn it off in '
          'Profile.',
          textAlign: TextAlign.center,
          style: ui.body(),
        ),
        const SizedBox(height: Space.s24),
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingCta(
            label: 'Remind me at $time',
            busy: _finishing,
            onPressed: () => _finish(remind: true),
          ),
          const SizedBox(height: Space.s8),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(Touch.minTarget),
            ),
            onPressed: _finishing ? null : _finish,
            child: const Text('I will come back on my own'),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.hint,
    this.icon,
    this.fontFamily,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final String semanticLabel;
  final String? fontFamily;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final motion = Motion.of(context);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: semanticLabel,
      radius: Radii.card,
      child: AnimatedContainer(
        duration: motion.crossFade,
        curve: AppCurves.standard,
        constraints: const BoxConstraints(minHeight: Touch.minTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s16,
          vertical: Space.s16,
        ),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: selected ? c.accent : c.hairline,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: PremiumColors.of(context).glow,
                    blurRadius: Space.s16,
                    offset: const Offset(0, Space.s4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              AnimatedContainer(
                duration: motion.crossFade,
                width: OnboardingMetrics.benefitIcon,
                height: OnboardingMetrics.benefitIcon,
                decoration: BoxDecoration(
                  color: selected ? c.accent : c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: IconSizes.small,
                  color: selected ? c.onAccent : c.accentText,
                ),
              ),
              const SizedBox(width: Space.s16),
            ] else
              const SizedBox(width: Space.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ui.title.copyWith(
                      fontSize: TitleSizes.card,
                      fontFamily: fontFamily,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: Space.s4),
                    Text(hint!, style: ui.body(size: 14)),
                  ],
                ],
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0.6,
              duration: motion.crossFade,
              curve: AppCurves.standard,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: motion.crossFade,
                child: Icon(LucideIcons.check, color: c.accentText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
