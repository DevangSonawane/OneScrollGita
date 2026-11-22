import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ui_providers.dart';
import 'glass.dart';
import 'tokens.dart';

/// Apple's own Liquid Glass controls (ios/Runner/NativeGlass.swift) are
/// used on iOS 26 and later, unless glass is simplified or high contrast
/// is on. Everywhere else the Flutter versions stay (docs/PRD_v7.md 4e).
bool useNativeGlass(BuildContext context, WidgetRef ref) =>
    ref.watch(nativeTabBarSupportedProvider) &&
    resolveGlassMode(context, ref) != GlassMode.solid;

const nativeViewPrefix = 'com.onescrollgita.app/';

/// A UIKit platform view that takes its state as one map, reports its
/// size, and sends events back. Shared by every native glass control.
class NativePlatformView extends StatefulWidget {
  const NativePlatformView({
    super.key,
    required this.viewType,
    required this.params,
    required this.onEvent,
    required this.size,
    this.sizeFromNative = (width: false, height: false),
  });

  /// Without the [nativeViewPrefix].
  final String viewType;
  final Map<String, Object?> params;
  final void Function(String method, Object? args) onEvent;

  /// The size to use (and, until UIKit reports, the starting size).
  final Size size;

  /// Which sides follow the size UIKit reports.
  final ({bool width, bool height}) sizeFromNative;

  @override
  State<NativePlatformView> createState() => _NativePlatformViewState();
}

class _NativePlatformViewState extends State<NativePlatformView> {
  MethodChannel? _channel;
  String? _sent;
  Size? _reported;

  Map<String, Object?> _params() => {
    ...widget.params,
    'dark': Theme.of(context).brightness == Brightness.dark,
    'tint': AppColors.of(context).accent.toARGB32(),
  };

  void _sync() {
    final channel = _channel;
    if (channel == null) return;
    final params = _params();
    final key = jsonEncode(params);
    if (key == _sent) return;
    final first = _sent == null;
    _sent = key;
    // The first update also asks UIKit to report its size again.
    channel
        .invokeMethod<void>('update', {...params, 'measure': first})
        .catchError((Object _) {
          // The view was not ready or is gone: send everything next time.
          if (_sent == key) _sent = null;
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(NativePlatformView old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _created(int id) {
    final channel = MethodChannel('$nativeViewPrefix${widget.viewType}_$id');
    channel.setMethodCallHandler((call) async {
      if (!mounted) return;
      final a = call.arguments;
      if (call.method == 'size' && a is Map) {
        final w = (a['width'] as num?)?.toDouble();
        final h = (a['height'] as num?)?.toDouble();
        if (w != null && h != null && w > 0 && h > 0) {
          setState(() => _reported = Size(w, h));
        }
        return;
      }
      widget.onEvent(call.method, a);
    });
    _channel = channel;
    _sent = null;
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final r = _reported;
    final fromNative = widget.sizeFromNative;
    return SizedBox(
      width: fromNative.width && r != null ? r.width : widget.size.width,
      height: fromNative.height && r != null ? r.height : widget.size.height,
      child: UiKitView(
        viewType: '$nativeViewPrefix${widget.viewType}',
        creationParams: _params(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
        // Touches go straight to UIKit so controls respond like system ones.
        gestureRecognizers: {
          const Factory<OneSequenceGestureRecognizer>(
            EagerGestureRecognizer.new,
          ),
        },
      ),
    );
  }
}

/// One entry of a native menu or action sheet.
class NativeMenuItem {
  const NativeMenuItem({
    required this.id,
    required this.title,
    this.symbol,
    this.destructive = false,
  });

  final String id;
  final String title;

  /// SF Symbol name.
  final String? symbol;
  final bool destructive;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'symbol': ?symbol,
    'destructive': destructive,
  };
}

enum NativeButtonStyle { glass, prominentGlass, plain }

/// Apple's UIButton: glass, tinted glass or plain. With [menu] a tap opens
/// the native menu and [onMenu] gets the chosen id; otherwise [onTap].
class NativeGlassButton extends StatelessWidget {
  const NativeGlassButton({
    super.key,
    required this.semanticLabel,
    this.title,
    this.symbol,
    this.symbolTrailing = false,
    this.style = NativeButtonStyle.glass,
    this.foreground,
    this.height = Touch.minTarget,
    this.width,
    this.onTap,
    this.menu,
    this.onMenu,
  });

  final String semanticLabel;
  final String? title;

  /// SF Symbol name.
  final String? symbol;
  final bool symbolTrailing;
  final NativeButtonStyle style;
  final Color? foreground;
  final double height;

  /// Fixed width; null follows the button's own size.
  final double? width;
  final VoidCallback? onTap;
  final List<NativeMenuItem>? menu;
  final ValueChanged<String>? onMenu;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: NativePlatformView(
        viewType: 'native_button',
        size: Size(width ?? height, height),
        sizeFromNative: (width: width == null, height: false),
        params: {
          'title': ?title,
          'symbol': ?symbol,
          'trailing': symbolTrailing,
          'style': style.name,
          'label': semanticLabel,
          if (foreground != null) 'foreground': foreground!.toARGB32(),
          if (menu != null) 'menu': [for (final m in menu!) m.toMap()],
        },
        onEvent: (method, args) {
          if (method == 'tap') onTap?.call();
          if (method == 'menu' && args is String) onMenu?.call(args);
        },
      ),
    );
  }
}

/// Apple's action sheet (iOS 26+ glass), for long-press menus. Returns the
/// chosen item's id, or null when cancelled.
Future<String?> showNativeActions({
  String? title,
  required List<NativeMenuItem> actions,
  @visibleForTesting MethodChannel? channel,
}) async {
  final ch =
      channel ?? const MethodChannel('${nativeViewPrefix}native_actions');
  try {
    return await ch.invokeMethod<String>('show', {
      'title': ?title,
      'actions': [for (final a in actions) a.toMap()],
    });
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
