import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// A chunky 3D button: a face sitting [TactileMetrics.depth] above a darker
/// base, sinking onto it when pressed. Under reduced motion it still sinks
/// (a state change, not an animation) and the shake is skipped.
class TactileButton extends StatefulWidget {
  const TactileButton({
    super.key,
    required this.child,
    required this.onTap,
    this.face,
    this.edge,
    this.border,
    this.shakeKey,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? face;
  final Color? edge;
  final Color? border;

  /// Change this to shake the button once (a wrong answer).
  final Object? shakeKey;
  final String? semanticLabel;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  late final _shake = AnimationController(
    vsync: this,
    duration: TactileMetrics.shake,
  );

  @override
  void didUpdateWidget(TactileButton old) {
    super.didUpdateWidget(old);
    if (widget.shakeKey != null &&
        widget.shakeKey != old.shakeKey &&
        !Motion.of(context).reduced) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = widget.onTap != null;
    final face = widget.face ?? c.surface;
    // The base is a shade darker than the hairline so the depth reads in
    // light mode too.
    final edge = widget.edge ?? Color.lerp(c.hairline, c.textPrimary, 0.22)!;
    final border = widget.border ?? c.hairline;
    final radius = BorderRadius.circular(TactileMetrics.radius);
    final sink = _down ? TactileMetrics.depth : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              math.sin(_shake.value * math.pi * 6) *
                  (1 - _shake.value) *
                  Space.s8,
              0,
            ),
            child: child,
          ),
          // The darker base shows below the face; pressing moves the face
          // down onto it while the whole stays the same height.
          child: AnimatedContainer(
            duration: TactileMetrics.press,
            margin: EdgeInsets.only(top: sink),
            padding: EdgeInsets.only(bottom: TactileMetrics.depth - sink),
            decoration: BoxDecoration(color: edge, borderRadius: radius),
            child: Container(
              decoration: BoxDecoration(
                color: face,
                borderRadius: radius,
                border: Border.all(color: border, width: 2),
              ),
              constraints: const BoxConstraints(
                minHeight: Touch.minTarget - TactileMetrics.depth,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s16,
                vertical: Space.s8,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glossy, raised icon: a gradient tile with a top highlight and a soft
/// coloured shadow, the glyph lit from above.
class Icon3D extends StatelessWidget {
  const Icon3D({
    super.key,
    required this.icon,
    required this.palette,
    this.size = TactileMetrics.iconTile,
  });

  final IconData icon;
  final FeelingPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size * 0.3);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.top, palette.bottom],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.bottom.withValues(alpha: 0.45),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gloss on the top half.
            Positioned(
              left: size * 0.08,
              right: size * 0.08,
              top: size * 0.05,
              height: size * 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                size: size * 0.5,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: palette.bottom.withValues(alpha: 0.9),
                    offset: Offset(0, size * 0.03),
                    blurRadius: size * 0.04,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
