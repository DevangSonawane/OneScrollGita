// Generates the clearly labelled PLACEHOLDER dataset in assets/scripture/.
//
// This is the development importer. It contains no scripture text: every
// Sanskrit line, translation and purport is a marked placeholder so the app
// can be built and tested before the authorised source files arrive.
// The real importer (tool/import_source.dart) replaces this output.
//
// Run: dart run tool/generate_placeholder.dart
import 'dart:convert';
import 'dart:io';

import 'package:versescroll/data/scripture/scripture_validator.dart';
import 'package:versescroll/domain/verse_navigation.dart';

// Development structure only. Counts must be confirmed against the
// authorised source in tool/expected_counts.json before release.
const _chapters = <(String, int)>[
  ('Observing the Armies on the Battlefield of Kurukṣetra', 47),
  ('Contents of the Gītā Summarized', 72),
  ('Karma-yoga', 43),
  ('Transcendental Knowledge', 42),
  ('Karma-yoga — Action in Kṛṣṇa Consciousness', 29),
  ('Dhyāna-yoga', 47),
  ('Knowledge of the Absolute', 30),
  ('Attaining the Supreme', 28),
  ('The Most Confidential Knowledge', 34),
  ('The Opulence of the Absolute', 42),
  ('The Universal Form', 55),
  ('Devotional Service', 20),
  ('Nature, the Enjoyer and Consciousness', 35),
  ('The Three Modes of Material Nature', 27),
  ('The Yoga of the Supreme Person', 20),
  ('The Divine and Demoniac Natures', 24),
  ('The Divisions of Faith', 28),
  ('Conclusion — The Perfection of Renunciation', 78),
];

// Placeholder range so the app exercises range entries. The real ranges
// come from the source.
const _ranges = <int, List<(int, int)>>{
  1: [(16, 18)],
};

const _devDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
String _dev(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => _devDigits[int.parse(m[0]!)]);

const _longSentences = [
  'This paragraph is placeholder text used to test how a very long purport reads and scrolls.',
  'It is <i>not</i> scripture and must be replaced by the authorised text before release.',
  'The renderer supports paragraphs, indented quotations, Sanskrit lines and limited <b>bold</b> or <i>italic</i> markup.',
  'Line height, paragraph spacing and the measure of the text column are tuned for comfortable reading at every text size.',
  'Scrolling should stay smooth because each block is built lazily as it comes into view.',
  'Nothing in this paragraph comes from the source edition; it only fills space with ordinary English sentences.',
  'When the importer runs on the real files, this placeholder disappears along with the rest of the development data.',
  'Readers will see the real purport here, set as a quiet book page with no cards, boxes or decoration.',
];

void main() {
  final root = Directory.current.path;
  final outDir = Directory('$root/assets/scripture')..createSync(recursive: true);
  final checksums = <String, String>{};
  final chapterIndex = <Map<String, dynamic>>[];
  final perChapter = <Map<String, dynamic>>[];

  for (var c = 1; c <= _chapters.length; c++) {
    final (title, verseCount) = _chapters[c - 1];
    final entries = <Map<String, dynamic>>[];
    var v = 1;
    while (v <= verseCount) {
      var end = v;
      for (final (s, e) in _ranges[c] ?? const <(int, int)>[]) {
        if (s == v) end = e;
      }
      entries.add(_entry(c, v, end));
      v = end + 1;
    }
    final raw = '${const JsonEncoder.withIndent('  ').convert({
      'chapter': c,
      'entries': entries,
    })}\n';
    final file = chapterFileName(c);
    File('${outDir.path}/$file').writeAsStringSync(raw);
    checksums[file] = sha256Of(raw);
    chapterIndex.add({
      'number': c,
      'titleEn': title,
      'titleHi': null,
      'verseCount': verseCount,
      'entryCount': entries.length,
    });
    perChapter.add({
      'chapter': c,
      'verses': verseCount,
      'entries': entries.length,
    });
  }

  final index = {
    'isPlaceholder': true,
    'source': {
      'name': 'PLACEHOLDER — authorised source not yet imported',
      'edition': 'Bhagavad-gita As It Is (edition to be confirmed)',
      'rightsHolder': 'To be confirmed',
      'attribution':
          'NEEDS YOUR WORDING: the exact attribution and permission text '
          'from the rights holder goes here.',
      'datasetVersion': '0.0.0-placeholder',
      'checksums': checksums,
    },
    'chapters': chapterIndex,
  };
  File(
    '${outDir.path}/chapters.json',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(index)}\n');

  final expected = File('$root/tool/expected_counts.json');
  if (!expected.existsSync()) {
    expected.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        'approved': false,
        'note': 'Development counts. Confirm every number against the '
            'authorised source, then set approved to true.',
        'chapters': chapterCount,
        'totalVerses': perChapter.fold<int>(0, (s, c) => s + (c['verses'] as int)),
        'perChapter': perChapter,
      })}\n',
    );
  }
  stdout.writeln('Wrote placeholder dataset to ${outDir.path}');
}

Map<String, dynamic> _entry(int c, int start, int end) {
  final label = formatLabel(c, start, end);
  final devLabel = _dev(label);
  final noPurport = start % 9 == 0;
  final isLong = c == 1 && start == 1;

  List<Map<String, String>> purportEn() {
    if (isLong) {
      final blocks = <Map<String, String>>[];
      for (var p = 0; p < 40; p++) {
        final sentences = [
          for (var s = 0; s < 8; s++)
            _longSentences[(p + s) % _longSentences.length],
        ];
        blocks.add({'type': 'p', 'text': sentences.join(' ')});
        if (p % 10 == 4) {
          blocks.add({
            'type': 'quote',
            'text': 'Placeholder quotation, indented like a cited verse.',
          });
          blocks.add({
            'type': 'sanskrit',
            'text': 'प्रतिस्थापन उद्धरण पंक्ति ॥',
          });
        }
      }
      return blocks;
    }
    return [
      {
        'type': 'p',
        'text':
            'Placeholder purport for $label. Paragraphs, <i>italic</i> and '
            '<b>bold</b> markup, quotations and Sanskrit lines will appear '
            'here once the authorised source is imported.',
      },
      if (start % 4 == 0) ...[
        {'type': 'quote', 'text': 'Placeholder quotation for $label.'},
        {'type': 'sanskrit', 'text': 'प्रतिस्थापन श्लोक $devLabel ॥'},
      ],
      {
        'type': 'p',
        'text':
            'This second paragraph is also placeholder text. It is not '
            'scripture.',
      },
    ];
  }

  return {
    'id': formatVerseId(c, start, end),
    'chapter': c,
    'verseStart': start,
    'verseEnd': end,
    'label': label,
    'sanskrit': [
      'प्रतिस्थापन पाठ — श्लोक $devLabel पंक्ति १ ।',
      'अधिकृत स्रोत से बदलें ॥ $devLabel ॥',
    ],
    'transliteration': [
      'pratisthāpana pāṭha — śloka $label paṅkti 1',
      'adhikṛta srota se badaleṁ',
    ],
    'translation': {
      'en':
          'Placeholder translation for Bhagavad-gita $label. This is not '
          'scripture; it will be replaced by the authorised translation '
          'from the source files.',
      'hi':
          'भगवद्गीता $devLabel का प्लेसहोल्डर अनुवाद। यह शास्त्र का पाठ नहीं '
          'है; इसे स्रोत फ़ाइलों के अधिकृत अनुवाद से बदला जाएगा।',
    },
    'purport': noPurport
        ? null
        : {
            'en': purportEn(),
            'hi': c == 1
                ? [
                    {
                      'type': 'p',
                      'text':
                          'श्लोक $devLabel का प्लेसहोल्डर तात्पर्य। यह शास्त्र '
                          'का पाठ नहीं है।',
                    },
                  ]
                : null,
          },
    'synonyms': null,
  };
}
