#!/usr/bin/env python3
"""v0.4 Sucheng dict: Windows 11 微軟速成 order on every page, HK glyphs appended."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_quick_dict as gen

DICT = ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml"
ORDER = ROOT / "schemas/kinfx-quick/ms_quick_order.tsv"


def _dict_rows() -> list[tuple[str, str, int]]:
    text = DICT.read_text(encoding="utf-8")
    header, body = text.split("\n...\n", 1)
    assert "sort: original" in header
    rows = []
    for line in body.splitlines():
        line = line.rstrip("\r\n")
        if not line or line.startswith("#"):
            continue
        ch, code, weight = line.split("\t")
        rows.append((ch, code, int(weight)))
    return rows


def _page(rows, code):
    return [ch for ch, c, _w in rows if c == code]


class BuildRowsTest(unittest.TestCase):
    def test_windows_order_then_frequency_tail(self) -> None:
        ms = {"vd": list("好她妹"), "hi": list("凡么我")}
        cangjie = [("好", "vd"), ("樂", "vd"), ("妹", "vd"), ("㗎", "vd"), ("我", "hi")]
        essay = {"樂": 50, "㗎": 5, "好": 900}
        rows, stats = gen.build_rows(ms, cangjie, essay, {})
        self.assertEqual(_page(rows, "vd"), list("好她妹樂㗎"))
        self.assertEqual(_page(rows, "hi"), list("凡么我"))
        self.assertEqual(stats["extra"], 2)
        gen.assert_ms_order(rows, ms)

    def test_unused_extension_noise_is_dropped(self) -> None:
        rows, _ = gen.build_rows({}, [("𠀀", "aa")], {}, {})
        self.assertEqual(rows, [])

    def test_rare_windows_glyphs_are_kept(self) -> None:
        # Windows lists 丂 on mp; KINFX keeps every Windows slot.
        rows, _ = gen.build_rows({"mp": ["亐", "丂"]}, [("丂", "mp")], {}, {})
        self.assertEqual(_page(rows, "mp"), ["亐", "丂"])

    def test_assert_catches_lost_order(self) -> None:
        with self.assertRaises(SystemExit):
            gen.assert_ms_order([("她", "vd", 1), ("好", "vd", 1)], {"vd": ["好", "她"]})


class GeneratedDictTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.rows = _dict_rows()
        cls.ms = gen.load_ms_order(ORDER)

    def test_every_measured_code_matches_windows(self) -> None:
        bad = [c for c, want in self.ms.items() if _page(self.rows, c)[: len(want)] != want]
        self.assertEqual(bad, [])
        self.assertGreater(len(self.ms), 600)

    def test_known_pages(self) -> None:
        self.assertEqual("".join(_page(self.rows, "vd")[:18]), "好她妹紆巢媒彙綑綵嫻槳樂繅孿姀孥姝婐")
        self.assertEqual("".join(_page(self.rows, "hi")[:9]), "凡么丟夙舟卵我私的")
        self.assertEqual("".join(_page(self.rows, "of")[:9]), "伙你係偽氮焦無絛僚")
        self.assertEqual("".join(_page(self.rows, "h")), "竹丿")

    def test_hk_glyphs_present(self) -> None:
        have = {(ch, c) for ch, c, _w in self.rows}
        for ch, code in [("㗎", "rd"), ("嘅", "ru"), ("𠻹", "rp"), ("𨋢", "jt"), ("嘢", "rn"), ("咗", "rm")]:
            self.assertIn((ch, code), have)


if __name__ == "__main__":
    unittest.main()
