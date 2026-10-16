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

    def test_long_prefix_prefers_shorter_remainder(self) -> None:
        """Weight does not beat a shorter tail: scri→script, voic→voice."""
        rows = [
            ("script", "script", gen.EN_BASE_WEIGHT),
            ("scriptwriter", "scriptwriter", gen.EN_BASE_WEIGHT),
            ("scriptwriting", "scriptwriting", 100000),
            ("voice", "voice", gen.EN_BASE_WEIGHT),
            ("voicemail", "voicemail", gen.EN_BASE_WEIGHT),
            ("voiceover", "voiceover", 100000),
            ("Gmail", "gmail", 100000),
            ("GMAIL", "gmail", 90000),
        ]
        self.assertEqual(gen.prefix_hits(rows, "scri")[0][0], "script")
        self.assertEqual(gen.prefix_hits(rows, "voic")[0][0], "voice")
        self.assertEqual(gen.prefix_hits(rows, "scriptwriti")[0][0], "scriptwriting")
        self.assertEqual(gen.prefix_hits(rows, "voiceove")[0][0], "voiceover")
        self.assertEqual(gen.prefix_hits(rows, "gmai")[0][0], "Gmail")

    def test_capture_keeps_hot_prefixes_only(self) -> None:
        rows = [("無錯", "ofca", 19399), ("無錫", "ofch", 3260), ("你鐘", "ofcg", 1067), ("好嘢", "vdmh", 50000)]
        caps = gen.capture_prefixes(rows, 19000, 3000)
        self.assertIn("ofc", caps)
        self.assertIn("ofca", caps)
        self.assertIn("ofch", caps)  # full 4-letter phrase above the exact floor
        self.assertNotIn("ofcg", caps)  # below it: key 4 tops out like Windows
        self.assertIn("vdm", caps)
        self.assertNotIn("vdo", caps)

    def test_windows_consistent_phrase_first(self) -> None:
        tops = {"vd": "好", "of": "伙"}
        rows = [("妹妹", "vdvd", 85071), ("好好", "vdvd", 19833), ("樂樂", "vdvd", 900)]
        out, lifted = gen.lift_windows_consistent(rows, tops)
        self.assertEqual(out[0][0], "好好")
        self.assertEqual(lifted, 1)
        self.assertEqual(gen.windows_text("vdof", tops), "好伙")
        self.assertIsNone(gen.windows_text("ofc", tops))

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
