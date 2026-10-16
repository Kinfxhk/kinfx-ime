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


def _weight(rows: list[tuple[str, str, int]], ch: str, code: str) -> int:
    found = [w for c, q, w in rows if c == ch and q == code]
    if not found:
        raise AssertionError(f"missing {ch}@{code}")
    return max(found)


def _completion_menu(
    rows: list[tuple[str, str, int]], prefix: str, limit: int = 9
) -> str:
    """librime 1.10 predictive order: shorter remaining code, then weight."""
    groups: dict[str, list[tuple[str, int]]] = {}
    for ch, code, weight in rows:
        if code.startswith(prefix):
            groups.setdefault(code, []).append((ch, weight))
    chunks = [
        {"rem": len(code) - len(prefix), "items": items, "i": 0}
        for code, items in groups.items()
    ]
    menu: list[str] = []
    while len(menu) < limit:
        live = [c for c in chunks if c["i"] < len(c["items"])]
        if not live:
            break
        live.sort(key=lambda c: (c["rem"], -c["items"][c["i"]][1]))
        best = live[0]
        menu.append(best["items"][best["i"]][0])
        best["i"] += 1
    return "".join(menu)


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
        self.assertEqual(best["綜"], "vf")
        self.assertLess(_weight(out, "網", "vd"), _weight(out, "網", "vv"))
        self.assertLess(_weight(out, "綜", "vd"), _weight(out, "綜", "vf"))
        # Rare pin keeps its essay weight; it does not climb to 我.
        self.assertEqual(_weight(out, "凡", "hi"), 10)
        self.assertEqual(_weight(out, "我", "hi"), 500)
        gen.assert_win_top9(out, win)

    def test_rare_pin_does_not_bury_short_code(self) -> None:
        rows = [
            ("竹", "h", 15527),
            ("身", "hh", 5000),
            ("凡", "hi", 10),
            ("我", "hi", 65_000_000),
            ("的", "hi", 10_000_000),
        ]
        win = {"h": list("竹"), "hi": list("凡我的")}
        out = gen.apply_win_top9_pin(rows, win)
        self.assertEqual(_page(out, "hi"), "凡我的")
        self.assertEqual(_page(out, "h")[:1], "竹")
        # Page order is not a weight chain: 凡 stays at its essay weight.
        self.assertEqual(_weight(out, "凡", "hi"), 10)
        self.assertEqual(_weight(out, "我", "hi"), 65_000_000)
        menu = _completion_menu(out, "h")
        self.assertEqual(menu[0], "竹")
        self.assertLess(menu.index("竹"), menu.index("凡"))
        # 我 sits behind the rare pin, so its champion weight must not jump
        # ahead of a heavier same-length code such as 身.
        self.assertLess(menu.index("身"), menu.index("凡"))
        self.assertLess(menu.index("身"), menu.index("我"))
        gen.assert_win_top9(out, win)

    def test_generated_dict_keeps_short_codes_and_primaries(self) -> None:
        path = ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml"
        text = path.read_text(encoding="utf-8")
        header, body = text.split("...", 1)
        self.assertIn("sort: original", header)
        rows: list[tuple[str, str, int]] = []
        for line in body.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            ch, code, weight = line.split("\t")
            rows.append((ch, code, int(weight)))
        self.assertEqual(_page(rows, "hi")[:9], "凡么丟夙舟卵我私的")
        self.assertEqual(_page(rows, "vd")[:9], "好她妹紆巢媒彙網綜")
        self.assertEqual(_page(rows, "h")[:1], "竹")
        self.assertLess(_weight(rows, "凡", "hi"), 1_000_000)
        self.assertGreater(_weight(rows, "我", "hi"), 1_000_000)
        best = _best(rows)
        self.assertEqual(best["網"], "vv")
        self.assertEqual(best["綜"], "vf")
        self.assertNotEqual(best["丟"], "hi")
        self.assertLess(_weight(rows, "網", "vd"), _weight(rows, "網", "vv"))
        self.assertLess(_weight(rows, "綜", "vd"), _weight(rows, "綜", "vf"))
        self.assertLess(_weight(rows, "丟", "hi"), _weight(rows, "丟", "mi"))
        menu = _completion_menu(rows, "h")
        self.assertEqual(menu[0], "竹")
        self.assertLess(menu.index("竹"), menu.index("凡"))
        # These were chained up to 我's weight and filled the h menu.
        self.assertNotIn("么", menu)
        self.assertNotIn("我", menu)
        self.assertNotIn("丟", menu)

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
