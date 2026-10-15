#!/usr/bin/env python3
"""Lexicon-driven phrase codes: one code per word, no of×c* product."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_quick_phrases as gen


QUICK = """# test
---
name: kinfx_quick
version: "0"
sort: by_weight
columns:
  - text
  - code
  - weight
...
無	xx	1
無	of	50
錯	zz	3
錯	ca	9
好	vd	10
你	nf	8
你	ab	1
日	a	5
月	b	5
"""

ESSAY = """無錯	19399
你好	5000
無好	500
日月	8000
不在表	99999
一心一意	200
"""


class PhraseEncodeTest(unittest.TestCase):
    def test_best_code_only_no_cartesian(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            quick = root / "quick.dict.yaml"
            essay = root / "essay.txt"
            quick.write_text(QUICK, encoding="utf-8")
            essay.write_text(ESSAY, encoding="utf-8")
            codes = gen.load_best_codes(quick)
            self.assertEqual(codes["無"], "of")
            self.assertEqual(codes["錯"], "ca")
            self.assertEqual(codes["你"], "nf")
            words = gen.load_essay_words(essay)
            hk_words, hk_idioms = gen.build_phrase_rows(words, codes)
            got = {(text, code) for text, code, _w in hk_words}
            self.assertIn(("無錯", "ofca"), got)
            self.assertIn(("你好", "nfvd"), got)
            self.assertIn(("無好", "ofvd"), got)
            # Two codes on 無 and two on 錯 must not become four phrases.
            self.assertNotIn(("無錯", "xxca"), got)
            self.assertNotIn(("無錯", "ofzz"), got)
            self.assertNotIn(("無錯", "xxzz"), got)
            self.assertNotIn(("你好", "abvd"), got)
            # Not in the single-char table, even at a huge weight.
            self.assertFalse(any(text == "不在表" for text, _c, _w in hk_words))
            # Two 1-letter codes concatenate to length 2 — dropped so 短碼 stays clean.
            self.assertFalse(any(text == "日月" for text, _c, _w in hk_words + hk_idioms))
            idioms = {text for text, _code, _w in hk_idioms}
            # 一／心／意 are not in the fixture table, so the idiom is not invented.
            self.assertNotIn("一心一意", idioms)

    def test_english_extras_and_case_fold(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            words = Path(tmp) / "words"
            extras = Path(tmp) / "extras.tsv"
            words.write_text("me\nME\ngood\nGood\n", encoding="utf-8")
            extras.write_text("Gmail\tgmail\t100000\nGMAIL\tgmail\t90000\n", encoding="utf-8")
            rows = gen.build_english_rows(gen.load_scowl(words), gen.load_extras(extras))
            by_code: dict[str, list[tuple[str, int]]] = {}
            for text, code, weight in rows:
                by_code.setdefault(code, []).append((text, weight))
            self.assertEqual(by_code["me"], [("me", gen.EN_BASE_WEIGHT)])
            self.assertEqual(by_code["good"], [("good", gen.EN_BASE_WEIGHT)])
            gmail = sorted(by_code["gmail"], key=lambda item: -item[1])
            self.assertEqual(gmail[0][0], "Gmail")
            self.assertEqual(gmail[1][0], "GMAIL")

    def test_prefix_order_exact_before_tail(self) -> None:
        rows = [
            ("無法", "ofxx", 99999),
            ("無錯", "ofca", 100),
            ("無錯啦", "ofcaxx", 50000),
        ]
        ofc = [text for text, _c, _w in gen.prefix_hits(rows, "ofc")]
        self.assertEqual(ofc[0], "無錯")
        ofca = [text for text, _c, _w in gen.prefix_hits(rows, "ofca")]
        self.assertEqual(ofca[0], "無錯")
        self.assertLess(
            gen.prefix_hits(rows, "ofca").index(("無錯", "ofca", 100)),
            len(gen.prefix_hits(rows, "ofca")),
        )


if __name__ == "__main__":
    unittest.main()
