import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'glass.dart';
import 'motion.dart';
import 'tokens.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The floating Liquid Glass navigation pill with a droplet selection that
/// follows the finger and settles with a short spring.
class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar>
    with SingleTickerProviderStateMixin {
  /// Droplet centre measured in tabs (0 = first tab).
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.currentIndex.toDouble(),
  );
  double _velocity = 0; // tabs per second, for the stretch
  bool _dragging = false;
  int _hoverIndex = 0;

  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 320,
    ratio: 0.78,
  );

  @override
  void initState() {
    super.initState();
    _hoverIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(GlassNavBar old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.currentIndex != old.currentIndex) {
      _settle(widget.currentIndex, 0);
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _settle(int index, double velocity) {
    _hoverIndex = index;
    if (Motion.of(context).reduced) {
      _pos.animateTo(
        index.toDouble(),
        duration: AppDurations.fast,
        curve: AppCurves.standard,
      );
      return;
    }
    _pos.animateWith(
      SpringSimulation(_spring, _pos.value, index.toDouble(), velocity),
    );
  }

  void _select(int index, {double velocity = 0}) {
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();
    }
    _settle(index, velocity);
    widget.onSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final screen = MediaQuery.sizeOf(context).width;
    final width = (screen - NavBarMetrics.sideMargin * 2).clamp(
      NavBarMetrics.minTabWidth * widget.items.length,
      NavBarMetrics.maxWidth,
    );
    final n = widget.items.length;
    const inset = 6.0;
    final tabWidth = (width - inset * 2) / n;

    double toTabs(double dx) =>
        ((dx - inset) / tabWidth - 0.5).clamp(0.0, n - 1.0);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        width: width,
        height: NavBarMetrics.height,
        child: GlassLayer(
          child: GlassShape(
            radius: NavBarMetrics.height / 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                _dragging = true;
                _pos.stop();
                _pos.value = toTabs(d.localPosition.dx);
              },
              onHorizontalDragUpdate: (d) {
                _pos.value = toTabs(d.localPosition.dx);
                setState(() => _velocity = d.primaryDelta! / tabWidth * 60);
                final hover = _pos.value.round();
                if (hover != _hoverIndex) {
                  _hoverIndex = hover;
                  HapticFeedback.selectionClick();
                }
              },
              onHorizontalDragEnd: (d) {
                _dragging = false;
                final v = d.primaryVelocity! / tabWidth;
                setState(() => _velocity = 0);
                final target = _pos.value.round();
                _settle(target, v);
                if (target != widget.currentIndex) widget.onSelect(target);
              },
              child: Stack(
                children: [
                  // Droplet.
                  AnimatedBuilder(
                    animation: _pos,
                    builder: (context, _) {
                      final stretch = (_velocity.abs() / 40).clamp(0.0, 0.22);
                      final w = tabWidth * (1 + stretch);
                      final h =
                          (NavBarMetrics.height - inset * 2) *
                          (1 - stretch * 0.25);
                      final left =
                          inset + _pos.value * tabWidth - (w - tabWidth) / 2;
                      return Positioned(
                        left: left,
                        top: (NavBarMetrics.height - h) / 2,
                        width: w,
                        height: h,
                        child: ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.accentSoft.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(h / 2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: inset),
                    child: Row(
                      children: [
                        for (var i = 0; i < n; i++)
                          Expanded(
                            child: _Tab(
                              item: widget.items[i],
                              selected: i == widget.currentIndex,
                              index: i,
                              count: n,
                              onTap: () => _select(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final iconColor = selected ? c.accent : c.textSecondary;
    return Semantics(
      label: '${item.label}, tab ${index + 1} of $count',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        button: false,
        child: SizedBox(
          height: NavBarMetrics.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey(selected),
                  size: IconSizes.regular,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom padding a scrollable needs so its end clears the floating pill.
double navBarInset(BuildContext context) =>
    NavBarMetrics.height +
    NavBarMetrics.bottomGap +
    MediaQuery.paddingOf(context).bottom +
    Space.s16;
