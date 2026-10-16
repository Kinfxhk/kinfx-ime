#!/usr/bin/env python3
"""gen_assoc.py: suffix grouping and the hex 0-f -> a-p char encoding."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_assoc as gen


class EncodeTest(unittest.TestCase):
    def test_encode_char(self) -> None:
        self.assertEqual(gen.encode_char("我"), "gcbb")  # U+6211
        self.assertEqual(gen.encode_char("好"), "fjhn")  # U+597D
        self.assertEqual(gen.encode_char("一"), "eoaa")  # U+4E00

    def test_roundtrip_suffix_lookup_code(self) -> None:
        # The code only depends on the FIRST character; the suffix is the rest.
        self.assertEqual(gen.encode_char("我"), gen.encode_char("我"))
        self.assertNotEqual(gen.encode_char("我"), gen.encode_char("你"))


class AssocWordsTest(unittest.TestCase):
    def test_groups_by_first_char_and_sorts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            essay = Path(tmp) / "essay.txt"
            essay.write_text(
                "我地\t50000\n我想\t40000\n我睇\t30000\n你好\t90000\n"
                "我們\t1000\n我行\t80000\n",
                encoding="utf-8",
            )
            groups = gen.load_assoc_words(essay)
            self.assertEqual(groups["我"], [("我行", 80000), ("我地", 50000), ("我想", 40000), ("我睇", 30000), ("我們", 1000)])
            self.assertEqual(groups["你"], [("你好", 90000)])

    def test_skips_single_char_and_long_words(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            essay = Path(tmp) / "essay.txt"
            essay.write_text("我\t99999\n一二三四五\t88888\n", encoding="utf-8")
            groups = gen.load_assoc_words(essay)
            self.assertEqual(groups, {})


class MsCharsTest(unittest.TestCase):
    def test_load_ms_chars(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            order = Path(tmp) / "ms.tsv"
            order.write_text("vd\t好 她 妹\nhi\t凡 么\n", encoding="utf-8")
            chars = gen.load_ms_chars(order)
            self.assertIn("好", chars)
            self.assertIn("凡", chars)
            # single-letter codes are skipped (capture is 2-letter only)
            self.assertNotIn("vd", chars)


if __name__ == "__main__":
    unittest.main()
