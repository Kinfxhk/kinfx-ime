#!/usr/bin/env python3
"""List the heaviest pairs a hold policy changes, to sanity-check the floor.

Usage: python tools/rimeh/hold_harm_top.py [floor3] [floor4_exact]
  floor3       : capture gate floor for keys 3 and 4 (default 19000)
  floor4_exact : extra key-4 hold when A+B is the exact code of a phrase
                 at least this heavy (default 3000; 0 disables)
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_rows(path: Path):
    text = path.read_text(encoding="utf-8").split("\n...\n", 1)[1]
    for line in text.splitlines():
        p = line.rstrip("\r\n").split("\t")
        if len(p) >= 3 and p[1].isalpha():
            yield p[0], p[1], int(p[2])


def main() -> None:
    floor = int(sys.argv[1]) if len(sys.argv) > 1 else 19000
    exact_floor = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
    order = {}
    for line in (ROOT / "schemas/kinfx-quick/ms_quick_order.tsv").read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or "\t" not in line:
            continue
        code, chars = line.split("\t", 1)
        if len(code) == 2:
            order[code] = chars.split(" ")[0]
    phrases = list(load_rows(ROOT / "lexicon/hk/kinfx_hk_words.dict.yaml")) + list(
        load_rows(ROOT / "lexicon/hk/kinfx_hk_idioms.dict.yaml")
    )
    freq = {}
    for t, c, w in load_rows(ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml"):
        if c in order and order[c] == t:
            freq[c] = max(freq.get(c, 0), w)
    first = {}
    exact_best = {}
    for t, c, w in phrases:
        if c not in first or w > first[c][1]:
            first[c] = (t, w)
        if len(c) == 4 and w > exact_best.get(c, 0):
            exact_best[c] = w
    hot = [(t, c, w) for t, c, w in phrases if w >= floor]
    exact3 = {c for _t, c, w in phrases if len(c) == 3 and w >= max(exact_floor, 0)} if exact_floor > 0 else set()
    g3 = {c[:3] for _t, c, _w in hot} | exact3
    g4 = {c[:4] for _t, c, _w in hot if len(c) >= 4}
    if exact_floor < 0:  # runtime policy: any phrase continues after the gate
        g4 = {c[:4] for _t, c, _w in phrases if len(c) >= 4}
    elif exact_floor == -2:  # runtime policy B: gate 3 and gate 4 by floor, then full table
        pass
    elif exact_floor:
        g4 |= {c for c, w in exact_best.items() if w >= exact_floor and c[:3] in g3}
    tot = sum(freq.get(a, 0) * freq.get(b, 0) for a in order for b in order) or 1
    harm = []
    for a in order:
        for b in order:
            if (a + b[0]) not in g3 or (a + b) not in g4:
                continue
            fp = first.get(a + b)
            want = order[a] + order[b]
            if fp is None or fp[0] != want:
                harm.append((freq.get(a, 0) * freq.get(b, 0), a + b, want, fp[0] if fp else "∅"))
    harm.sort(reverse=True)
    share = sum(h[0] for h in harm) / tot
    print(f"floor3={floor} exact4={exact_floor}  gates3={len(g3)} gates4={len(g4)}  "
          f"harm pairs={len(harm)} ({len(harm) / len(order) ** 2:.3%})  freq-weighted={share:.3%}")
    for w, code, want, got in harm[:15]:
        print(f"  {code}: Windows {want}  held-first {got}  share {w / tot:.3%}")


if __name__ == "__main__":
    main()
