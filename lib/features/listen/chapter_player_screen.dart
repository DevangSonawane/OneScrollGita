import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/audio_providers.dart';
import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/audio/audio.dart';
import '../common/common_widgets.dart';
import '../premium/sadhak_art.dart';
import 'listen_widgets.dart';

/// The full player for the chapter queue (PRD_v4 section 4).
class ChapterPlayerScreen extends ConsumerWidget {
  const ChapterPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final s = ref.watch(audioControllerProvider);
    final index = ref.watch(chaptersIndexProvider).value;
    final lang = ref.watch(languageProvider);
    final q = s.kind == AudioKind.chapter ? s.queue : null;
    final track = s.track;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    void close() => context.canPop() ? context.pop() : context.go('/listen');

    if (q == null || track == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close player',
            onPressed: close,
            icon: const Icon(LucideIcons.chevron_down),
          ),
        ),
        body: Center(child: Text('Nothing is playing', style: ui.emptyTitle)),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              chapter: q.chapter,
              title: index?.chapter(q.chapter).title(lang) ?? '',
              onClose: close,
              onVerses: () => _showVerses(context, ref),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.readingSide,
                ),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Art(chapter: q.chapter, playing: s.playing),
                        const SizedBox(height: Space.s8),
                        _PhaseChips(phase: track.phase, mode: s.mode),
                        const SizedBox(height: Space.s16),
                        _VerseCard(verseId: track.verseId, phase: track.phase),
                        const SizedBox(height: Space.s16),
                        // Large text: the controls scroll with the verse.
                        if (largeText) _Controls(state: s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!largeText) _Controls(state: s),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.chapter,
    required this.title,
    required this.onClose,
    required this.onVerses,
  });

  final int chapter;
  final String title;
  final VoidCallback onClose;
  final VoidCallback onVerses;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close player',
            onPressed: onClose,
            icon: Icon(LucideIcons.chevron_down, color: c.textPrimary),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'CHAPTER $chapter',
                  style: ui.overline.copyWith(color: c.textSecondary),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: ui.label(size: 14),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Verses in this chapter',
            onPressed: onVerses,
            icon: Icon(LucideIcons.list_music, color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// The turning mandala with the chapter number, breathing while it plays.
class _Art extends StatefulWidget {
  const _Art({required this.chapter, required this.playing});

  final int chapter;
  final bool playing;

  @override
  State<_Art> createState() => _ArtState();
}

class _ArtState extends State<_Art> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppDurations.breathe,
  );

  void _sync() {
    final run = widget.playing && !Motion.of(context).reduced;
    if (run && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Art old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    return SizedBox(
      height: PlayerMetrics.art,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Full bleed past the page's side padding, soft at both edges.
          const Positioned(
            top: 0,
            bottom: 0,
            left: -Space.readingSide,
            right: -Space.readingSide,
            child: SadhakAmbient(height: PlayerMetrics.art, fadeTop: true),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final v = Curves.easeInOut.transform(_c.value);
              return Transform.scale(scale: 0.96 + 0.06 * v, child: child);
            },
            child: Semantics(
              label: 'Chapter ${widget.chapter}',
              excludeSemantics: true,
              child: Container(
                width: PlayerMetrics.art * 0.5,
                height: PlayerMetrics.art * 0.5,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [p.cardTop, p.cardTop.withValues(alpha: 0)],
                  ),
                ),
                child: Text(
                  devanagariNumber(widget.chapter),
                  textScaler: TextScaler.noScaling,
                  style: ReadingStyles(c, 1).sanskrit.copyWith(
                    fontSize: PlayerMetrics.artNumeral,
                    height: 1.1,
                    color: c.accentText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseChips extends StatelessWidget {
  const _PhaseChips({required this.phase, required this.mode});

  final AudioPhase phase;
  final PlayMode mode;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final duration = Motion.of(context).reduced
        ? AppDurations.instant
        : AppDurations.base;
    Widget chip(AudioPhase p) {
      final on = p == phase;
      return AnimatedContainer(
        duration: duration,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s12,
          vertical: Space.s4,
        ),
        decoration: BoxDecoration(
          color: on ? c.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: on ? c.accentSoft : c.hairline),
        ),
        child: Text(
          p.label,
          style: ui.label(size: 13, color: on ? c.accentText : c.textTertiary),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Now: ${phase.label}',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s8,
        runSpacing: Space.s8,
        children: [
          chip(AudioPhase.sanskrit),
          if (mode == PlayMode.withTranslation) ...[
            Icon(
              LucideIcons.chevron_right,
              size: IconSizes.small - 4,
              color: c.textTertiary,
            ),
            chip(AudioPhase.translation),
          ],
        ],
      ),
    );
  }
}

/// The verse being heard, from the dataset, on a solid card (never glass).
class _VerseCard extends ConsumerWidget {
  const _VerseCard({required this.verseId, required this.phase});

  final String verseId;
  final AudioPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final entry = ref.watch(entryProvider(verseId)).value;
    final lang = ref.watch(languageProvider);
    final styles = readingStyles(context, ref);
    if (entry == null) {
      return const SizedBox(height: Touch.minTarget * 3);
    }
    final sanskrit = phase == AudioPhase.sanskrit;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s16,
        vertical: Space.s12,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.hairline),
      ),
      child: AnimatedSwitcher(
        duration: Motion.of(context).crossFade,
        child: Column(
          key: ValueKey('$verseId-$sanskrit'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: ReferenceChip(label: 'Bhagavad-gītā ${entry.label}')),
            const SizedBox(height: Space.s12),
            // A little smaller than the reader: the player is for listening.
            if (sanskrit) ...[
              Text(
                entry.sanskrit.join('\n'),
                textAlign: TextAlign.center,
                style: styles.sanskrit.copyWith(
                  fontSize: (styles.sanskrit.fontSize ?? 22) * 0.82,
                ),
              ),
              const SizedBox(height: Space.s8),
              Text(
                entry.transliteration.join('\n'),
                textAlign: TextAlign.center,
                style: styles.transliteration.copyWith(
                  fontSize: (styles.transliteration.fontSize ?? 15) * 0.9,
                ),
              ),
            ] else
              Text(
                // English narration: the English translation from the dataset.
                entry.translationEn,
                style: styles
                    .translation('en')
                    .copyWith(
                      fontSize:
                          (styles.translation('en').fontSize ?? 18) * 0.86,
                    ),
                locale: const Locale('en'),
              ),
            if (sanskrit && lang == 'hi' && entry.hasTranslation('hi')) ...[
              const SizedBox(height: Space.s12),
              Text(
                entry.translation('hi'),
                style: styles.translation('hi').copyWith(color: c.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state});

  final AudioUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    final ui = UiStyles(c);
    final audio = ref.read(audioControllerProvider.notifier);
    final s = state;
    final now = ref.read(clockProvider)();
    final sleepLabel = switch (s.sleep) {
      null => 'Sleep',
      SleepOption.endOfVerse => 'After verse',
      SleepOption.endOfChapter => 'After chapter',
      _ when s.sleepEndsAt != null =>
        '${(s.sleepEndsAt!.difference(now).inSeconds / 60).ceil().clamp(0, 99)} min',
      _ => 'Sleep',
    };
    final speedLabel =
        '${s.speed == s.speed.roundToDouble() ? s.speed.toStringAsFixed(0) : s.speed.toString()}×';

    Widget small(
      IconData icon,
      String label,
      VoidCallback onTap, {
      bool on = false,
      String? semantics,
    }) => Semantics(
      button: true,
      toggled: on,
      label: semantics ?? label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: Touch.minTarget,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Touch.minTarget + Space.s16,
            minHeight: Touch.minTarget,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: IconSizes.small,
                color: on ? c.accentText : c.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: ui.body(
                  size: 11,
                  color: on ? c.accentText : c.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Control labels grow to 1.5x at most, like the nav bar (1.3x).
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.hairline)),
        ),
        padding: const EdgeInsets.fromLTRB(
          Space.readingSide,
          Space.s8,
          Space.readingSide,
          Space.s8,
        ),
        child: ContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Scrubber(state: s),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous verse',
                    iconSize: IconSizes.large,
                    onPressed: audio.previousVerse,
                    icon: Icon(LucideIcons.skip_back, color: c.textPrimary),
                  ),
                  const SizedBox(width: Space.s16),
                  Semantics(
                    button: true,
                    label: s.playing ? 'Pause' : 'Play',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: audio.toggle,
                      child: Container(
                        width: PlayerMetrics.playButton,
                        height: PlayerMetrics.playButton,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.accent, p.gold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: p.glow,
                              blurRadius: PaywallMetrics.glowBlur * 0.6,
                              offset: const Offset(0, Space.s4),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: AppDurations.fast,
                          child: Icon(
                            s.playing ? LucideIcons.pause : LucideIcons.play,
                            key: ValueKey(s.playing),
                            size: IconSizes.large,
                            color: c.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.s16),
                  IconButton(
                    tooltip: 'Next verse',
                    iconSize: IconSizes.large,
                    onPressed: audio.nextVerse,
                    icon: Icon(LucideIcons.skip_forward, color: c.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: Space.s4),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  small(
                    LucideIcons.gauge,
                    speedLabel,
                    audio.cycleSpeed,
                    semantics: 'Speed $speedLabel. Tap to change',
                  ),
                  small(
                    LucideIcons.moon,
                    sleepLabel,
                    () => _showSleep(context, ref),
                    on: s.sleep != null,
                    semantics: s.sleep == null
                        ? 'Sleep timer'
                        : 'Sleep timer: $sleepLabel',
                  ),
                  small(
                    LucideIcons.languages,
                    s.mode == PlayMode.sanskritOnly
                        ? 'Sanskrit only'
                        : '+ Meaning',
                    () => audio.setMode(
                      s.mode == PlayMode.sanskritOnly
                          ? PlayMode.withTranslation
                          : PlayMode.sanskritOnly,
                    ),
                    on: s.mode == PlayMode.sanskritOnly,
                    semantics: s.mode.label,
                  ),
                  small(
                    LucideIcons.repeat_1,
                    'Repeat',
                    audio.toggleRepeat,
                    on: s.repeatVerse,
                    semantics: 'Repeat this verse',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chapter progress with a small tick at each verse. Drag or tap to seek.
class _Scrubber extends ConsumerStatefulWidget {
  const _Scrubber({required this.state});

  final AudioUiState state;

  @override
  ConsumerState<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends ConsumerState<_Scrubber> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final s = widget.state;
    final value = _drag ?? s.progress;
    final marks = s.queue?.verseMarks ?? const [];
    final shownMs = (s.totalMs * value).round();
    final audio = ref.read(audioControllerProvider.notifier);

    double frac(Offset local, double width) =>
        (local.dx / width).clamp(0.0, 1.0);

    return Column(
      children: [
        Semantics(
          slider: true,
          label: 'Chapter position',
          value: '${formatDuration(shownMs)} of ${formatDuration(s.totalMs)}',
          increasedValue: 'Next verse',
          decreasedValue: 'Previous verse',
          onIncrease: audio.nextVerse,
          onDecrease: audio.previousVerse,
          child: LayoutBuilder(
            builder: (context, box) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) =>
                  audio.seekFraction(frac(d.localPosition, box.maxWidth)),
              onHorizontalDragStart: (d) =>
                  setState(() => _drag = frac(d.localPosition, box.maxWidth)),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _drag = frac(d.localPosition, box.maxWidth)),
              onHorizontalDragEnd: (_) {
                final f = _drag;
                setState(() => _drag = null);
                if (f != null) audio.seekFraction(f);
              },
              child: SizedBox(
                height: PlayerMetrics.scrubberHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ScrubberPainter(
                    value: value,
                    marks: [for (final m in marks) m.at],
                    track: c.hairline,
                    fill: c.accent,
                    tick: c.textTertiary.withValues(alpha: 0.5),
                    thumb: c.accent,
                    dragging: _drag != null,
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Text(formatDuration(shownMs), style: ui.body(size: 12)),
            const Spacer(),
            Text(formatDuration(s.totalMs), style: ui.body(size: 12)),
          ],
        ),
      ],
    );
  }
}

class _ScrubberPainter extends CustomPainter {
  _ScrubberPainter({
    required this.value,
    required this.marks,
    required this.track,
    required this.fill,
    required this.tick,
    required this.thumb,
    required this.dragging,
  });

  final double value;
  final List<double> marks;
  final Color track;
  final Color fill;
  final Color tick;
  final Color thumb;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line..color = track);
    final ticks = Paint()
      ..color = tick
      ..strokeWidth = 1;
    // Too many verses to tick each one clearly: thin them out.
    final step = (marks.length / 40).ceil().clamp(1, 1000);
    for (var i = 0; i < marks.length; i += step) {
      final x = marks[i] * size.width;
      canvas.drawLine(
        Offset(x, y - PlayerMetrics.tickHeight / 2),
        Offset(x, y + PlayerMetrics.tickHeight / 2),
        ticks,
      );
    }
    final x = value * size.width;
    canvas.drawLine(Offset(0, y), Offset(x, y), line..color = fill);
    canvas.drawCircle(Offset(x, y), dragging ? 8 : 6, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_ScrubberPainter old) =>
      old.value != value ||
      old.dragging != dragging ||
      old.marks.length != marks.length ||
      old.fill != fill;
}

Future<void> _showVerses(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => Consumer(
          builder: (context, ref, _) {
            final c = AppColors.of(context);
            final ui = UiStyles(c);
            final s = ref.watch(audioControllerProvider);
            final marks = s.queue?.verseMarks ?? const [];
            final current = s.track?.verseId;
            return ListView.builder(
              controller: controller,
              itemCount: marks.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.readingSide,
                      Space.s16,
                      Space.readingSide,
                      Space.s8,
                    ),
                    child: Text('Verses', style: ui.emptyTitle),
                  );
                }
                final m = marks[i - 1];
                final on = m.verseId == current;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Space.readingSide,
                  ),
                  selected: on,
                  leading: on
                      ? SoundWave(playing: s.playing, color: c.accentText)
                      : Icon(
                          LucideIcons.play,
                          size: IconSizes.small,
                          color: c.textTertiary,
                        ),
                  title: Text(
                    m.label,
                    style: ui.label(color: on ? c.accentText : c.textPrimary),
                  ),
                  trailing: Text(
                    formatDuration(((s.queue?.totalMs ?? 0) * m.at).round()),
                    style: ui.body(size: 13),
                  ),
                  onTap: () {
                    ref
                        .read(audioControllerProvider.notifier)
                        .seekToVerse(m.verseId);
                    Navigator.of(sheet).pop();
                  },
                );
              },
            );
          },
        ),
      ),
    );

Future<void> _showSleep(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) {
          final c = AppColors.of(context);
          final ui = UiStyles(c);
          final current = ref.watch(
            audioControllerProvider.select((s) => s.sleep),
          );
          final audio = ref.read(audioControllerProvider.notifier);
          Widget option(String label, SleepOption? value) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.readingSide,
            ),
            title: Text(label, style: ui.label()),
            trailing: current == value
                ? Icon(LucideIcons.check, color: c.accentText)
                : null,
            onTap: () {
              audio.setSleep(value);
              Navigator.of(sheet).pop();
            },
          );
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.readingSide,
                    Space.s16,
                    Space.readingSide,
                    Space.s8,
                  ),
                  child: Text('Sleep timer', style: ui.emptyTitle),
                ),
                for (final o in SleepOption.values) option(o.label, o),
                option('Off', null),
              ],
            ),
          );
        },
      ),
    );
