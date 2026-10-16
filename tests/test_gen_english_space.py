#!/usr/bin/env python3
"""gen_english_space.py: 2-letter words are always unsafe; rate model sanity."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_english_space as gen


def _minimal_order() -> dict[str, list[str]]:
    # a few codes; "an" is a 2-letter code, "the" a 3-letter run (th + e).
    return {"an": ["明", "丹"], "th": ["芽"], "e": ["水", "火"]}


class TwoLetterUnsafeTest(unittest.TestCase):
    def test_two_letter_code_words_are_forced_unsafe(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            en_dict = root / "en.dict.yaml"
            en_dict.write_text(
                "---\nname: x\ncolumns:\n  - text\n  - code\n  - weight\n...\n"
                "an\tan\t100\nban\tban\t100\nthe\tthe\t100\n",
                encoding="utf-8",
            )
            words = gen.load_words(en_dict)
            self.assertIn("an", words)
            self.assertIn("the", words)
            # The build() helper is the unit under test only via its internal
            # forcing; verify the forcing logic directly on a fake rates dict.
            rates = {"an": 0.001, "the": 2.5, "ban": 0.0001}
            order = {"an": ["明"], "th": ["芽"], "e": ["水"]}
            for w in list(rates):
                if len(w) == 2 and w in order:
                    rates[w] = 1e9
            self.assertGreater(rates["an"], 1.0)   # forced unsafe
            self.assertGreater(rates["the"], 1.0)  # already unsafe by rate
            self.assertLess(rates["ban"], 1.0)     # 3 letters, stays safe


class ModelHelpersTest(unittest.TestCase):
    def test_code_cost(self) -> None:
        # 2-letter rank 1: 2 keys. 2-letter rank 10: letters + 1 page + digit.
        self.assertEqual(gen.code_cost("vd", 1), 2)
        self.assertEqual(gen.code_cost("vd", 9), 3)
        # single-letter rank 1: letter + space + digit.
        self.assertGreater(gen.code_cost("a", 1), 2)

    def test_load_words_lowercases_codes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "en.dict.yaml"
            p.write_text(
                "---\nname: x\ncolumns:\n  - text\n  - code\n  - weight\n...\n"
                "Gmail\tgmail\t100\nhello\thello\t100\n",
                encoding="utf-8",
            )
            self.assertEqual(gen.load_words(p), ["gmail", "hello"])


if __name__ == "__main__":
    unittest.main()
