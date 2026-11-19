import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/audio_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/audio/audio.dart';

void openPlayer(BuildContext context) => context.push('/player');

/// Four bars that rise and fall while audio plays (still bars under reduced
/// motion or when paused).
class SoundWave extends StatefulWidget {
  const SoundWave({super.key, required this.playing, required this.color});

  final bool playing;
  final Color color;

  @override
  State<SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppDurations.soundWave,
  );

  void _sync() {
    final run = widget.playing && !Motion.of(context).reduced;
    if (run && !_c.isAnimating) {
      _c.repeat();
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
  void didUpdateWidget(SoundWave old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SizedBox(
        height: PlayerMetrics.waveHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: PlayerMetrics.waveBar,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height:
                    PlayerMetrics.waveHeight *
                    (widget.playing && _c.isAnimating
                        ? 0.3 +
                              0.7 *
                                  (0.5 +
                                          0.5 *
                                              math.sin(
                                                2 * math.pi * _c.value +
                                                    i * 1.7,
                                              ))
                                      .abs()
                        : const [0.45, 0.8, 0.6, 0.35][i]),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The separate Listen pill beside the main nav pill.
class ListenPill extends ConsumerWidget {
  const ListenPill({
    super.key,
    required this.selected,
    required this.wide,
    required this.onTap,
  });

  final bool selected;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final playing = ref.watch(
      audioControllerProvider.select((s) => s.playing && s.active),
    );
    final lit = selected || playing;
    final fg = lit ? c.accentText : c.textSecondary;
    return Semantics(
      label: 'Listen, tab 4 of 4${playing ? ', playing' : ''}',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        width: wide ? PlayerMetrics.pillWide : PlayerMetrics.pillCompact,
        height: NavBarMetrics.height,
        child: GlassLayer(
          child: GlassShape(
            radius: NavBarMetrics.height / 2,
            child: Pressable(
              onTap: onTap,
              button: false,
              radius: NavBarMetrics.height / 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  decoration: BoxDecoration(
                    color: lit
                        ? c.accentSoft.withValues(alpha: 0.85)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (playing)
                        SoundWave(playing: true, color: fg)
                      else
                        Icon(
                          LucideIcons.headphones,
                          size: IconSizes.regular,
                          color: fg,
                        ),
                      if (wide) ...[
                        const SizedBox(width: Space.s8),
                        Flexible(
                          child: Text(
                            'Listen',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: UiStyles(c).label(size: 15, color: fg),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chapter's number on a warm tile ("२").
class ChapterNumeral extends StatelessWidget {
  const ChapterNumeral({super.key, required this.chapter, required this.size});

  final int chapter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.cardTop, p.cardBottom],
          ),
          border: Border.all(color: p.gold.withValues(alpha: 0.35)),
        ),
        child: Text(
          devanagariNumber(chapter),
          textScaler: TextScaler.noScaling,
          style: ReadingStyles(c, 1).sanskrit.copyWith(
            fontSize: size * 0.52,
            height: 1.1,
            color: c.accentText,
          ),
        ),
      ),
    );
  }
}

/// Floats above the nav pills on every tab while something is loaded.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final s = ref.watch(audioControllerProvider);
    final audio = ref.read(audioControllerProvider.notifier);
    final chapter = s.chapter ?? 1;
    final summary = s.kind == AudioKind.summary;
    final title = summary
        ? 'Chapter $chapter · Summary'
        : 'Chapter $chapter · ${s.track?.label ?? ''}';
    final subtitle = summary
        ? 'Chapter summary'
        : '${s.track?.phase.label ?? ''}${s.mode == PlayMode.sanskritOnly
              ? ''
              : s.track?.phase == AudioPhase.sanskrit
              ? ' · then translation'
              : ''}';
    // Like the nav pills it sits on, its labels grow to 1.3x at most.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Dismissible(
        key: const ValueKey('mini-player'),
        direction: DismissDirection.down,
        onDismissed: (_) => audio.stop(),
        child: Semantics(
          container: true,
          label: 'Now playing: $title',
          child: Container(
            height: PlayerMetrics.miniHeight,
            margin: const EdgeInsets.symmetric(horizontal: Space.s16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: c.hairline),
              boxShadow: Elevation.soft(c),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => summary
                        ? context.push('/gita/summary/$chapter')
                        : openPlayer(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: Space.s12),
                      child: Row(
                        children: [
                          ChapterNumeral(
                            chapter: chapter,
                            size: PlayerMetrics.miniTile,
                          ),
                          const SizedBox(width: Space.s12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ui.label(size: 14),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ui.body(size: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: s.playing ? 'Pause' : 'Play',
                            onPressed: audio.toggle,
                            icon: Icon(
                              s.playing ? LucideIcons.pause : LucideIcons.play,
                              color: c.textPrimary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close player',
                            onPressed: audio.stop,
                            icon: Icon(
                              LucideIcons.x,
                              size: IconSizes.small,
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                LinearProgressIndicator(
                  value: s.progress,
                  minHeight: PlayerMetrics.progressLine,
                  color: c.accent,
                  backgroundColor: c.hairline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
