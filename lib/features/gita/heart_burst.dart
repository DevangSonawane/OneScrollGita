import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';

/// The heart that pops where the reader double-tapped.
class HeartBurst extends StatefulWidget {
  const HeartBurst({super.key, required this.position, required this.onDone});

  final Offset position;
  final VoidCallback onDone;

  @override
  State<HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<HeartBurst>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_c.isAnimating && _c.value == 0) {
      _c.forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
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
    final reduced = Motion.of(context).reduced;
    const size = 96.0;
    return Positioned(
      left: widget.position.dx - size / 2,
      top: widget.position.dy - size / 2,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = _c.value;
              final scale = reduced
                  ? 1.0
                  : t < 0.3
                  ? Curves.easeOutBack.transform(t / 0.3) * 1.15
                  : 1.15 - 0.15 * ((t - 0.3) / 0.7);
              final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
              return Opacity(
                opacity: opacity.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, reduced ? 0 : -24 * t),
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: Icon(
              Icons.favorite_rounded,
              size: size,
              color: c.accent,
              shadows: [Shadow(color: c.shadow, blurRadius: 16)],
            ),
          ),
        ),
      ),
    );
  }
}
