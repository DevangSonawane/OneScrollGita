// Validates assets/messages/messages.json (PRD_v2 section 6).
//
// Run: dart run tool/validate_messages.dart
// Exits with code 1 on any error. Never modifies data.
import 'dart:io';

import 'package:versescroll/data/content/content_validator.dart';

void main() {
  final file = File('assets/messages/messages.json');
  if (!file.existsSync()) {
    stderr.writeln('Missing assets/messages/messages.json. Run from the repo root.');
    exit(1);
  }
  final report = validateMessages(file.readAsStringSync());
  stdout.writeln(report);
  stdout.writeln('Size: ${file.lengthSync()} bytes');
  if (!report.ok) exit(1);
}
