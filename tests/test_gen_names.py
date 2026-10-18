#!/usr/bin/env python3
"""gen_names.py: filtering and casing of Wikidata name labels (offline)."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_names as gen


class BuildTest(unittest.TestCase):
    def test_filters_and_casing(self) -> None:
        labels = {
            "AdSense": 57, "Adsense": 57, "ADSENSE": 57,  # same code: most capitals wins
            "GoDaddy": 35,
            "Hello": 99,          # SCOWL lowercase word: skipped
            "GitLab": 80,         # already in the hand list: skipped
            "Xvideos": 56,        # blocklist
            "AOL": 50,            # 3 letters: too short
            "Win32": 40,          # digits: not a typing target here
            "Okta": 14, "OKTA": 14,  # mixed case beats ALL CAPS
        }
        rows = gen.build(labels, {"hello", "gitlab"})
        self.assertEqual([(t, c) for t, c, _ in rows],
                         [("AdSense", "adsense"), ("GoDaddy", "godaddy"), ("Okta", "okta")])

    def test_write_and_read_back(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "kinfx_names.dict.yaml"
            gen.write_dict([("AdSense", "adsense", 57)], out, 1, 12)
            text = out.read_text(encoding="utf-8")
            self.assertIn("name: kinfx_names\n", text)
            self.assertTrue(text.endswith("...\n\nAdSense\tadsense\t57\n"))

    def test_hand_codes_reads_both_forms(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "names.txt"
            p.write_text("# comment\nGitLab\tgitlab\nnpm\n", encoding="utf-8")
            self.assertEqual(gen.hand_codes(p), {"gitlab", "npm"})


if __name__ == "__main__":
    unittest.main()
