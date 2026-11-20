import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';

/// What the paywall figure is doing (PRD_v6 section 3).
enum FigurePose {
  /// Sadhak: seated, holding an open book; pages turn now and then.
  reading,

  /// Shravan: seated with headphones, eyes closed, sound rippling out.
  listening,
}

/// A calm seated monk drawn in code (bald head, beard, tilak, closed eyes):
/// simple rounded shapes, no likeness of anyone. Breathes slowly; under
/// reduced motion it is a still drawing.
class SeekerFigure extends StatefulWidget {
  const SeekerFigure({super.key, required this.pose, this.animate = true});

  final FigurePose pose;

  /// False for the still thank-you view.
  final bool animate;

  @override
  State<SeekerFigure> createState() => _SeekerFigureState();
}

class _SeekerFigureState extends State<SeekerFigure>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: FigureMetrics.cycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || Motion.of(context).reduced) {
      _c
        ..stop()
        ..value = 0.25;
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
    final c = AppColors.of(context);
    final p = PremiumColors.of(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FigurePainter(
            t: _c,
            pose: widget.pose,
            colors: c,
            premium: p,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.t,
    required this.pose,
    required this.colors,
    required this.premium,
  }) : super(repaint: t);

  final Animation<double> t;
  final FigurePose pose;
  final AppColors colors;
  final PremiumColors premium;

  @override
  void paint(Canvas canvas, Size size) {
    // Fit a 200 x 200 design box, centred, as large as the space allows.
    final s =
        math.min(math.min(size.width, size.height), FigureMetrics.maxHeight) /
        200;
    if (s <= 0) return;
    final v = t.value; // 0..1, one full cycle
    final breath = math.sin(v * 2 * math.pi); // -1..1
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    canvas.translate(-100, -100);

    _halo(canvas, breath);
    if (pose == FigurePose.reading) _motes(canvas, v);

    // Listening: a gentle sway around the seat.
    if (pose == FigurePose.listening) {
      canvas.translate(100, 170);
      canvas.rotate(0.03 * math.sin(v * 2 * math.pi));
      canvas.translate(-100, -170);
    }

    _body(canvas, breath);
    if (pose == FigurePose.reading) {
      _book(canvas, v, breath);
    } else {
      _headphones(canvas, breath);
      _waves(canvas, v);
    }
    canvas.restore();
  }

  Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  void _halo(Canvas canvas, double breath) {
    final r = 82 + 4 * breath;
    canvas.drawCircle(
      const Offset(100, 92),
      r,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                premium.glow.withValues(alpha: 0.55),
                premium.glow.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: const Offset(100, 92), radius: r),
            ),
    );
  }

  void _body(Canvas canvas, double breath) {
    final lift = -1.2 * breath; // chest rises a little
    // Crossed legs: a wide soft base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 150, 120, 30),
        const Radius.circular(15),
      ),
      _fill(colors.accent.withValues(alpha: 0.85)),
    );
    // Robe: a rounded trapezoid.
    final robe = Path()
      ..moveTo(70, 82 + lift)
      ..quadraticBezierTo(100, 72 + lift, 130, 82 + lift)
      ..quadraticBezierTo(146, 120, 150, 160)
      ..lineTo(50, 160)
      ..quadraticBezierTo(54, 120, 70, 82 + lift)
      ..close();
    canvas.drawPath(
      robe,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [premium.gold, colors.accent],
        ).createShader(const Rect.fromLTWH(50, 72, 100, 90)),
    );
    // Shawl fold.
    final fold = Path()
      ..moveTo(78, 86 + lift)
      ..quadraticBezierTo(100, 112, 124, 86 + lift);
    canvas.drawPath(
      fold,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = premium.goldSoft.withValues(alpha: 0.8),
    );
    // Neck and head.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(94, 68 + lift, 12, 12),
        const Radius.circular(4),
      ),
      _fill(premium.goldSoft),
    );
    final head = Offset(100, 52 + lift);
    final skin = premium.goldSoft;
    final beardColor = colors.textSecondary;
    // Ears, then a bald head with a soft shine: a monk, not a headdress.
    for (final dx in [-18.0, 18.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: head.translate(dx, 3), width: 7, height: 11),
        _fill(Color.lerp(skin, colors.accent, 0.12)!),
      );
    }
    canvas.drawCircle(head, 19, _fill(skin));
    canvas.drawOval(
      Rect.fromCenter(center: head.translate(-6, -11), width: 11, height: 6),
      _fill(colors.surface.withValues(alpha: 0.55)),
    );
    // Tilak on the forehead.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: head.translate(0, -6), width: 2.6, height: 7),
        const Radius.circular(1.3),
      ),
      _fill(colors.accent),
    );
    // Full beard from cheek to cheek, rounded at the chin.
    final beard = Path()
      ..moveTo(head.dx - 17, head.dy + 2)
      ..quadraticBezierTo(head.dx - 16, head.dy + 26, head.dx, head.dy + 30)
      ..quadraticBezierTo(head.dx + 16, head.dy + 26, head.dx + 17, head.dy + 2)
      ..quadraticBezierTo(head.dx + 10, head.dy + 12, head.dx, head.dy + 12)
      ..quadraticBezierTo(head.dx - 10, head.dy + 12, head.dx - 17, head.dy + 2)
      ..close();
    canvas.drawPath(beard, _fill(beardColor.withValues(alpha: 0.9)));
    // Moustache.
    final moustache = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = beardColor;
    canvas.drawArc(
      Rect.fromCenter(center: head.translate(0, 13), width: 14, height: 6),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      moustache,
    );
    // Closed eyes: two gentle arcs, looking down.
    final eye = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = colors.textPrimary.withValues(alpha: 0.7);
    for (final dx in [-7.0, 7.0]) {
      canvas.drawArc(
        Rect.fromCenter(center: head.translate(dx, 2), width: 7, height: 4.5),
        0,
        math.pi,
        false,
        eye,
      );
    }
  }

  void _book(Canvas canvas, double v, double breath) {
    final y = 128 - 1.2 * breath;
    // Hands under the book.
    for (final x in [72.0, 128.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 10), width: 16, height: 11),
        _fill(premium.goldSoft),
      );
    }
    final cover = _fill(colors.accentText);
    final page = _fill(colors.surface);
    // Left and right pages, slightly opened in a V.
    final left = Path()
      ..moveTo(100, y + 6)
      ..lineTo(70, y - 2)
      ..lineTo(70, y - 26)
      ..lineTo(100, y - 18)
      ..close();
    final right = Path()
      ..moveTo(100, y + 6)
      ..lineTo(130, y - 2)
      ..lineTo(130, y - 26)
      ..lineTo(100, y - 18)
      ..close();
    canvas.drawPath(left.shift(const Offset(-1.5, 2)), cover);
    canvas.drawPath(right.shift(const Offset(1.5, 2)), cover);
    canvas.drawPath(left, page);
    canvas.drawPath(right, page);
    // Text lines.
    final line = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = colors.textTertiary.withValues(alpha: 0.6);
    for (var i = 0; i < 3; i++) {
      final o = 6.0 * i;
      canvas.drawLine(Offset(75, y - 20 + o), Offset(96, y - 13 + o), line);
      canvas.drawLine(Offset(104, y - 13 + o), Offset(125, y - 20 + o), line);
    }
    // A page turns in the last fifth of each cycle.
    const start = 0.8;
    if (v > start) {
      final k = Curves.easeInOut.transform((v - start) / (1 - start));
      final x = 130 - 60 * k; // outer edge travels right -> left
      final turning = Path()
        ..moveTo(100, y + 6)
        ..lineTo(x, y - 2 - 6 * math.sin(k * math.pi))
        ..lineTo(x, y - 26 - 6 * math.sin(k * math.pi))
        ..lineTo(100, y - 18)
        ..close();
      canvas.drawPath(
        turning,
        _fill(Color.lerp(colors.surface, premium.goldSoft, 0.5)!),
      );
    }
  }

  void _motes(Canvas canvas, double v) {
    // A few light motes rising from the book, each on its own phase.
    for (var i = 0; i < FigureMetrics.motes; i++) {
      final phase = (v + i / FigureMetrics.motes) % 1;
      final x = 80 + 40 * ((i * 37) % 10) / 10 + 4 * math.sin(phase * 6);
      final y = 110 - 80 * phase;
      final a = math.sin(phase * math.pi);
      canvas.drawCircle(
        Offset(x, y),
        1.6 + (i % 3) * 0.5,
        _fill(premium.gold.withValues(alpha: 0.65 * a)),
      );
    }
  }

  void _headphones(Canvas canvas, double breath) {
    final head = Offset(100, 52 - 1.2 * breath);
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = colors.accentText;
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: 24),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      band,
    );
    for (final dx in [-23.0, 23.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: head.translate(dx, 3), width: 11, height: 18),
          const Radius.circular(5),
        ),
        _fill(colors.accentText),
      );
    }
    // Hands resting in the lap.
    for (final x in [86.0, 114.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 146), width: 18, height: 11),
        _fill(premium.goldSoft),
      );
    }
  }

  void _waves(Canvas canvas, double v) {
    final head = const Offset(100, 55);
    for (var i = 0; i < FigureMetrics.waves; i++) {
      final phase = (v * 2 + i / FigureMetrics.waves) % 1;
      final r = 14 + 34 * phase;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = premium.gold.withValues(alpha: 0.7 * (1 - phase));
      for (final side in [-1.0, 1.0]) {
        final c = head.translate(side * 28, 0);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          side < 0 ? math.pi * 0.75 : -math.pi * 0.25,
          math.pi * 0.5,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.pose != pose || old.colors != colors || old.premium != premium;
}
