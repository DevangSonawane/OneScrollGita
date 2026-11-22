import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native side of iOS Home Screen Quick Actions
/// (ios/Runner/AppDelegate.swift, `QuickActionsPlugin`). Only the iOS app
/// answers; elsewhere this reports nothing.
class QuickActionsChannel {
  QuickActionsChannel({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('com.onescrollgita.app/quick_actions') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'action' && call.arguments is String) {
        _actions.add(call.arguments as String);
      }
    });
  }

  final MethodChannel _channel;
  final _actions = StreamController<String>.broadcast();

  /// Shortcut types chosen while the app is running or in the background.
  Stream<String> get actions => _actions.stream;

  /// The shortcut that launched the app from terminated, if any (read once).
  Future<String?> takeInitialAction() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      return await _channel.invokeMethod<String>('takeInitialAction');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
