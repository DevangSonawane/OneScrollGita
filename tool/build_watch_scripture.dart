// Builds the Apple Watch's own copy of the verse text (docs/PRD_v10.md
// section 3) from assets/scripture/, so the watch reads offline and the
// phone never sends scripture over WatchConnectivity.
//
// Only the fields the watch shows are kept: id, chapter, verse numbers,
// label, Sanskrit, transliteration and the English and Hindi translations.
// Every kept string is copied exactly as it is; nothing is changed,
// shortened or added. Entry order is the app's order, so the daily verse
// index means the same entry on both devices.
//
// Refuses placeholder data. test/data/watch_scripture_test.dart fails if the
// output is out of date with assets/scripture/.
//
// Run from the repo root: dart run tool/build_watch_scripture.dart
import 'dart:convert';
import 'dart:io';

const watchScripturePath = 'ios/GitaWatch/Shared/gita_watch.json';

/// The watch file for [indexRaw] (chapters.json) and [chapterFiles]
/// (`chapter_NN.json` name to contents).
String buildWatchScripture(String indexRaw, Map<String, String> chapterFiles) {
  final index = jsonDecode(indexRaw) as Map<String, dynamic>;
  if (index['isPlaceholder'] != false) {
    throw StateError('assets/scripture is placeholder data; refusing.');
  }
  final source = index['source'] as Map<String, dynamic>;
  final entries = <Map<String, Object?>>[];
  final chapters = (index['chapters'] as List).cast<Map<String, dynamic>>();
  for (final ch in chapters) {
    final n = ch['number'] as int;
    final name = 'chapter_${n.toString().padLeft(2, '0')}.json';
    final raw = chapterFiles[name];
    if (raw == null) throw StateError('Missing $name');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['isPlaceholder'] == true) {
      throw StateError('$name is placeholder data; refusing.');
    }
    final list = (json['entries'] as List).cast<Map<String, dynamic>>();
    if (list.length != ch['entryCount']) {
      throw StateError(
        '$name has ${list.length} entries, '
        'chapters.json says ${ch['entryCount']}',
      );
    }
    for (final e in list) {
      final t = e['translation'] as Map<String, dynamic>;
      entries.add({
        'id': e['id'],
        'chapter': e['chapter'],
        'verseStart': e['verseStart'],
        'verseEnd': e['verseEnd'],
        'label': e['label'],
        'sanskrit': e['sanskrit'],
        'transliteration': e['transliteration'],
        'en': t['en'],
        'hi': t['hi'],
      });
    }
  }
  final out = {
    'isPlaceholder': false,
    'datasetVersion': source['datasetVersion'],
    'attribution': source['attribution'],
    'entries': entries,
  };
  return '${jsonEncode(out)}\n';
}

/// Reads assets/scripture/ from the working directory.
String buildFromAssets() {
  final dir = Directory('assets/scripture');
  final files = <String, String>{
    for (final f in dir.listSync().whereType<File>())
      if (RegExp(r'chapter_\d{2}\.json$').hasMatch(f.path))
        f.uri.pathSegments.last: f.readAsStringSync(),
  };
  return buildWatchScripture(
    File('${dir.path}/chapters.json').readAsStringSync(),
    files,
  );
}

void main() {
  final out = buildFromAssets();
  File(watchScripturePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(out);
  final count =
      ((jsonDecode(out) as Map<String, dynamic>)['entries'] as List).length;
  stdout.writeln(
    'Wrote $watchScripturePath: $count entries, '
    '${out.length} characters.',
  );
}
