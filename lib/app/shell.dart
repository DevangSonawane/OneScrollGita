import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../application/ui_providers.dart';
import '../core/design/glass_nav_bar.dart';
import '../core/design/motion.dart';
import '../core/design/tokens.dart';

const _items = [
  GlassNavItem(
    label: 'Home',
    icon: LucideIcons.house,
    selectedIcon: LucideIcons.house,
  ),
  GlassNavItem(
    label: 'Gita',
    icon: LucideIcons.book,
    selectedIcon: LucideIcons.book,
  ),
  GlassNavItem(
    label: 'Profile',
    icon: LucideIcons.user,
    selectedIcon: LucideIcons.user,
  ),
];

/// Three tabs that keep their own state, with the floating glass pill above
/// the content.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onSelect(WidgetRef ref, int index) {
    ref.read(navBarVisibleProvider.notifier).show();
    if (index == shell.currentIndex) {
      if (index == 1) return; // reader: does nothing
      ref.read(tabReselectProvider.notifier).reselect(index);
      shell.goBranch(index, initialLocation: true);
      return;
    }
    shell.goBranch(index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = Motion.of(context);
    final visible =
        ref.watch(navBarVisibleProvider) ||
        !motion.allowNavHide ||
        shell.currentIndex == 0; // always visible on Home
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: shell),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom + NavBarMetrics.bottomGap,
            child: Center(
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 0.4),
                  duration: motion.navHide,
                  curve: AppCurves.standard,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: motion.navHide,
                    curve: AppCurves.standard,
                    child: GlassNavBar(
                      items: _items,
                      currentIndex: shell.currentIndex,
                      onSelect: (i) => _onSelect(ref, i),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!visible)
            // Tap near the bottom brings the pill back.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottom + 28,
              child: Semantics(
                button: true,
                label: 'Show navigation',
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => ref.read(navBarVisibleProvider.notifier).show(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
