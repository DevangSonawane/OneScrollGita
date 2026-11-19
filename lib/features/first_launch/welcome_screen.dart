import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Guided first launch (PRD_v5 section 4): language, what brings you here,
/// the first verse (counts day 1), an optional reminder, then Home. Every
/// step can be skipped.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Step { language, intent, verse, reminder }

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  String _lang = 'en';
  _Step _step = _Step.language;
  FirstIntent? _intent;
  String? _firstVerseId;
  bool _finishing = false;

  void _go(_Step s) => setState(() => _step = s);

  Future<void> _chooseIntent(FirstIntent i) async {
    setState(() => _intent = i);
    await ref.read(settingsRepositoryProvider).setFirstIntent(i.name);
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
    await settings.completeFirstLaunch(_lang);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final body = switch (_step) {
      _Step.language => _languageStep(ui, c),
      _Step.intent => _intentStep(ui),
      _Step.verse => _verseStep(ui),
      _Step.reminder => _reminderStep(ui, c),
    };
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              SizedBox(
                height: Touch.minTarget,
                child: Row(
                  children: [
                    const SizedBox(width: Space.readingSide),
                    _StepDots(index: _step.index, count: _Step.values.length),
                    const Spacer(),
                    if (_step != _Step.language)
                      TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: const Text('Skip'),
                      ),
                    const SizedBox(width: Space.s8),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.of(context).crossFade,
                  child: KeyedSubtree(key: ValueKey(_step), child: body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A centred, scrollable step that survives large text.
  Widget _page(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );

  Widget _heading(UiStyles ui, String text, {double? size}) => Semantics(
    header: true,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: size == null ? ui.title : ui.title.copyWith(fontSize: size),
    ),
  );

  Widget _languageStep(UiStyles ui, AppColors c) => _page([
    const SizedBox(height: Space.s32),
    _heading(ui, 'One Scroll Gita', size: TitleSizes.hero),
    const SizedBox(height: Space.s16),
    Text(
      'Read the Bhagavad-gita As It Is. No account. No internet needed.',
      textAlign: TextAlign.center,
      style: ui.body(size: 17),
    ),
    const SizedBox(height: Space.s48),
    for (final (code, label, hint) in const [
      ('en', 'English', 'Translation in English'),
      ('hi', 'हिन्दी', 'Translation in Hindi'),
    ])
      Padding(
        padding: const EdgeInsets.only(bottom: Space.s12),
        child: _Option(
          label: label,
          semanticLabel: hint,
          fontFamily: code == 'en' ? Fonts.literata : Fonts.devanagari,
          selected: _lang == code,
          onTap: () => setState(() => _lang = code),
        ),
      ),
    const SizedBox(height: Space.s32),
    FilledButton(
      onPressed: () async {
        await ref.read(settingsProvider.notifier).setLanguage(_lang);
        _go(_Step.intent);
      },
      child: const Text('Begin'),
    ),
    const SizedBox(height: Space.s12),
    Text(
      'You can change this later in Profile.',
      textAlign: TextAlign.center,
      style: ui.body(size: 13, color: c.textTertiary),
    ),
    const SizedBox(height: Space.s32),
  ]);

  Widget _intentStep(UiStyles ui) => _page([
    _heading(ui, 'What brings you to the Gita?'),
    const SizedBox(height: Space.s8),
    Text(
      'We will start you with one verse. It stays on this phone.',
      textAlign: TextAlign.center,
      style: ui.body(),
    ),
    const SizedBox(height: Space.s32),
    for (final i in FirstIntent.values)
      Padding(
        padding: const EdgeInsets.only(bottom: Space.s12),
        child: _Option(
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
    return _page([
      const SizedBox(height: Space.s24),
      _heading(ui, 'Your first verse'),
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
      const SizedBox(height: Space.s32),
      FilledButton(
        onPressed: entry == null
            ? null
            : () {
                ref.read(readTrackerProvider.notifier).qualify(entry.id);
                _go(_Step.reminder);
              },
        child: const Text('I have read it'),
      ),
      const SizedBox(height: Space.s32),
    ]);
  }

  Widget _reminderStep(UiStyles ui, AppColors c) {
    final t = ref.watch(reminderControllerProvider).settings.reminderTime;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: t.hour, minute: t.minute));
    return _page([
      _heading(ui, 'Day 1. A beginning.'),
      const SizedBox(height: Space.s12),
      Text(
        'Would you like a gentle reminder each day? You can change the time '
        'or turn it off in Profile.',
        textAlign: TextAlign.center,
        style: ui.body(),
      ),
      const SizedBox(height: Space.s32),
      FilledButton(
        onPressed: _finishing ? null : () => _finish(remind: true),
        child: Text('Remind me at $time'),
      ),
      const SizedBox(height: Space.s8),
      TextButton(
        onPressed: _finishing ? null : _finish,
        child: const Text('Not now'),
      ),
    ]);
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.only(right: Space.s4),
              width: i == index ? Space.s16 : StreakMetrics.dot - 4,
              height: StreakMetrics.dot - 4,
              decoration: BoxDecoration(
                color: i <= index ? c.accent : c.hairline,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
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
    this.fontFamily,
  });

  final String label;
  final String? hint;
  final String semanticLabel;
  final String? fontFamily;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: semanticLabel,
      radius: Radii.card,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        constraints: const BoxConstraints(minHeight: Touch.minTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s24,
          vertical: Space.s16,
        ),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: selected ? c.accent : c.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
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
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: AppDurations.fast,
              child: Icon(Icons.check_rounded, color: c.accentText),
            ),
          ],
        ),
      ),
    );
  }
}
