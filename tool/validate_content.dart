// Validates chapter summaries and the theme map (PRD_v2 sections 9, 11).
//
// Run: dart run tool/validate_content.dart
// Exits with code 1 on any error. Never modifies data.
import 'dart:convert';
import 'dart:io';

import 'package:versescroll/data/content/content_validator.dart';

void main() {
  var failed = false;
  final summaries = File('assets/summaries/summaries.json');
  if (summaries.existsSync()) {
    final r = validateSummaries(summaries.readAsStringSync());
    stdout.writeln('Summaries:\n$r\n');
    failed |= !r.ok;
  } else {
    stdout.writeln('Summaries: missing assets/summaries/summaries.json');
    failed = true;
  }

  final ids = <String>{};
  for (var c = 1; c <= 18; c++) {
    final f = File('assets/scripture/chapter_${c.toString().padLeft(2, '0')}.json');
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final e in json['entries'] as List) {
      ids.add((e as Map)['id'] as String);
    }
  }
  final themes = File('assets/search/themes.json');
  if (themes.existsSync()) {
    final r = validateThemes(themes.readAsStringSync(), ids);
    stdout.writeln('Themes:\n$r');
    failed |= !r.ok;
  } else {
    stdout.writeln('Themes: missing assets/search/themes.json');
    failed = true;
  }
  if (failed) exit(1);
}
