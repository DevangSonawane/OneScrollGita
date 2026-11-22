import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// The major iOS version, or null when not running on iOS.
int? iosMajorVersion() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
  if (!Platform.isIOS) return null;
  return parseIosMajorVersion(Platform.operatingSystemVersion);
}

/// Reads the major version from iOS's version string, for example
/// "Version 26.1 (Build 23B85)" or "26.1".
@visibleForTesting
int? parseIosMajorVersion(String raw) {
  final match = RegExp(r'(\d+)(?:\.\d+)*').firstMatch(raw);
  return match == null ? null : int.tryParse(match.group(1)!);
}
