#!/usr/bin/env python3
"""Turns the cached vedabase.io HTML into JSON shaped like the vedabase.cc API.

Reads tool/.cache/vedabase_io/html/ (written by fetch_vedabase_io.py) and
writes tool/.cache/vedabase_io/en/bg/<c>/<slug>.json and toc_en.json, so that
tool/import_vedabase.dart --english=io can import them with the same parser
it uses for vedabase.cc.

Text is copied verbatim. The only changes are markup: <em> -> *..*,
<strong> -> **..**, <br> -> newline, centred verse blocks -> "> " lines, and
HTML whitespace collapsed the way a browser renders it. No network access.

Run: python3 tool/convert_vedabase_io.py
"""
import html as htmllib
import json
import os
import re
import sys
from html.parser import HTMLParser

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, '.cache', 'vedabase_io')
HTML = os.path.join(CACHE, 'html', 'en', 'library', 'bg')
VOID = {'br', 'img', 'hr', 'meta', 'link', 'input', 'source', 'path', 'wbr'}


class Node:
    def __init__(self, tag, attrs, parent):
        self.tag, self.attrs, self.parent = tag, dict(attrs), parent
        self.children = []

    @property
    def cls(self):
        return (self.attrs.get('class') or '').split()


class Tree(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node('root', [], None)
        self.cur = self.root

    def handle_starttag(self, tag, attrs):
        n = Node(tag, attrs, self.cur)
        self.cur.children.append(n)
        if tag not in VOID:
            self.cur = n

    def handle_startendtag(self, tag, attrs):
        self.cur.children.append(Node(tag, attrs, self.cur))

    def handle_endtag(self, tag):
        n = self.cur
        while n is not self.root and n.tag != tag:
            n = n.parent
        if n is not self.root:
            self.cur = n.parent

    def handle_data(self, data):
        self.cur.children.append(data)


def parse(text):
    t = Tree()
    t.feed(text)
    return t.root


def find_all(node, pred):
    out = []
    for ch in node.children:
        if isinstance(ch, Node):
            if pred(ch):
                out.append(ch)
            out.extend(find_all(ch, pred))
    return out


def md(node):
    """Inline markdown of a node: em -> *, strong -> **, br -> newline."""
    parts = []
    for ch in node.children:
        if isinstance(ch, str):
            parts.append(re.sub(r'\s+', ' ', ch))
        elif ch.tag == 'br':
            parts.append('\n')
        elif ch.tag in ('h1', 'h2', 'h3', 'script', 'style', 'svg'):
            continue
        else:
            inner = md(ch)
            if ch.tag in ('em', 'i') and inner.strip():
                lead = inner[:len(inner) - len(inner.lstrip(' '))]
                trail = inner[len(inner.rstrip(' ')):]
                inner = f'{lead}*{inner.strip(" ")}*{trail}'
            elif ch.tag in ('strong', 'b') and inner.strip():
                inner = f'**{inner.strip()}**'
            parts.append(inner)
    s = re.sub(r' {2,}', ' ', ''.join(parts))  # as a browser renders it
    s = re.sub(r' *\n *', '\n', s)
    return s


def section(root, name):
    secs = find_all(root, lambda n: n.tag == 'div' and f'av-{name}' in n.cls)
    if not secs:
        return None
    blocks = find_all(secs[0], lambda n: n.tag == 'div' and
                      (n.attrs.get('id') or '').startswith('bb'))
    return blocks


def is_centred(block):
    return any('text-center' in n.cls for n in find_all(block, lambda n: True))


def verse_lines(blocks):
    if not blocks:
        return None
    lines = []
    for b in blocks:  # grouped verses have one block per verse
        t = md(b).strip()
        # Each transliteration block is wrapped in one <em>; drop that only.
        if t.startswith('*') and t.endswith('*') and t.count('*') == 2:
            t = t[1:-1]
        lines += [l.strip() for l in t.split('\n') if l.strip()]
    return '\n'.join('> ' + l for l in lines)


def purport(blocks):
    if not blocks:
        return None
    paras = []
    for b in blocks:
        t = md(b).strip()
        if not t:
            continue
        if is_centred(b):
            lines = [l.strip() for l in t.split('\n') if l.strip()]
            joined = '\n'.join(lines)
            if (joined.startswith('*') and joined.endswith('*')
                    and joined.count('*') == 2):
                lines = joined[1:-1].split('\n')
            paras.append('\n'.join('> ' + l.strip() for l in lines))
        else:
            paras.append(' '.join(l.strip() for l in t.split('\n')))
    return '\n\n'.join(paras) or None


def plain_block(blocks):
    if not blocks:
        return None
    return ' '.join(md(b).strip() for b in blocks).strip() or None


def chapter_title(c):
    with open(os.path.join(HTML, str(c) + '.html'), encoding='utf-8') as f:
        root = parse(f.read())
    h1 = find_all(root, lambda n: n.tag == 'h1')
    return md(h1[0]).replace('*', '').strip()


def main():
    if not os.path.isdir(HTML):
        sys.exit('No cache. Run python3 tool/fetch_vedabase_io.py first.')
    toc = {'book': 'bg', 'lang': 'en', 'title': 'Bhagavad-gītā As It Is',
           'source': 'vedabase.io', 'children': []}
    missing = []
    for c in range(1, 19):
        cdir = os.path.join(HTML, str(c))
        if not os.path.exists(os.path.join(HTML, f'{c}.html')):
            missing.append(f'chapter {c}')
            continue
        with open(os.path.join(HTML, f'{c}.html'), encoding='utf-8') as f:
            chtml = f.read()
        slugs = sorted(set(re.findall(
            rf'href="/en/library/bg/{c}/([0-9]+(?:-[0-9]+)?)/"', chtml)),
            key=lambda s: int(s.split('-')[0]))
        kids = []
        for s in slugs:
            page = os.path.join(cdir, s + '.html')
            if not os.path.exists(page):
                missing.append(f'bg/{c}/{s}')
                continue
            with open(page, encoding='utf-8') as f:
                root = parse(f.read())
            ref = f'bg/{c}/{s}'
            out = {
                'ref': ref,
                'lang': 'en',
                'book': 'bg',
                'url': f'https://vedabase.io/en/library/bg/{c}/{s}/',
                'devanagari': verse_lines(section(root, 'devanagari')),
                'verse_text': verse_lines(section(root, 'verse_text')),
                'synonyms': plain_block(section(root, 'synonyms')),
                'translation': plain_block(section(root, 'translation')),
                'purport': purport(section(root, 'purport')),
                'format': 'markdown',
            }
            if not out['translation'] or not out['verse_text']:
                missing.append(f'{ref} (no translation/verse text parsed)')
            dest = os.path.join(CACHE, 'en', 'bg', str(c), s + '.json')
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, 'w', encoding='utf-8') as f:
                json.dump(out, f, ensure_ascii=False)
            kids.append({'ref': ref, 'label': f'{c}.{s}'})
        toc['children'].append({'ref': f'bg/{c}',
                                'title': f'Chapter {c}: {chapter_title(c)}',
                                'label': str(c), 'children': kids})
    if missing:
        for m in missing:
            print('missing:', m, file=sys.stderr)
        sys.exit(1)
    with open(os.path.join(CACHE, 'toc_en.json'), 'w', encoding='utf-8') as f:
        json.dump(toc, f, ensure_ascii=False)
    n = sum(len(ch['children']) for ch in toc['children'])
    print(f'Converted {n} entries in {len(toc["children"])} chapters.')


if __name__ == '__main__':
    main()
