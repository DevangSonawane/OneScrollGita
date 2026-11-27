import 'package:flutter/services.dart';

/// The native side of the Apple Watch companion (docs/PRD_v10.md):
/// ios/Runner/WatchSync.swift, `WatchSyncPlugin`. It stores the latest
/// state and hands it to the watch through WatchConnectivity's application
/// context (latest state only, delivered when the watch can take it).
///
/// Only the iOS app answers; elsewhere every call is a quiet no-op.
class WatchChannel {
  WatchChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.onescrollgita.app/watch');

  final MethodChannel _channel;

  /// Sends the small state the watch mirrors. Never throws.
  Future<void> update(Map<String, Object?> state) async {
    try {
      await _channel.invokeMethod<void>('update', state);
    } on MissingPluginException {
      // Not iOS, or the plugin is not registered (tests).
    } on PlatformException {
      // The watch catches up on the next change.
    }
  }
}
