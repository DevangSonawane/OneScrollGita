#!/usr/bin/env python3
"""Tests for convert_vedabase_io.py. Run: python3 tool/test_convert_vedabase_io.py"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import convert_vedabase_io as c  # noqa: E402

PAGE = '''<main>
<div class="av-devanagari"><h2>Devanagari</h2><div id="bb1"><div class="text-center">
अ ब ।<br/>क ख ॥ १ ॥</div></div></div>
<div class="av-verse_text"><h2>Verse text</h2><div id="bb2"><div class="text-center italic">
<em>line one<br />line ’two</em></div></div></div>
<div class="av-synonyms"><h2>Synonyms</h2><div id="bb3"><div>
<span class="inline"><a href="#"><em>karma</em></a>-<a href="#"><em>phala</em></a> — <span class="inline">result</span>; </span>
<span class="inline"><a href="#"><em>te</em></a> — <span class="inline">of you</span>.</span></div></div></div>
<div class="av-translation"><h2>Translation</h2><div id="bb4"><div><strong>Do your duty.</strong></div></div></div>
<div class="av-purport"><h2>Purport</h2>
<div id="bb5"><div class="s-justify">First   para with <em>kūṭa-stha.</em> word.</div></div>
<div id="bb6"><div class="text-center italic"><em>quoted a<br />quoted b</em></div></div>
<div id="bb7"><div class="s-justify">Last.</div></div></div>
</main>'''


class ConvertTest(unittest.TestCase):
    def setUp(self):
        self.root = c.parse(PAGE)

    def test_devanagari_lines(self):
        self.assertEqual(c.verse_lines(c.section(self.root, 'devanagari')),
                         '> अ ब ।\n> क ख ॥ १ ॥')

    def test_transliteration_drops_wrapper_em_only(self):
        self.assertEqual(c.verse_lines(c.section(self.root, 'verse_text')),
                         '> line one\n> line ’two')

    def test_grouped_verse_blocks_each_lose_wrapper(self):
        root = c.parse('<div class="av-verse_text"><div id="bb1"><div '
                       'class="text-center"><em>a<br />b</em></div></div>'
                       '<div id="bb2"><div class="text-center"><em>c<br />d'
                       '</em></div></div></div>')
        self.assertEqual(c.verse_lines(c.section(root, 'verse_text')),
                         '> a\n> b\n> c\n> d')

    def test_synonyms_keep_text(self):
        self.assertEqual(c.plain_block(c.section(self.root, 'synonyms')),
                         '*karma*-*phala* — result; *te* — of you.')

    def test_translation_bold(self):
        self.assertEqual(c.plain_block(c.section(self.root, 'translation')),
                         '**Do your duty.**')

    def test_purport_paragraphs_and_quotes(self):
        self.assertEqual(c.purport(c.section(self.root, 'purport')),
                         'First para with *kūṭa-stha.* word.\n\n'
                         '> quoted a\n> quoted b\n\nLast.')

    def test_missing_section(self):
        self.assertIsNone(c.section(c.parse('<main></main>'), 'purport'))


if __name__ == '__main__':
    unittest.main()
