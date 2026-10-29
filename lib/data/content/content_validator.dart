/// Validators for written content (PRD_v2 sections 6, 9, 11). Pure: they
/// read JSON strings and report; they never modify data.
library;

import 'dart:convert';

class ContentReport {
  final errors = <String>[];
  final warnings = <String>[];

  bool get ok => errors.isEmpty;

  @override
  String toString() => [
    for (final e in errors) 'ERROR: $e',
    for (final w in warnings) 'WARNING: $w',
    ok ? 'OK' : '${errors.length} error(s)',
  ].join('\n');
}

const messageMinimums = {
  'invite': 150,
  'streak_risk': 100,
  'comeback': 80,
  'milestone': 30,
  'reflection': 120,
  'popup_good_work': 60,
  'verse_lead_in': 20,
};

const requiredMilestones = [1, 3, 7, 21, 40, 108, 365];

const bannedPhrases = [
  'watching you',
  'failed',
  'lazy',
  'shame',
  'guilt',
  'lost your streak',
  'you must',
];

const allowedPlaceholders = {'{streak}', '{days}'};
const maxTitle = 40;
const maxBody = 140;

/// Allowed emoji (at most one per message).
final _emoji = RegExp('[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
const _allowedEmoji = {'🪷', '🙏'};

ContentReport validateMessages(String raw) {
  final r = ContentReport();
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    return r..errors.add('Not valid JSON: $e');
  }
  final list = json['messages'];
  if (list is! List) return r..errors.add('Missing "messages" list');

  final ids = <String>{};
  final seenText = <String>{};
  final counts = <String, int>{};
  final milestones = <int>{};
  var missingHi = 0;

  for (final m in list) {
    if (m is! Map) {
      r.errors.add('A message is not an object');
      continue;
    }
    final id = m['id'];
    final cat = m['category'];
    if (id is! String || id.isEmpty) {
      r.errors.add('Message without id');
      continue;
    }
    if (!ids.add(id)) r.errors.add('$id: duplicate id');
    if (!messageMinimums.containsKey(cat)) {
      r.errors.add('$id: unknown category "$cat"');
      continue;
    }
    counts[cat as String] = (counts[cat] ?? 0) + 1;
    if (cat == 'milestone') {
      final day = m['day'];
      if (day is! int || day < 1) {
        r.errors.add('$id: milestone needs a positive "day"');
      } else {
        milestones.add(day);
      }
    }
    if (m['reviewed'] is! bool) r.errors.add('$id: "reviewed" must be a bool');

    for (final field in const ['title', 'body']) {
      final t = m[field];
      if (t is! Map || t['en'] is! String) {
        r.errors.add('$id: $field.en missing');
        continue;
      }
      final hi = t['hi'];
      if (hi is! String || hi.trim().isEmpty) missingHi++;
      for (final lang in const ['en', 'hi']) {
        final text = t[lang];
        if (text is! String) continue;
        final limit = field == 'title' ? maxTitle : maxBody;
        if (text.trim().isEmpty) r.errors.add('$id: empty $field.$lang');
        if (text.runes.length > limit) {
          r.errors.add(
            '$id: $field.$lang is ${text.runes.length} chars (max $limit)',
          );
        }
        for (final p in RegExp(r'\{[^}]*\}').allMatches(text)) {
          if (!allowedPlaceholders.contains(p[0])) {
            r.errors.add('$id: unknown placeholder ${p[0]} in $field.$lang');
          }
        }
        if (lang == 'en') {
          final lower = text.toLowerCase();
          for (final b in bannedPhrases) {
            if (lower.contains(b)) {
              r.errors.add('$id: banned phrase "$b" in $field.en');
            }
          }
        }
      }
    }
    final title = m['title'], body = m['body'];
    if (title is Map && body is Map) {
      final emoji = [
        ..._emoji.allMatches('${title['en']} ${body['en']}').map((e) => e[0]),
      ];
      if (emoji.length > 1) r.errors.add('$id: more than one emoji');
      for (final e in emoji) {
        if (!_allowedEmoji.contains(e)) r.errors.add('$id: emoji $e not allowed');
      }
      final key = '$cat|${title['en']}|${body['en']}'.toLowerCase();
      if (!seenText.add(key)) r.errors.add('$id: exact duplicate text');
    }
  }

  for (final e in messageMinimums.entries) {
    final n = counts[e.key] ?? 0;
    if (n < e.value) {
      r.errors.add('${e.key}: $n messages, need at least ${e.value}');
    }
  }
  for (final d in requiredMilestones) {
    if (!milestones.contains(d)) r.errors.add('No milestone message for day $d');
  }
  if (missingHi > 0) {
    r.warnings.add('$missingHi title/body fields have no Hindi (English is used)');
  }
  final total = counts.values.fold(0, (a, b) => a + b);
  r.warnings.add('$total messages; Hindi present for every field: ${missingHi == 0}');
  return r;
}

const summaryMinWords = 150;
const summaryMaxWords = 250;

ContentReport validateSummaries(String raw) {
  final r = ContentReport();
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    return r..errors.add('Not valid JSON: $e');
  }
  final list = json['summaries'];
  if (list is! List) return r..errors.add('Missing "summaries" list');
  final chapters = <int>{};
  for (final raw in list) {
    final s = raw is Map ? raw : const <String, Object?>{};
    final c = s['chapter'];
    if (c is! int || c < 1 || c > 18) {
      r.errors.add('Summary with bad chapter: $c');
      continue;
    }
    if (!chapters.add(c)) r.errors.add('Chapter $c: duplicate summary');
    final en = s['en'];
    if (en is! String || en.trim().isEmpty) {
      r.errors.add('Chapter $c: empty English summary');
    } else {
      final words = en.trim().split(RegExp(r'\s+')).length;
      if (words < summaryMinWords || words > summaryMaxWords) {
        r.errors.add(
          'Chapter $c: $words words (want $summaryMinWords-$summaryMaxWords)',
        );
      }
      if (en.toLowerCase().contains('prabhupada says') ||
          en.toLowerCase().contains('prabhupāda says')) {
        r.errors.add('Chapter $c: do not write "Prabhupada says"');
      }
    }
    final hi = s['hi'];
    if (hi is! String || hi.trim().isEmpty) {
      r.warnings.add('Chapter $c: no Hindi summary (English is used)');
    }
    if (s['reviewed'] is! bool) {
      r.errors.add('Chapter $c: "reviewed" must be a bool');
    }
  }
  if (chapters.length != 18) {
    r.errors.add('Need exactly 18 summaries, found ${chapters.length}');
  }
  return r;
}

/// [entryIds] are every entry id in the dataset.
ContentReport validateThemes(String raw, Set<String> entryIds) {
  final r = ContentReport();
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    return r..errors.add('Not valid JSON: $e');
  }
  final list = json['themes'];
  if (list is! List) return r..errors.add('Missing "themes" list');
  final ids = <String>{};
  for (final raw in list) {
    final t = raw is Map ? raw : const <String, Object?>{};
    final id = t['id'];
    if (id is! String || id.isEmpty) {
      r.errors.add('Theme without id');
      continue;
    }
    if (!ids.add(id)) r.errors.add('$id: duplicate theme id');
    final title = t['title'];
    if (title is! Map || title['en'] is! String) {
      r.errors.add('$id: title.en missing');
    }
    final syn = t['synonyms'];
    if (syn is! List || syn.isEmpty) r.errors.add('$id: no synonyms');
    final verses = t['verseIds'];
    if (verses is! List || verses.length < 3 || verses.length > 8) {
      r.errors.add('$id: needs 3-8 verseIds, has ${verses is List ? verses.length : 0}');
    }
    if (verses is List) {
      final seen = <String>{};
      for (final v in verses) {
        if (v is! String || !entryIds.contains(v)) {
          r.errors.add('$id: verse id $v does not exist in the dataset');
        }
        if (!seen.add('$v')) r.errors.add('$id: verse $v listed twice');
      }
    }
    if (t['reviewed'] is! bool) r.errors.add('$id: "reviewed" must be a bool');
  }
  if (ids.length < 100 || ids.length > 150) {
    r.warnings.add('${ids.length} themes (spec asks for about 100-150)');
  }
  return r;
}
