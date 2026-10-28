// Validates assets/scripture/ against tool/expected_counts.json.
//
// Run: dart run tool/validate_scripture.dart [--release]
// Exits with code 1 on any error. Never modifies data.
import 'dart:io';

import 'package:versescroll/data/scripture/scripture_validator.dart';

void main(List<String> args) {
  final release = args.contains('--release');
  final dir = Directory('assets/scripture');
  final indexFile = File('${dir.path}/chapters.json');
  final expectedFile = File('tool/expected_counts.json');
  if (!indexFile.existsSync() || !expectedFile.existsSync()) {
    stderr.writeln('Missing assets/scripture/chapters.json or '
        'tool/expected_counts.json. Run from the repo root.');
    exit(1);
  }
  final files = <String, String>{
    for (final f in dir.listSync().whereType<File>())
      if (RegExp(r'chapter_\d{2}\.json$').hasMatch(f.path))
        f.uri.pathSegments.last: f.readAsStringSync(),
  };
  final report = validateScripture(
    indexRaw: indexFile.readAsStringSync(),
    chapterFiles: files,
    expectedCountsRaw: expectedFile.readAsStringSync(),
    release: release,
  );
  stdout.writeln(report);
  exit(report.ok ? 0 : 1);
}
