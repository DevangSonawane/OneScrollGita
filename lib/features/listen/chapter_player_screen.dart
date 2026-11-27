import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/audio_providers.dart';
import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/audio/audio.dart';
import '../common/common_widgets.dart';
import 'listen_widgets.dart';

/// The full player for the chapter queue (PRD_v4 section 4): the chapter's
/// cover on top, the verse being heard, and the controls on a card below.
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
        body: Center(
          child: s.loadingChapter != null
              ? Semantics(
                  label: 'Loading',
                  child: CircularProgressIndicator(color: c.accent),
                )
              : Text('Nothing is playing', style: ui.emptyTitle),
        ),
      );
    }

    final heroHeight = math
        .max(
          PlayerMetrics.heroMin,
          MediaQuery.sizeOf(context).height * PlayerMetrics.heroShare,
        )
        .roundToDouble(); // whole pixels: no anti-aliased seam at its foot

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: heroHeight,
                          child: _Hero(chapter: q.chapter, playing: s.playing),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: heroHeight - PlayerMetrics.heroOverlap,
                          ),
                          child: ContentWidth(
                            child: _NowPlayingText(
                              title:
                                  index?.chapter(q.chapter).title(lang) ?? '',
                              verseId: track.verseId,
                              phase: track.phase,
                              mode: s.mode,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s24),
                    // Large text: the controls scroll with the verse.
                    if (largeText) _Controls(state: s),
                  ],
                ),
              ),
              if (!largeText) _Controls(state: s),
            ],
          ),
          _TopButtons(onClose: close),
        ],
      ),
    );
  }
}

/// Back and more, floating over the cover (one glass layer).
class _TopButtons extends ConsumerWidget {
  const _TopButtons({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s16,
          vertical: Space.s8,
        ),
        child: GlassLayer(
          strength: GlassStrength.light,
          child: Row(
            children: [
              GlassIconButton(
                icon: LucideIcons.arrow_left,
                semanticLabel: 'Close player',
                onTap: onClose,
              ),
              const Spacer(),
              Builder(
                builder: (anchor) => GlassIconButton(
                  icon: LucideIcons.ellipsis,
                  semanticLabel: 'More options',
                  onTap: () => _showMore(anchor, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _More { view, sleep, repeat, playlist, mode }

Future<void> _showMore(BuildContext anchor, WidgetRef ref) async {
  final s = ref.read(audioControllerProvider);
  final audio = ref.read(audioControllerProvider.notifier);
  final choice = await showGlassMenu<_More>(
    anchor,
    items: [
      const GlassMenuItem(
        value: _More.view,
        icon: LucideIcons.eye,
        label: 'View',
      ),
      GlassMenuItem(
        value: _More.sleep,
        icon: LucideIcons.moon,
        label: s.sleep == null ? 'Sleep timer' : 'Sleep: ${s.sleep!.label}',
      ),
      GlassMenuItem(
        value: _More.repeat,
        icon: LucideIcons.repeat_1,
        label: s.repeatVerse ? 'Repeat this verse: on' : 'Repeat this verse',
      ),
      const GlassMenuItem(
        value: _More.playlist,
        icon: LucideIcons.list_music,
        label: 'Playlist',
      ),
      GlassMenuItem(
        value: _More.mode,
        icon: LucideIcons.languages,
        label: 'Listen to: ${s.mode.label}',
      ),
    ],
  );
  if (!anchor.mounted) return;
  switch (choice) {
    case _More.view:
      await _showView(anchor);
    case _More.sleep:
      await _showSleep(anchor, ref);
    case _More.repeat:
      audio.toggleRepeat();
    case _More.playlist:
      await _showVerses(anchor, ref);
    case _More.mode:
      await _showMode(anchor);
    case null:
  }
}

/// The chapter's cover, full bleed, fading into the page at its foot.
/// It drifts very slowly closer while it plays (still under reduced motion).
class _Hero extends StatefulWidget {
  const _Hero({required this.chapter, required this.playing});

  final int chapter;
  final bool playing;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(_Hero old) {
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
    return Semantics(
      label: 'Chapter ${widget.chapter}',
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final v = Curves.easeInOut.transform(_c.value);
                return Transform.scale(scale: 1 + 0.04 * v, child: child);
              },
              child: ChapterCover(
                chapter: widget.chapter,
                numeralSize: PlayerMetrics.heroNumeral,
              ),
            ),
          ),
          // Melts into the page so the title can sit on its foot.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Solid for its last strip, so no seam shows at the edge.
                stops: const [0, 0.4, 0.92, 1],
                colors: [
                  c.bg.withValues(alpha: 0),
                  c.bg.withValues(alpha: 0),
                  c.bg,
                  c.bg,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chapter title, verse reference, then the verse from the dataset:
/// Devanagari and the English translation, the one being heard in full
/// colour. On the page, never on glass.
class _NowPlayingText extends ConsumerWidget {
  const _NowPlayingText({
    required this.title,
    required this.verseId,
    required this.phase,
    required this.mode,
  });

  final String title;
  final String verseId;
  final AudioPhase phase;
  final PlayMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final entry = ref.watch(entryProvider(verseId)).value;
    final styles = readingStyles(context, ref);
    final k = PlayerMetrics.verseTextFactor * styles.scale;
    final sanskrit = phase == AudioPhase.sanskrit;
    final show = ref.watch(playerTextProvider);
    final translation = show.contains(PlayerText.translation);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: chapterNameStyle(
              ui.title.copyWith(fontWeight: FontWeight.w700),
              ref.watch(languageProvider),
            ),
          ),
          const SizedBox(height: Space.s4),
          if (entry != null)
            Text(
              'Bhagavad-gītā ${entry.label}',
              textAlign: TextAlign.center,
              style: ui.label(size: 17, color: c.textSecondary),
            ),
          const SizedBox(height: Space.s8),
          Semantics(
            container: true,
            label: 'Now: ${phase.label}',
            excludeSemantics: true,
            child: Text(switch (mode) {
              PlayMode.sanskritOnly => 'NOW · SANSKRIT ONLY',
              PlayMode.translationOnly => 'NOW · ENGLISH ONLY',
              PlayMode.withTranslation => 'NOW · ${phase.label.toUpperCase()}',
            }, style: ui.overline),
          ),
          const SizedBox(height: Space.s16),
          if (entry == null)
            const SizedBox(height: Touch.minTarget * 3)
          else
            AnimatedSwitcher(
              duration: Motion.of(context).crossFade,
              child: Column(
                key: ValueKey('$verseId-$sanskrit'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (show.contains(PlayerText.devanagari))
                    Text(
                      entry.sanskrit.join('\n'),
                      textAlign: TextAlign.center,
                      style: styles.sanskrit.copyWith(
                        fontSize: ReadingType.shloka * k,
                        color: sanskrit ? c.textPrimary : c.textTertiary,
                      ),
                    ),
                  if (show.contains(PlayerText.transliteration)) ...[
                    if (show.contains(PlayerText.devanagari))
                      const SizedBox(height: Space.s8),
                    Text(
                      entry.transliteration.join('\n'),
                      textAlign: TextAlign.center,
                      style: styles.transliteration.copyWith(
                        fontSize: ReadingType.transliteration * k,
                        color: sanskrit ? c.textSecondary : c.textTertiary,
                      ),
                    ),
                  ],
                  if (translation) ...[
                    if (show.length > 1) const SizedBox(height: Space.s16),
                    Text(
                      // English narration: the English translation from the
                      // dataset.
                      entry.translationEn,
                      textAlign: TextAlign.center,
                      locale: const Locale('en'),
                      style: styles
                          .translation('en')
                          .copyWith(
                            fontSize: ReadingType.translation * k,
                            color: sanskrit ? c.textTertiary : c.textPrimary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The white card at the foot: times, waveform, then previous, play/pause,
/// next, and the speed on the right.
class _Controls extends ConsumerWidget {
  const _Controls({required this.state});

  final AudioUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final audio = ref.read(audioControllerProvider.notifier);
    final s = state;
    final speedLabel =
        '${s.speed == s.speed.roundToDouble() ? s.speed.toStringAsFixed(0) : s.speed.toString()}×';

    Widget side(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: c.surfaceSoft,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: PlayerMetrics.sideButton,
              child: Icon(icon, size: IconSizes.regular, color: c.textPrimary),
            ),
          ),
        ),
      ),
    );

    // Control labels grow to 1.5x at most, like the nav bar (1.3x).
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: Space.s16),
        child: ContentWidth(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: Space.s16),
            padding: const EdgeInsets.fromLTRB(
              Space.s24,
              Space.s16,
              Space.s24,
              Space.s24,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.sheet),
              border: Border.all(color: c.hairline),
              boxShadow: Elevation.soft(c),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Scrubber(state: s),
                const SizedBox(height: Space.s16),
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    side(
                      LucideIcons.skip_back,
                      'Previous verse',
                      audio.previousVerse,
                    ),
                    const SizedBox(width: Space.s16),
                    Semantics(
                      button: true,
                      label: s.playing ? 'Pause' : 'Play',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: audio.toggle,
                        child: Container(
                          width: PlayerMetrics.mainButton,
                          height: PlayerMetrics.mainButton,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.accent,
                            boxShadow: Elevation.soft(c),
                          ),
                          child: AnimatedSwitcher(
                            duration: Motion.of(context).crossFade,
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
                    side(
                      LucideIcons.skip_forward,
                      'Next verse',
                      audio.nextVerse,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: 'Speed $speedLabel. Tap to change',
                          excludeSemantics: true,
                          child: InkResponse(
                            onTap: audio.cycleSpeed,
                            radius: Touch.minTarget / 2,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: Touch.minTarget,
                                minHeight: Touch.minTarget,
                              ),
                              child: Center(
                                child: Text(
                                  speedLabel,
                                  maxLines: 1,
                                  style: ui.label(
                                    size: 15,
                                    color: s.speed == 1
                                        ? c.textSecondary
                                        : c.accentText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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

/// Elapsed and remaining time over a waveform that fills as the chapter
/// plays. Drag or tap to seek.
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
    final shownMs = (s.totalMs * value).round();
    final audio = ref.read(audioControllerProvider.notifier);

    double frac(Offset local, double width) =>
        (local.dx / width).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Text(formatDuration(shownMs), style: ui.body(size: 13)),
            const Spacer(),
            Text(
              '-${formatDuration(math.max(0, s.totalMs - shownMs))}',
              style: ui.body(size: 13),
            ),
          ],
        ),
        const SizedBox(height: Space.s8),
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
                height: PlayerMetrics.scrubHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WavePainter(
                    value: value,
                    seed: s.queue?.chapter ?? 1,
                    played: c.accent,
                    rest: c.hairline,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bars of a steady made-up waveform (the same for a chapter every time);
/// those before [value] take the played colour.
class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.value,
    required this.seed,
    required this.played,
    required this.rest,
  });

  final double value;
  final int seed;
  final Color played;
  final Color rest;

  double _height(int i) {
    double noise(int n) {
      final x = math.sin(n * 12.9898 + seed * 78.233) * 43758.5453;
      return x - x.floorToDouble();
    }

    // A slow swell times a little jitter, so it reads like speech.
    final swell = 0.55 + 0.45 * math.sin(i * 0.35 + seed);
    return (0.2 + 0.8 * swell * (0.45 + 0.55 * noise(i))).clamp(0.15, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const step = PlayerMetrics.scrubBar + PlayerMetrics.scrubGap;
    final count = ((size.width + PlayerMetrics.scrubGap) / step).floor();
    if (count <= 0) return;
    final spare = size.width - (count * step - PlayerMetrics.scrubGap);
    final mid = size.height / 2;
    final paint = Paint()
      ..strokeWidth = PlayerMetrics.scrubBar
      ..strokeCap = StrokeCap.round;
    final cut = value * size.width;
    for (var i = 0; i < count; i++) {
      final x = spare / 2 + i * step + PlayerMetrics.scrubBar / 2;
      final half = (size.height - PlayerMetrics.scrubBar) * _height(i) / 2;
      paint.color = x <= cut ? played : rest;
      canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.value != value ||
      old.seed != seed ||
      old.played != played ||
      old.rest != rest;
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

/// Which lines of the verse the player shows: tick any of the three.
Future<void> _showView(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  builder: (sheet) => Consumer(
    builder: (context, ref, _) {
      final c = AppColors.of(context);
      final ui = UiStyles(c);
      final show = ref.watch(playerTextProvider);
      final view = ref.read(playerTextProvider.notifier);
      Widget option(String label, PlayerText t) => CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.readingSide,
        ),
        activeColor: c.accent,
        checkColor: c.onAccent,
        title: Text(label, style: ui.label()),
        value: show.contains(t),
        // The last line left on stays on.
        onChanged: show.length == 1 && show.contains(t)
            ? null
            : (_) => view.toggle(t),
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
              child: Text('View', style: ui.emptyTitle),
            ),
            option('Devanagari', PlayerText.devanagari),
            option('Transliteration', PlayerText.transliteration),
            option('English translation', PlayerText.translation),
            const SizedBox(height: Space.s8),
          ],
        ),
      );
    },
  ),
);

/// What is heard: Sanskrit and its translation, Sanskrit only, or English
/// only.
Future<void> _showMode(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  builder: (sheet) => Consumer(
    builder: (context, ref, _) {
      final c = AppColors.of(context);
      final ui = UiStyles(c);
      final current = ref.watch(audioControllerProvider.select((s) => s.mode));
      final audio = ref.read(audioControllerProvider.notifier);
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
              child: Text('Listen to', style: ui.emptyTitle),
            ),
            for (final m in PlayMode.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.readingSide,
                ),
                title: Text(m.label, style: ui.label()),
                trailing: current == m
                    ? Icon(LucideIcons.check, color: c.accentText)
                    : null,
                onTap: () {
                  audio.setMode(m);
                  Navigator.of(sheet).pop();
                },
              ),
            const SizedBox(height: Space.s8),
          ],
        ),
      );
    },
  ),
);
