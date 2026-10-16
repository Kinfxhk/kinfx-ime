#!/usr/bin/env python3
"""How often does holding the third key change Windows-style typing?

Model: a Windows Quick user types code A (2 letters) then code B and relies on
the top-out, so the expected text is top(A)+top(B) (the first candidate of
each code). KINFX holds the third letter when A+B[0] is a capture gate. The
result then changes only if the user's next action is "1"/Space-confirm and
the first held candidate differs from top(A)+top(B) — or the hold carries on
through B[1] and swallows a code the user meant to start fresh.

We count, over every A,B pair of measured 2-letter codes (weighted by the
essay frequency of top(A)+top(B) as a bigram where available), the share of
pairs whose fourth key lands in a held phrase state. Printed for several
capture floors so the threshold can be picked with a number, not a guess.

Usage: python tools/rimeh/hold_impact.py
"""
from __future__ import annotations

import bisect
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_rows(path: Path) -> list[tuple[str, str, int]]:
    text = path.read_text(encoding="utf-8").split("\n...\n", 1)[1]
    out = []
    for line in text.splitlines():
        p = line.rstrip("\r\n").split("\t")
        if len(p) >= 3 and p[1].isalpha():
            out.append((p[0], p[1], int(p[2])))
    return out


def main() -> None:
    order = {}
    for line in (ROOT / "schemas/kinfx-quick/ms_quick_order.tsv").read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or "\t" not in line:
            continue
        code, chars = line.split("\t", 1)
        if len(code) == 2:
            order[code] = chars.split(" ")[0]
    phrases = load_rows(ROOT / "lexicon/hk/kinfx_hk_words.dict.yaml") + load_rows(
        ROOT / "lexicon/hk/kinfx_hk_idioms.dict.yaml"
    )
    codes_sorted = sorted({c for _t, c, _w in phrases})
    by_text = {}
    for t, c, w in phrases:
        by_text[t] = max(by_text.get(t, 0), w)

    def has_prefix(p: str) -> bool:
        i = bisect.bisect_left(codes_sorted, p)
        return i < len(codes_sorted) and codes_sorted[i].startswith(p)

    pairs = [(a, b) for a in order for b in order]
    # Char frequency of each code's Windows top (essay weight in the dict).
    qrows = load_rows(ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml")
    freq = {}
    for t, c, w in qrows:
        if c in order and order[c] == t:
            freq[c] = max(freq.get(c, 0), w)
    first_phrase = {}
    for t, c, w in phrases:
        if c not in first_phrase or w > first_phrase[c][1]:
            first_phrase[c] = (t, w)
    print("\nHarm model: user relies on Windows top-out and picks with 1/Enter after")
    print("code B. Harm = held@4 and the held menu's first item != top(A)+top(B).")
    print("Weighted = pairs weighted by freq(top A) * freq(top B) (essay char freq).")
    tot_fw = sum(freq.get(a, 0) * freq.get(b, 0) for a, b in pairs) or 1
    print("floor    harm(uniform)  harm(freq-weighted)")
    for floor in (5000, 10000, 19000, 30000, 50000):
        gates = {c[:3] for _t, c, w in phrases if w >= floor and len(c) >= 3}
        h = 0
        hw = 0
        for a, b in pairs:
            if (a + b[0]) not in gates or not has_prefix(a + b):
                continue
            fp = first_phrase.get(a + b)
            if fp is None or fp[0] != order[a] + order[b]:
                h += 1
                hw += freq.get(a, 0) * freq.get(b, 0)
        print(f"{floor:>6}  {h / len(pairs):12.3%}  {hw / tot_fw:18.3%}")
    print()
    print("Policy P2: gate at key 3 AND key 4 by floor; full table only after key 4.")
    print("floor    gates3  gates4  harm(uniform)  harm(freq-weighted)")
    for floor in (5000, 10000, 19000, 30000, 50000, 100000):
        hot = [(t, c, w) for t, c, w in phrases if w >= floor and len(c) >= 3]
        g3 = {c[:3] for _t, c, _w in hot}
        g4 = {c[:4] for _t, c, _w in hot if len(c) >= 4}
        h = 0
        hw = 0
        for a, b in pairs:
            if (a + b[0]) not in g3 or (a + b) not in g4:
                continue
            fp = first_phrase.get(a + b)
            if fp is None or fp[0] != order[a] + order[b]:
                h += 1
                hw += freq.get(a, 0) * freq.get(b, 0)
        print(f"{floor:>6}  {len(g3):>6}  {len(g4):>6}  {h / len(pairs):12.3%}  {hw / tot_fw:18.3%}")
    print()
    # Weight each pair by how often its Windows result is a real word (bigram).
    total_w = sum(1 + by_text.get(order[a] + order[b], 0) for a, b in pairs)
    print(f"pairs {len(pairs)}  (2-letter codes {len(order)})")
    print("floor    gates  held@3   held@4   held@4 weighted   note")
    for floor in (5000, 10000, 19000, 30000, 50000, 100000):
        gates = {c[:3] for _t, c, w in phrases if w >= floor and len(c) >= 3}
        held3 = held4 = 0
        held4_w = 0
        for a, b in pairs:
            k3 = a + b[0]
            if k3 not in gates:
                continue
            held3 += 1
            if has_prefix(a + b):
                held4 += 1
                held4_w += 1 + by_text.get(order[a] + order[b], 0)
        note = "ofc gate" if "ofc" in gates else "ofc NOT gated"
        print(
            f"{floor:>6}  {len(gates):>6}  {held3 / len(pairs):7.2%}  {held4 / len(pairs):7.2%}  "
            f"{held4_w / total_w:14.2%}   {note}"
        )
    print()
    print("held@3: third key held instead of topping out (shows phrases; Space/1 still")
    print("        gives the phrase, a non-phrase 4th key splits back to Windows text).")
    print("held@4: the 4th key also continues a phrase, so a user relying on Windows")
    print("        top-out sees a phrase menu instead of top(A)+B's menu.")


if __name__ == "__main__":
    sys.exit(main())
