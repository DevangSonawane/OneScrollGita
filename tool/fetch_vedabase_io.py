#!/usr/bin/env python3
"""Fetches Bhagavad-gita As It Is (English) from vedabase.io into a local cache.

Build-time only; the app never calls the network for scripture. Raw HTML is
cached in tool/.cache/vedabase_io/html/ so a re-run only fetches what is
missing. vedabase.io's robots.txt asks for a 10 second crawl delay, which this
script honours.

Run:  python3 tool/fetch_vedabase_io.py
Then: python3 tool/convert_vedabase_io.py
"""
import os
import re
import sys
import time
import urllib.error
import urllib.request

BASE = 'https://vedabase.io'
DELAY = 10.0  # seconds, from vedabase.io/robots.txt
UA = 'GitaOfflineApp-importer/1.0'
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.cache',
                    'vedabase_io', 'html')

_last = 0.0


def fetch(path):
    """GET BASE+path, cached under ROOT. Returns the HTML text."""
    global _last
    cache = os.path.join(ROOT, path.strip('/').replace('/', os.sep) + '.html')
    if os.path.exists(cache):
        with open(cache, encoding='utf-8') as f:
            return f.read()
    for attempt in range(1, 6):
        wait = DELAY - (time.monotonic() - _last)
        if wait > 0:
            time.sleep(wait)
        _last = time.monotonic()
        try:
            req = urllib.request.Request(BASE + path, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=60) as res:
                html = res.read().decode('utf-8')
            os.makedirs(os.path.dirname(cache), exist_ok=True)
            with open(cache, 'w', encoding='utf-8') as f:
                f.write(html)
            return html
        except urllib.error.HTTPError as e:
            if e.code == 429:
                retry = int(e.headers.get('Retry-After') or 60)
                print(f'rate limited, waiting {retry}s', file=sys.stderr)
                time.sleep(retry)
                continue
            if e.code == 404 or attempt == 5:
                raise
        except Exception as e:  # network hiccup
            if attempt == 5:
                raise
            print(f'retry {path} ({e})', file=sys.stderr)
            time.sleep(10 * attempt)
    raise RuntimeError(path)


def verse_refs(chapter_html, c):
    """Verse page slugs of chapter c (e.g. '16-18'), in reading order."""
    slugs = set(re.findall(rf'href="/en/library/bg/{c}/([0-9]+(?:-[0-9]+)?)/"',
                           chapter_html))
    return sorted(slugs, key=lambda s: int(s.split('-')[0]))


def main():
    chapters = {}
    for c in range(1, 19):
        chapters[c] = verse_refs(fetch(f'/en/library/bg/{c}/'), c)
        print(f'chapter {c}: {len(chapters[c])} entries', flush=True)
    total = sum(len(v) for v in chapters.values())
    done = 0
    for c, slugs in chapters.items():
        for s in slugs:
            fetch(f'/en/library/bg/{c}/{s}/')
            done += 1
            if done % 25 == 0 or done == total:
                print(f'{done}/{total} verse pages', flush=True)
    print('Done.')


if __name__ == '__main__':
    main()
