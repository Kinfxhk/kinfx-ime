#!/usr/bin/env python3
"""Merge raw ms_uiless captures into schemas/kinfx-quick/ms_quick_order.tsv.

Input: one or more TSV files from tools/mscapture/ms_uiless.ps1, lines
    code<TAB>count;pageStarts;cand1\x01cand2...
A trailing "_" on the code means Space was pressed once after the code
(Windows shows single-letter Quick codes and some 2-letter codes only then).

Output: code<TAB>candidates separated by spaces, in Microsoft order.
Only single-character candidates are kept for 2-letter codes. Single-letter
codes keep only the first page (single characters) because the Space list
there is the Microsoft associated-phrase list, not the code list.
"""
from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def parse(paths: list[Path]) -> dict[str, list[str]]:
    raw: dict[str, list[str]] = {}
    spaced: dict[str, list[str]] = {}
    for p in paths:
        for line in p.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            code, _, rest = line.partition("\t")
            if not rest:
                continue
            n, _pages, items = rest.split(";", 2)
            if int(n) == 0:
                continue
            cands = items.split("\x01")
            if int(n) != len(cands):
                raise SystemExit(f"{p}: {code} count {n} != {len(cands)}")
            if code.endswith("_"):
                spaced[code[:-1]] = cands
            else:
                raw[code] = cands
    out: dict[str, list[str]] = {}
    for code, cands in raw.items():
        out[code] = cands
    for code, cands in spaced.items():
        if code in out:
            continue
        if len(code) == 1:
            # Space after one letter lists the letter's own characters only when
            # every entry is one glyph (h/i/k/l/n/y). Otherwise it is phrases.
            if all(len(c) == 1 for c in cands):
                out[code] = cands
        elif code[0] != "x":
            # 2-letter code that only answered after Space: still the code list.
            out[code] = cands
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+", type=Path)
    ap.add_argument("--out", type=Path, default=ROOT / "schemas/kinfx-quick/ms_quick_order.tsv")
    args = ap.parse_args()
    table = parse(args.inputs)
    lines = [
        "# Microsoft Quick (速成) candidate order, measured on Windows 11 Pro",
        "# (zh-TW, Microsoft 速成, Fixed Candidate Order off, Ext-A/B/HKSCS off).",
        "# Captured with tools/mscapture/ms_uiless.ps1 through TSF UILess mode;",
        "# nothing was committed. One code per line: code<TAB>candidates (space).",
        "# This is an order reference, not a dictionary. See docs/WIN_QUICK_RANK.md.",
    ]
    total = 0
    for code in sorted(table, key=lambda c: (len(c), c)):
        cands = [c for c in table[code] if len(c) == 1]
        if not cands:
            continue
        total += len(cands)
        lines.append(code + "\t" + " ".join(cands))
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"wrote {args.out}: {len(lines) - 5} codes, {total} entries")


if __name__ == "__main__":
    main()
