#!/usr/bin/env python3
"""Windows top-9 pin: page order follows the table, not hot-character lifts."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_quick_dict as gen


def _page(rows: list[tuple[str, str, int]], code: str) -> str:
    return "".join(ch for ch, c, _w in rows if c == code)


def _best(rows: list[tuple[str, str, int]]) -> dict[str, str]:
    best: dict[str, tuple[int, int, str]] = {}
    for ch, code, weight in rows:
        cand = (weight, len(code), code)
        prev = best.get(ch)
        if prev is None or cand > prev:
            best[ch] = cand
    return {ch: code for ch, (_w, _n, code) in best.items()}


class WinTop9PinTest(unittest.TestCase):
    def test_windows_order_beats_frequency(self) -> None:
        rows = [
            ("我", "hi", 500),
            ("凡", "hi", 10),
            ("的", "hi", 400),
            ("個", "or", 900),
            ("倉", "or", 80),
            ("合", "or", 20),
            ("何", "or", 15),
            ("好", "vd", 100),
            ("樂", "vd", 90),
            ("她", "vd", 50),
            ("網", "vv", 40),
            ("綜", "vf", 5),
        ]
        win = {
            "hi": list("凡我的"),
            "or": list("合何"),
            "vd": list("好她網綜"),
        }
        out = gen.apply_win_top9_pin(rows, win)
        self.assertEqual(_page(out, "hi"), "凡我的")
        self.assertEqual(_page(out, "or")[:2], "合何")
        self.assertNotEqual(_page(out, "or")[:2], "個倉")
        self.assertNotIn("倉", _page(out, "or")[:2])
        self.assertEqual(_page(out, "vd")[:4], "好她網綜")
        # 樂 stays on vd, after the Windows page.
        self.assertGreater(_page(out, "vd").index("樂"), 3)
        best = _best(out)
        self.assertEqual(best["我"], "hi")
        self.assertEqual(best["倉"], "or")
        # 網 keeps the heavier vv reading; vd is only the Windows page slot.
        self.assertEqual(best["網"], "vv")
        gen.assert_win_top9(out, win)

    def test_documented_vd_ends_with_measured_glyphs(self) -> None:
        table = gen.load_win_top9(ROOT / "schemas/kinfx-quick/win_quick_top9.tsv")
        self.assertEqual("".join(table["vd"]), "好她妹紆巢媒彙網綜")
        self.assertEqual("".join(table["hi"]), "凡么丟夙舟卵我私的")
        self.assertEqual("".join(table["of"]), "伙你係偽氮焦無絛僚")
        self.assertEqual("".join(table["rr"]), "呂呵咖咕品哈咯唁唔")
        self.assertNotIn("倉", table["or"])
        self.assertEqual(table["me"][4], "夏")


if __name__ == "__main__":
    unittest.main()
