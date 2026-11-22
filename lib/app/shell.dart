import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../application/audio_providers.dart';
import '../application/ui_providers.dart';
import '../core/config/audio_config.dart';
import '../core/design/glass_nav_bar.dart';
import '../core/design/motion.dart';
import '../core/design/native_glass.dart';
import '../core/design/native_tab_bar.dart';
import '../core/design/tokens.dart';
import '../features/listen/listen_widgets.dart';

/// Branch indexes in the router (never reordered: other code stores them).
abstract final class TabBranch {
  static const home = 0;
  static const gita = 1;
  static const profile = 2;
  static const listen = 3;
}

/// One tab as shown, in the order the owner chose (2026-11-22):
/// Home, Gita, Listen, Profile.
class _Tab {
  const _Tab({
    required this.branch,
    required this.label,
    required this.icon,
    required this.symbol,
    this.selectedSymbol,
  });

  final int branch;
  final String label;
  final IconData icon;
  final String symbol;
  final String? selectedSymbol;
}

List<_Tab> _tabs({required bool listen, required bool playing}) => [
  const _Tab(
    branch: TabBranch.home,
    label: 'Home',
    icon: LucideIcons.house,
    symbol: 'house',
    selectedSymbol: 'house.fill',
  ),
  const _Tab(
    branch: TabBranch.gita,
    label: 'Gita',
    icon: LucideIcons.book,
    symbol: 'book',
    selectedSymbol: 'book.fill',
  ),
  if (listen)
    _Tab(
      branch: TabBranch.listen,
      label: 'Listen',
      icon: playing ? LucideIcons.audio_lines : LucideIcons.headphones,
      symbol: playing ? 'waveform' : 'headphones',
    ),
  const _Tab(
    branch: TabBranch.profile,
    label: 'Profile',
    icon: LucideIcons.user,
    symbol: 'person.crop.circle',
    selectedSymbol: 'person.crop.circle.fill',
  ),
];

/// Tabs that keep their own state. On iOS 26+ the bar is Apple's own tab
/// bar with the mini player docked in it; elsewhere the floating Flutter
/// glass pill with the mini player above it (docs/PRD_v7.md section 4e).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onSelect(WidgetRef ref, int branch) {
    ref.read(navBarVisibleProvider.notifier).show();
    if (branch == shell.currentIndex) {
      if (branch == TabBranch.gita) return; // reader: does nothing
      ref.read(tabReselectProvider.notifier).reselect(branch);
      shell.goBranch(branch, initialLocation: true);
      return;
    }
    shell.goBranch(branch);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = Motion.of(context);
    final visible =
        ref.watch(navBarVisibleProvider) ||
        !motion.allowNavHide ||
        shell.currentIndex == TabBranch.home; // always visible on Home
    final bottom = MediaQuery.paddingOf(context).bottom;
    final listen = AudioConfig.enabled;
    final audio = listen
        ? ref.watch(audioControllerProvider)
        : const AudioUiState();
    final audioActive = listen && audio.active;
    final tabs = _tabs(listen: listen, playing: audio.playing && audio.active);
    final shown = tabs.indexWhere((t) => t.branch == shell.currentIndex);
    final miniInset = audioActive
        ? PlayerMetrics.miniHeight + PlayerMetrics.miniGap
        : 0.0;

    final native = useNativeGlass(context, ref);
    Widget bar;
    if (native) {
      final text = miniPlayerText(audio);
      bar = NativeTabBar(
        items: [
          for (final t in tabs)
            NativeTabItem(
              label: t.label,
              symbol: t.symbol,
              selectedSymbol: t.selectedSymbol,
            ),
        ],
        currentIndex: shown,
        onSelect: (i) => _onSelect(ref, tabs[i].branch),
        miniPlayer: audioActive
            ? NativeMiniPlayer(
                numeral: '${audio.chapter ?? 1}',
                title: text.title,
                subtitle: text.subtitle,
                playing: audio.playing,
              )
            : null,
        onMiniPlayer: (action) {
          final controller = ref.read(audioControllerProvider.notifier);
          switch (action) {
            case 'open':
              openNowPlaying(context, ref.read(audioControllerProvider));
            case 'toggle':
              controller.toggle();
            case 'close':
              controller.stop();
          }
        },
      );
    } else {
      final screen = MediaQuery.sizeOf(context).width;
      bar = GlassNavBar(
        items: [
          for (final t in tabs)
            GlassNavItem(label: t.label, icon: t.icon, selectedIcon: t.icon),
        ],
        currentIndex: shown,
        onSelect: (i) => _onSelect(ref, tabs[i].branch),
        width: (screen - NavBarMetrics.sideMargin * 2).clamp(
          NavBarMetrics.minTabWidth * tabs.length,
          NavBarMetrics.maxWidth,
        ),
      );
      if (audioActive) {
        bar = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            const SizedBox(height: PlayerMetrics.miniGap),
            bar,
          ],
        );
      }
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: MiniPlayerInset(height: miniInset, child: shell),
          ),
          Positioned(
            left: 0,
            right: 0,
            // Apple's bar includes the home-indicator area, so it sits on the
            // screen edge like in system apps.
            bottom: native ? 0 : bottom + NavBarMetrics.bottomGap,
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
                    child: bar,
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
