import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';

/// Hand-drawn art for the Sadhak plan: a drifting aura, a slowly turning
/// lotus mandala, rising golden sparks, a lotus mark, a shimmer and a bloom.
/// Every loop stops under reduced motion (one still frame instead).

// ---------------------------------------------------------------------------
// Ambient hero: aura + mandala + sparks, driven by one repeating controller.

class SadhakAmbient extends StatefulWidget {
  const SadhakAmbient({super.key, required this.height});

  final double height;

  @override
  State<SadhakAmbient> createState() => _SadhakAmbientState();
}

class _SadhakAmbientState extends State<SadhakAmbient>
    with SingleTickerProviderStateMixin {
  // One long cycle; the aura, mandala and sparks read their own phases
  // from the elapsed seconds.
  late final _c = AnimationController(
    vsync: this,
    duration: AppDurations.mandalaTurn,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).reduced) {
      _c
        ..stop()
        ..value = 0.06;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PremiumColors.of(context);
    final c = AppColors.of(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _AmbientPainter(
                seconds: _c.value * AppDurations.mandalaTurn.inSeconds,
                premium: p,
                line: c.accent,
                bg: c.bg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spark {
  const _Spark(this.x, this.phase, this.size, this.sway);
  final double x;
  final double phase;
  final double size;
  final double sway;
}

/// Fixed spark layout (a small hand-written LCG, so it never changes).
final List<_Spark> _sparks = () {
  var seed = 0x5AD4A;
  double next() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  }

  return [
    for (var i = 0; i < PaywallMetrics.sparkCount; i++)
      _Spark(0.08 + next() * 0.84, next(), 1.0 + next() * 2.0, next()),
  ];
}();

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.seconds,
    required this.premium,
    required this.line,
    required this.bg,
  });

  final double seconds;
  final PremiumColors premium;
  final Color line;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.5);
    // Never paint past the bounds (the aura is larger than the canvas).
    canvas.clipRect(Offset.zero & size);

    // 1. Aura: two soft lights drifting on slow ellipses.
    final a = 2 * math.pi * seconds / AppDurations.auraCycle.inSeconds;
    for (final (color, phase, rx) in [
      (premium.auraA, 0.0, 0.20),
      (premium.auraB, math.pi, 0.16),
    ]) {
      final o = center.translate(
        math.cos(a + phase) * w * rx,
        math.sin(a * 0.8 + phase) * h * 0.10,
      );
      final r = w * 0.62;
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    // 2. Mandala: three petal rings turning in opposite directions.
    final turn = 2 * math.pi * seconds / AppDurations.mandalaTurn.inSeconds;
    final R = PaywallMetrics.mandalaSize / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line.withValues(alpha: 0.20);
    for (final (petals, outer, inner, dir) in [
      (16, 1.0, 0.70, 1.0),
      (12, 0.74, 0.46, -1.0),
      (8, 0.50, 0.24, 1.0),
    ]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(turn * dir);
      for (var i = 0; i < petals; i++) {
        canvas.save();
        canvas.rotate(2 * math.pi * i / petals);
        canvas.drawPath(_petal(R * inner, R * outer, R * outer * 0.22), stroke);
        canvas.restore();
      }
      canvas.restore();
    }
    for (final f in const [1.06, 0.30]) {
      canvas.drawCircle(center, R * f, stroke);
    }
    // A dotted ring just outside the petals.
    final dot = Paint()..color = premium.gold.withValues(alpha: 0.35);
    const dots = 48;
    for (var i = 0; i < dots; i++) {
      final t = 2 * math.pi * i / dots - turn * 0.5;
      canvas.drawCircle(
        center + Offset(math.cos(t), math.sin(t)) * R * 1.14,
        0.9,
        dot,
      );
    }

    // 3. Sparks rising, fading in and out.
    final rise = seconds / AppDurations.sparkRise.inSeconds;
    final sparkPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    for (final s in _sparks) {
      final progress = (rise + s.phase) % 1.0;
      final y = h * (1.0 - progress);
      final x = w * s.x + math.sin((progress + s.sway) * 2 * math.pi) * 8;
      final alpha = math.sin(progress * math.pi) * 0.85;
      sparkPaint.color = premium.gold.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), s.size, sparkPaint);
    }

    // 4. Fade the bottom edge into the page.
    final fade = Rect.fromLTWH(0, h * 0.62, w, h * 0.38);
    canvas.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg.withValues(alpha: 0), bg],
        ).createShader(fade),
    );
  }

  /// A petal pointing up (negative y), from radius [r0] to [r1].
  static Path _petal(double r0, double r1, double width) => Path()
    ..moveTo(0, -r0)
    ..quadraticBezierTo(width, -(r0 + r1) / 2, 0, -r1)
    ..quadraticBezierTo(-width, -(r0 + r1) / 2, 0, -r0)
    ..close();

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.seconds != seconds || old.premium != premium || old.line != line;
}

// ---------------------------------------------------------------------------
// Lotus mark.

class LotusMark extends StatelessWidget {
  const LotusMark({super.key, required this.size, this.open = 1});

  final double size;

  /// 0 closed bud to 1 fully open (the success bloom animates this).
  final double open;

  @override
  Widget build(BuildContext context) {
    final p = PremiumColors.of(context);
    final c = AppColors.of(context);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LotusPainter(
          open: open,
          gold: p.gold,
          saffron: c.accent,
          soft: p.goldSoft,
        ),
      ),
    );
  }
}

class _LotusPainter extends CustomPainter {
  _LotusPainter({
    required this.open,
    required this.gold,
    required this.saffron,
    required this.soft,
  });

  final double open;
  final Color gold;
  final Color saffron;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final base = Offset(s / 2, s * 0.78);
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gold, saffron],
      ).createShader(Offset.zero & size);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..color = soft.withValues(alpha: 0.9);

    // Outer petals first, centre petal last. Each opens by its own angle.
    final e = Curves.easeOutBack.transform(open.clamp(0.0, 1.0));
    for (final (angle, length, width) in [
      (-1.25, 0.42, 0.13),
      (1.25, 0.42, 0.13),
      (-0.62, 0.55, 0.15),
      (0.62, 0.55, 0.15),
      (0.0, 0.66, 0.16),
    ]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle * e);
      final l = s * length * (0.55 + 0.45 * e);
      final wd = s * width;
      final petal = Path()
        ..moveTo(0, 0)
        ..cubicTo(wd, -l * 0.25, wd * 0.9, -l * 0.75, 0, -l)
        ..cubicTo(-wd * 0.9, -l * 0.75, -wd, -l * 0.25, 0, 0)
        ..close();
      canvas.drawPath(petal, fill);
      canvas.drawPath(petal, edge);
      canvas.restore();
    }
    // Water line.
    final w = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.03
      ..color = gold.withValues(alpha: 0.6);
    canvas.drawLine(
      base.translate(-s * 0.3, s * 0.06),
      base.translate(s * 0.3, s * 0.06),
      w,
    );
  }

  @override
  bool shouldRepaint(_LotusPainter old) =>
      old.open != open || old.gold != gold || old.saffron != saffron;
}

// ---------------------------------------------------------------------------
// Shimmer: a soft band of light sweeping across a child.

class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    required this.base,
    required this.highlight,
    this.textMode = true,
  });

  final Widget child;
  final Color base;
  final Color highlight;

  /// True: the child's own pixels take the gradient (text). False: a light
  /// band is laid over the child (buttons).
  final bool textMode;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).reduced) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.of(context).reduced) {
      return widget.textMode
          ? ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => LinearGradient(
                colors: [widget.base, widget.highlight, widget.base],
              ).createShader(r),
              child: widget.child,
            )
          : widget.child;
    }
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // The band crosses in the first 45% of the cycle, then rests.
        final t = (_c.value / 0.45).clamp(0.0, 1.0);
        final x = -1.5 + 3.0 * Curves.easeInOut.transform(t);
        if (widget.textMode) {
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(x - 1, -0.3),
              end: Alignment(x + 1, 0.3),
              colors: [widget.base, widget.highlight, widget.base],
              stops: const [0.3, 0.5, 0.7],
            ).createShader(r),
            child: child,
          );
        }
        return Stack(
          fit: StackFit.passthrough,
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x - 0.6, -1),
                        end: Alignment(x + 0.6, 1),
                        colors: [
                          widget.highlight.withValues(alpha: 0),
                          widget.highlight,
                          widget.highlight.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Success bloom: the lotus opens inside a ring of light and a burst of sparks.

class LotusBloom extends StatefulWidget {
  const LotusBloom({super.key});

  @override
  State<LotusBloom> createState() => _LotusBloomState();
}

class _LotusBloomState extends State<LotusBloom>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppDurations.bloom,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).reduced) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PremiumColors.of(context);
    const size = PaywallMetrics.bloomSize;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(size),
                  painter: _BurstPainter(
                    progress: v,
                    gold: p.gold,
                    glow: p.glow,
                  ),
                ),
                LotusMark(
                  size: size * 0.62,
                  open: const Interval(0.1, 0.8).transform(v),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.gold,
    required this.glow,
  });

  final double progress;
  final Color gold;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Glow disc.
    final g = Curves.easeOut.transform(progress);
    canvas.drawCircle(
      c,
      r * (0.4 + 0.6 * g),
      Paint()
        ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Expanding ring.
    final ring = const Interval(0.2, 0.9).transform(progress);
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        c,
        r * (0.5 + 0.5 * ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = gold.withValues(alpha: (1 - ring) * 0.8),
      );
    }
    // Sparks flying outwards.
    final burst = const Interval(0.25, 1.0).transform(progress);
    if (burst > 0 && burst < 1) {
      final paint = Paint()..color = gold.withValues(alpha: 1 - burst);
      const n = 14;
      for (var i = 0; i < n; i++) {
        final a = 2 * math.pi * i / n + 0.2;
        final d = r * (0.45 + 0.5 * Curves.easeOut.transform(burst));
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * d,
          2.2 * (1 - burst * 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
