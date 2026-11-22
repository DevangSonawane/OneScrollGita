import 'package:flutter/material.dart';

import 'native_glass.dart';
import 'tokens.dart';

/// One tab of the native bar: its name and SF Symbol names.
class NativeTabItem {
  const NativeTabItem({
    required this.label,
    required this.symbol,
    this.selectedSymbol,
  });

  final String label;
  final String symbol;
  final String? selectedSymbol;

  Map<String, Object?> toMap() => {
    'label': label,
    'symbol': symbol,
    'selectedSymbol': ?selectedSymbol,
  };
}

/// What the docked mini player shows.
class NativeMiniPlayer {
  const NativeMiniPlayer({
    required this.numeral,
    required this.title,
    required this.subtitle,
    required this.playing,
  });

  final String numeral;
  final String title;
  final String subtitle;
  final bool playing;

  Map<String, Object?> toMap() => {
    'numeral': numeral,
    'title': title,
    'subtitle': subtitle,
    'playing': playing,
  };
}

/// Apple's own tab bar: UIKit's `UITabBarController` bar (Liquid Glass on
/// iOS 26), shown through a platform view (ios/Runner/NativeGlass.swift).
/// It spans the screen width at the bottom edge and UIKit lays it out, as
/// in system apps. The Shravan mini player docks into it as the bar's
/// bottom accessory. Only used on iOS 26 and later; see docs/PRD_v7.md 4e.
class NativeTabBar extends StatelessWidget {
  const NativeTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    this.miniPlayer,
    this.onMiniPlayer,
  });

  static const viewType = '${nativeViewPrefix}native_tab_bar';

  final List<NativeTabItem> items;

  /// The selected tab.
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// The docked mini player, while audio is loaded.
  final NativeMiniPlayer? miniPlayer;

  /// Mini player taps: `open`, `toggle` or `close`.
  final ValueChanged<String>? onMiniPlayer;

  @override
  Widget build(BuildContext context) {
    // Until UIKit reports, assume the pill plus the home-indicator area.
    final guess = NavBarMetrics.height + MediaQuery.paddingOf(context).bottom;
    return NativePlatformView(
      viewType: 'native_tab_bar',
      size: Size(MediaQuery.sizeOf(context).width, guess),
      sizeFromNative: (width: false, height: true),
      params: {
        'items': [for (final i in items) i.toMap()],
        'selected': currentIndex,
        if (miniPlayer != null) 'accessory': miniPlayer!.toMap(),
      },
      onEvent: (method, args) {
        if (method == 'select' && args is int) onSelect(args);
        if (method == 'accessory' && args is String) onMiniPlayer?.call(args);
      },
    );
  }
}
