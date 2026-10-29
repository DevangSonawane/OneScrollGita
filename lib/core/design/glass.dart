import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../application/core_providers.dart';
import '../../application/ui_providers.dart';
import 'motion.dart';
import 'tokens.dart';
import 'typography.dart';

export '../../application/ui_providers.dart' show GlassMode;

/// Full glass needs shader filters (Impeller). Otherwise use frosted glass.
bool get _shadersSupported => ui.ImageFilter.isShaderFilterSupported;

/// Picks full, frosted or solid glass for the current context.
GlassMode resolveGlassMode(BuildContext context, WidgetRef ref) {
  final forced = ref.watch(glassModeOverrideProvider);
  if (forced != null) return forced;
  final simplified = ref.watch(
    settingsProvider.select((s) => s.simplifiedGlass),
  );
  if (simplified || MediaQuery.highContrastOf(context)) return GlassMode.solid;
  if (ref.watch(glassFrameGuardProvider) || !_shadersSupported) {
    return GlassMode.frosted;
  }
  return GlassMode.full;
}

enum GlassStrength { regular, light }

/// One backdrop sample shared by every [GlassShape] below it. Counts as one
/// surface in the glass budget (max 3 on screen).
class GlassLayer extends ConsumerWidget {
  const GlassLayer({
    super.key,
    required this.child,
    this.strength = GlassStrength.regular,
  });

  final Widget child;
  final GlassStrength strength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = resolveGlassMode(context, ref);
    final scoped = _GlassScope(mode: mode, strength: strength, child: child);
    if (mode != GlassMode.full) return scoped;
    final t = GlassTokens.of(context);
    final c = AppColors.of(context);
    final light = strength == GlassStrength.light;
    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        refractionHeight: t.refractionHeight,
        refractionAmount: light ? t.refractionAmount * 0.6 : t.refractionAmount,
        frost: light ? t.lightFrost : t.frost,
        highlight: t.highlight,
      ),
      defaultAppearance: LiquidGlassAppearance(
        tint: c.surface.withValues(
          alpha: light ? t.lightTintOpacity : t.tintOpacity,
        ),
      ),
      child: scoped,
    );
  }
}

class _GlassScope extends InheritedWidget {
  const _GlassScope({
    required this.mode,
    required this.strength,
    required super.child,
  });

  final GlassMode mode;
  final GlassStrength strength;

  static _GlassScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlassScope>();

  @override
  bool updateShouldNotify(_GlassScope old) =>
      old.mode != mode || old.strength != strength;
}

/// A glass shape inside a [GlassLayer]. Falls back to frosted or solid.
/// Never put reading text on it: only floating controls.
class GlassShape extends StatelessWidget {
  const GlassShape({
    super.key,
    required this.radius,
    required this.child,
    this.shadow = true,
  });

  final double radius;
  final Widget child;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final scope = _GlassScope.maybeOf(context);
    final mode = scope?.mode ?? GlassMode.solid;
    final light = scope?.strength == GlassStrength.light;
    final c = AppColors.of(context);
    final t = GlassTokens.of(context);
    final borderRadius = BorderRadius.circular(radius);
    final shadows = shadow ? Elevation.soft(c) : const <BoxShadow>[];
    switch (mode) {
      case GlassMode.full:
        return LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: radius),
          shadows: shadows,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: c.hairline.withValues(alpha: t.borderOpacity),
              ),
            ),
            child: child,
          ),
        );
      case GlassMode.frosted:
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: t.frostedBlur,
                sigmaY: t.frostedBlur,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface.withValues(
                    alpha: light
                        ? t.lightTintOpacity + 0.15
                        : t.tintOpacity + 0.1,
                  ),
                  borderRadius: borderRadius,
                  border: Border.all(color: c.hairline),
                ),
                child: child,
              ),
            ),
          ),
        );
      case GlassMode.solid:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: borderRadius,
            border: Border.all(color: c.hairline),
            boxShadow: shadows,
          ),
          child: child,
        );
    }
  }
}

/// Press feedback: scale 0.97 plus an 8% overlay; 2 px accent focus ring.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.radius = Radii.pill,
    this.semanticLabel,
    this.selected,
    this.button = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final String? semanticLabel;
  final bool? selected;
  final bool button;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = widget.onTap != null;
    final radius = BorderRadius.circular(widget.radius);
    return Semantics(
      button: widget.button,
      selected: widget.selected,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap?.call(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: AppDurations.instant,
            curve: AppCurves.standard,
            child: Opacity(
              opacity: enabled ? 1 : 0.38,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: _pressed
                      ? c.textPrimary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: _focused
                      ? Border.all(color: c.accent, width: 2)
                      : null,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A light-glass pill with a tap action (reader chapter and verse pills).
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.height = Touch.pillHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.s16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: height,
      child: Padding(
        padding: padding,
        child: Center(widthFactor: 1, child: child),
      ),
    );
    return GlassShape(
      radius: height / 2,
      child: onTap == null
          ? content
          : Pressable(
              onTap: onTap,
              semanticLabel: semanticLabel,
              radius: height / 2,
              child: content,
            ),
    );
  }
}

/// A round light-glass button (purport back button).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = Touch.minTarget,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassShape(
      radius: size / 2,
      child: Pressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        radius: size / 2,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: IconSizes.regular, color: c.textPrimary),
        ),
      ),
    );
  }
}

/// One row of a [showGlassMenu].
class GlassMenuItem<T> {
  const GlassMenuItem({
    required this.value,
    required this.icon,
    required this.label,
  });

  final T value;
  final IconData icon;
  final String label;
}

/// A floating liquid-glass menu under [anchor] (the button that opened it),
/// right-aligned to it. Returns the chosen value, or null when dismissed.
/// Counts as one glass surface while open.
Future<T?> showGlassMenu<T>(
  BuildContext anchor, {
  required List<GlassMenuItem<T>> items,
  String barrierLabel = 'Close menu',
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final topLeft = box.localToGlobal(Offset.zero);
  final screen = MediaQuery.sizeOf(anchor);
  final top = topLeft.dy + box.size.height + GlassMenuMetrics.gap;
  final right = (screen.width - topLeft.dx - box.size.width).clamp(
    Space.s8,
    screen.width,
  );
  final motion = Motion.of(anchor);
  return showGeneralDialog<T>(
    context: anchor,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.transparent,
    transitionDuration: motion.crossFade,
    pageBuilder: (context, _, _) => Stack(
      children: [
        Positioned(
          top: top,
          right: right,
          child: _GlassMenu<T>(items: items),
        ),
      ],
    ),
    transitionBuilder: (context, a, _, child) {
      final curved = CurvedAnimation(parent: a, curve: AppCurves.standard);
      final fade = FadeTransition(opacity: curved, child: child);
      if (Motion.of(context).reduced) return fade;
      return ScaleTransition(
        alignment: Alignment.topRight,
        scale: Tween(
          begin: GlassMenuMetrics.openScale,
          end: 1.0,
        ).animate(curved),
        child: fade,
      );
    },
  );
}

class _GlassMenu<T> extends StatelessWidget {
  const _GlassMenu({required this.items});

  final List<GlassMenuItem<T>> items;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Material(
        type: MaterialType.transparency,
        child: GlassLayer(
          child: GlassShape(
            radius: Radii.card,
            child: SizedBox(
              width: GlassMenuMetrics.width,
              child: Padding(
                padding: const EdgeInsets.all(Space.s4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.s12,
                          ),
                          child: Divider(
                            height: 1,
                            color: c.hairline.withValues(alpha: 0.6),
                          ),
                        ),
                      Pressable(
                        radius: Radii.card - Space.s4,
                        semanticLabel: items[i].label,
                        onTap: () => Navigator.of(context).pop(items[i].value),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: GlassMenuMetrics.rowHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.s12,
                              vertical: Space.s8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  items[i].icon,
                                  size: IconSizes.small,
                                  color: c.accentText,
                                ),
                                const SizedBox(width: Space.s12),
                                Expanded(
                                  child: Text(
                                    items[i].label,
                                    style: ui.label(size: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
