#!/usr/bin/env python3
"""Compares two copies of assets/scripture/ and writes a Markdown report.

Read-only on both inputs. Lists, per verse entry, which fields differ
(Sanskrit, transliteration, English translation, English purport, English
word meanings) and entries that exist in only one copy.

Run: python3 tool/diff_scripture.py OLD_DIR NEW_DIR REPORT.md
"""
import difflib
import json
import os
import re
import sys

FIELDS = [
    ('sanskrit', lambda e: '\n'.join(e.get('sanskrit') or [])),
    ('transliteration', lambda e: '\n'.join(e.get('transliteration') or [])),
    ('translation', lambda e: (e.get('translation') or {}).get('en') or ''),
    ('purport', lambda e: '\n\n'.join(
        b['text'] for b in ((e.get('purport') or {}).get('en') or []))),
    ('word meanings', lambda e: '; '.join(
        f"{m['word']}—{m['meaning']}"
        for m in ((e.get('synonyms') or {}).get('en') or []))),
]


def load(d):
    out = {}
    for f in sorted(os.listdir(d)):
        if re.match(r'chapter_\d\d\.json$', f):
            with open(os.path.join(d, f), encoding='utf-8') as fh:
                for e in json.load(fh)['entries']:
                    out[e['id']] = e
    return out


def strip(s):
    return re.sub(r'</?[ib]>', '', s)


def changed_words(a, b, limit=6):
    """A few word-level changes, for a quick read of the report."""
    aw, bw = strip(a).split(), strip(b).split()
    out = []
    for op, i1, i2, j1, j2 in difflib.SequenceMatcher(None, aw, bw,
                                                      autojunk=False).get_opcodes():
        if op == 'equal':
            continue
        out.append(f"“{' '.join(aw[i1:i2])[:60]}” → “{' '.join(bw[j1:j2])[:60]}”")
        if len(out) >= limit:
            out.append('…')
            break
    return '; '.join(out)


def main(old_dir, new_dir, report):
    old, new = load(old_dir), load(new_dir)
    only_old = [i for i in old if i not in new]
    only_new = [i for i in new if i not in old]
    counts = {f: 0 for f, _ in FIELDS}
    rows = []
    for vid in new:
        if vid not in old:
            continue
        diffs = []
        for name, get in FIELDS:
            a, b = get(old[vid]), get(new[vid])
            if a != b:
                counts[name] += 1
                diffs.append((name, a, b))
        if diffs:
            rows.append((vid, diffs))
    lines = [
        '# Scripture text: vedabase.cc → vedabase.io (English)',
        '',
        f'Compared {len(old)} old entries with {len(new)} new entries. '
        'Hindi text is unchanged (it still comes from vedabase.cc).',
        '',
        '| Field | Entries that changed |',
        '|---|---|',
        *[f'| {k} | {v} |' for k, v in counts.items()],
        f'| any field | {len(rows)} |',
        '',
    ]
    if only_old or only_new:
        lines += ['## Entries in only one copy', '',
                  f'- Only in old: {", ".join(only_old) or "none"}',
                  f'- Only in new: {", ".join(only_new) or "none"}', '']
    lines += ['## Changes by entry', '',
              'Each line shows a few of the word-level changes, not all of them.',
              '']
    for vid, diffs in rows:
        lines.append(f'### {vid}')
        for name, a, b in diffs:
            lines.append(f'- **{name}**: {changed_words(a, b)}')
        lines.append('')
    with open(report, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print('\n'.join(lines[4:12 + len(FIELDS)]))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
