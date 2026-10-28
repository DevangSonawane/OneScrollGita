// Imports Bhagavad-gītā As It Is from the vedabase.cc API
// (https://vedabase.cc/en/api) into assets/scripture/, English and Hindi.
//
// The app stays offline: this runs at build time only, and the app ships the
// JSON it writes. Text is copied verbatim; only the API's Markdown is turned
// into the app's `<i>`/`<b>` markup. Responses are cached in
// tool/.cache/vedabase_cc/ and requests stay under the API's limit of
// 120 a minute, so a re-run only fetches what is missing.
//
// Run: dart run tool/import_vedabase.dart
import 'dart:convert';
import 'dart:io';

import 'package:versescroll/data/scripture/scripture_validator.dart';
import 'package:versescroll/domain/markup.dart';
import 'package:versescroll/domain/verse_navigation.dart';

const _api = 'https://vedabase.cc/api/v1';
const _gap = Duration(milliseconds: 600); // 100 requests a minute
const attribution =
    'Texts of Śrīla Prabhupāda from vedabase.cc (https://vedabase.cc), used '
    'with permission and reproduced without alteration.';

final _cacheDir = Directory('tool/.cache/vedabase_cc');
final _client = HttpClient()..userAgent = 'GitaOfflineApp-importer/1.0';
DateTime? _last;

/// GET [path] as JSON, cached. Returns null on 404 (no text in that language).
Future<Map<String, dynamic>?> _get(String path, String cacheName) async {
  final file = File('${_cacheDir.path}/$cacheName.json');
  if (file.existsSync()) {
    final cached = file.readAsStringSync();
    return cached == 'null' ? null : jsonDecode(cached) as Map<String, dynamic>;
  }
  for (var attempt = 1; ; attempt++) {
    final last = _last;
    if (last != null) {
      final wait = _gap - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _last = DateTime.now();
    try {
      final res = await (await _client.getUrl(Uri.parse('$_api/$path'))).close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 429) {
        final retry = int.tryParse(res.headers.value('retry-after') ?? '') ?? 30;
        stderr.writeln('rate limited, waiting ${retry}s');
        await Future<void>.delayed(Duration(seconds: retry));
        continue;
      }
      file.parent.createSync(recursive: true);
      if (res.statusCode == 404) {
        file.writeAsStringSync('null');
        return null;
      }
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode} for $path: $body');
      }
      file.writeAsStringSync(body);
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      if (attempt >= 5) rethrow;
      stderr.writeln('retry $path ($e)');
      await Future<void>.delayed(Duration(seconds: 5 * attempt));
    }
  }
}

/// The API's Markdown (`**bold**`, `*italic*`) → balanced `<b>`/`<i>`.
String _markup(String md) {
  final s = md
      .replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*', dotAll: true),
        (m) => '<b>${m[1]}</b>',
      )
      .replaceAllMapped(
        RegExp(r'\*(.+?)\*', dotAll: true),
        (m) => '<i>${m[1]}</i>',
      );
  final out = StringBuffer();
  for (final seg in parseMarkup(s)) {
    var t = seg.text;
    if (seg.bold) t = '<b>$t</b>';
    if (seg.italic) t = '<i>$t</i>';
    out.write(t);
  }
  return out.toString().trim();
}

String _plain(String md) => stripMarkup(_markup(md)).trim();

final _quotePrefix = RegExp(r'^\s*>\s?');

/// Verse lines: drop the "> " prefixes and blank separators.
List<String> _lines(String? md) => [
  for (final l in (md ?? '').split('\n'))
    if (l.replaceFirst(_quotePrefix, '').trim().isNotEmpty)
      _plain(l.replaceFirst(_quotePrefix, '')),
];

final _devanagari = RegExp(r'[ऀ-ॿ]');

List<Map<String, String>>? _purport(String? md) {
  if (md == null || md.trim().isEmpty) return null;
  final blocks = <Map<String, String>>[];
  for (final para in md.split(RegExp(r'\n\s*\n'))) {
    final lines = para.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) continue;
    if (lines.every(_quotePrefix.hasMatch)) {
      final text = lines
          .map((l) => _markup(l.replaceFirst(_quotePrefix, '')))
          .join('\n');
      blocks.add({
        'type': _devanagari.hasMatch(text) && !RegExp('[a-zA-Z]').hasMatch(text)
            ? 'sanskrit'
            : 'quote',
        'text': text,
      });
    } else {
      blocks.add({'type': 'p', 'text': _markup(lines.join(' '))});
    }
  }
  return blocks.isEmpty ? null : blocks;
}

String _chapterTitle(String title) =>
    title.replaceFirst(RegExp(r'^(Chapter|अध्याय)\s*\d+\s*:\s*'), '').trim();

List<Map<String, dynamic>> _chaptersOf(Map<String, dynamic>? toc) => [
  for (final n in (toc?['children'] as List? ?? const []))
    if ((n as Map<String, dynamic>)['children'] != null) n,
];

Future<void> main() async {
  final tocEn = (await _get('books/bg/toc?lang=en', 'toc_en'))!;
  final tocHi = await _get('books/bg/toc?lang=hi', 'toc_hi');
  final hiTitles = {
    for (final c in _chaptersOf(tocHi))
      c['ref']: _chapterTitle(c['title'] as String),
  };

  final outDir = Directory('assets/scripture')..createSync(recursive: true);
  final checksums = <String, String>{};
  final chapters = <Map<String, dynamic>>[];
  final perChapter = <Map<String, dynamic>>[];

  for (final ch in _chaptersOf(tocEn)) {
    final c = int.parse((ch['ref'] as String).split('/')[1]);
    final entries = <Map<String, dynamic>>[];
    var verses = 0;
    for (final node in ch['children'] as List) {
      final ref = (node as Map<String, dynamic>)['ref'] as String; // bg/1/16-18
      final part = ref.split('/').last;
      final start = int.parse(part.split('-').first);
      final end = int.parse(part.split('-').last);
      verses = end;
      final en = (await _get('verse/$ref?lang=en', 'en/$ref'))!;
      final hi = await _get('verse/$ref?lang=hi', 'hi/$ref');
      final hiTranslation = hi?['translation'] as String?;
      final purportEn = _purport(en['purport'] as String?);
      final purportHi = _purport(hi?['purport'] as String?);
      entries.add({
        'id': formatVerseId(c, start, end),
        'chapter': c,
        'verseStart': start,
        'verseEnd': end,
        'label': formatLabel(c, start, end),
        'sanskrit': _lines(en['devanagari'] as String?),
        'transliteration': _lines(en['verse_text'] as String?),
        'translation': {
          'en': _plain(en['translation'] as String),
          'hi': hiTranslation == null || hiTranslation.trim().isEmpty
              ? null
              : _plain(hiTranslation),
        },
        'purport': purportEn == null && purportHi == null
            ? null
            : {'en': purportEn, 'hi': purportHi},
        'synonyms': null,
        'sourceUrl': en['url'],
      });
    }
    final raw = '${const JsonEncoder.withIndent(' ').convert({
      'chapter': c,
      'entries': entries,
    })}\n';
    final file = chapterFileName(c);
    File('${outDir.path}/$file').writeAsStringSync(raw);
    checksums[file] = sha256Of(raw);
    chapters.add({
      'number': c,
      'titleEn': _chapterTitle(ch['title'] as String),
      'titleHi': hiTitles[ch['ref']],
      'verseCount': verses,
      'entryCount': entries.length,
    });
    perChapter.add({'chapter': c, 'verses': verses, 'entries': entries.length});
    stdout.writeln('chapter $c: ${entries.length} entries, $verses verses');
  }

  final index = {
    'isPlaceholder': false,
    'source': {
      'name': 'vedabase.cc',
      'edition':
          'Bhagavad-gītā As It Is, by His Divine Grace A.C. Bhaktivedanta '
          'Swami Prabhupāda',
      'rightsHolder': 'The Bhaktivedanta Book Trust',
      'attribution': attribution,
      'datasetVersion':
          'vedabase-cc-${DateTime.now().toUtc().toIso8601String().substring(0, 10)}',
      'checksums': checksums,
    },
    'chapters': chapters,
  };
  File('${outDir.path}/chapters.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(index)}\n',
  );
  File('tool/expected_counts.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'approved': false,
      'note': 'Counts taken from the vedabase.cc table of contents. Check '
          'them against the printed edition, then set approved to true.',
      'chapters': chapterCount,
      'totalVerses': perChapter.fold<int>(0, (s, c) => s + (c['verses'] as int)),
      'perChapter': perChapter,
    })}\n',
  );
  _client.close();
  stdout.writeln('Done. Now run: dart run tool/validate_scripture.dart');
}
