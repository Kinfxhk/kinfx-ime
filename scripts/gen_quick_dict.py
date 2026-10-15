#!/usr/bin/env python3
"""Generate kinfx_quick.dict.yaml (Sucheng = Cangjie first+last) with HK-biased weights."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Rare / non-practical glyphs that should not surface in Sucheng menus.
DENYLIST = frozenset({"丂", "丄", "丅", "丆", "丏", "丒", "丗"})

# Minimum combined weight to keep (0-weight Extension noise drops out).
MIN_WEIGHT = 1

# Windows first-page boost. See docs/WIN_QUICK_RANK.md.
# Near-tie: two characters that both sit on the legacy Windows first page,
# and whose HK weights are within this ratio, follow Windows order.
WIN_NEAR_TIE = 1.15
# Ignore Windows-page glyphs lighter than this (汞／昤 class) so they
# cannot ride a near-tie onto the page.
WIN_PRACTICAL_MIN = 8000
# Frequency champions at or above this stay ahead of an explicit lift.
WIN_ANCHOR_MIN = 200_000
# 1-based maximum rank. Legacy Windows puts 倉 at 22; the product still
# keeps it on the first page of 9. 夏 matches the legacy rank of 5.
PAGE1_MAX_RANK = {
    ("me", "夏"): 5,
    ("or", "倉"): 9,
}


def load_weights(path: Path) -> dict[str, int]:
    out: dict[str, int] = {}
    if not path.exists():
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) < 2 or len(parts[0]) != 1:
            continue
        try:
            w = int(float(parts[1]))
        except ValueError:
            continue
        ch = parts[0]
        if w > out.get(ch, 0):
            out[ch] = w
    return out


def combined_weight(ch: str, essay: dict[str, int], canto: dict[str, int]) -> int:
    # Prefer Cantonese essay strongly so 我／唔／係／嘅 rank above Mandarin-heavy peers.
    return essay.get(ch, 0) + canto.get(ch, 0) * 5


def is_basic_cjk(ch: str) -> bool:
    o = ord(ch)
    return 0x4E00 <= o <= 0x9FFF


def load_win_top9(path: Path) -> dict[str, list[str]]:
    """code -> Windows first-page characters (at most 9), in Windows order."""
    out: dict[str, list[str]] = {}
    if not path.exists():
        print(f"warning: missing Win top-9 reference {path}")
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        code, chars = line.split("\t", 1)
        out[code] = list(chars)
    return out


def _boost_code(
    code: str,
    entries: list[tuple[str, int]],
    win_page: list[str],
) -> list[tuple[str, int]]:
    """Return (char, weight) in candidate order with weights made strict."""
    order = [ch for ch, _w in entries]
    base = {ch: w for ch, w in entries}
    weight = dict(base)
    win_index: dict[str, int] = {}
    for i, ch in enumerate(win_page):
        if ch in base and ch not in win_index:
            win_index[ch] = i
    on_win_page = set(win_page)
    index = {ch: i for i, ch in enumerate(order)}

    for ch in win_page:
        if ch not in base or base[ch] < WIN_PRACTICAL_MIN or ch not in win_index:
            continue
        guard = 0
        while index[ch] > win_index[ch] and guard < 80:
            guard += 1
            i = index[ch]
            prev = order[i - 1]
            # Only reorder inside the Windows first page, and only when the
            # frequency gap is a near-tie. Heavier champions stay put.
            if prev not in on_win_page:
                break
            if base[prev] > base[ch] * WIN_NEAR_TIE:
                break
            if win_index.get(prev, 10**9) <= win_index[ch]:
                break
            order[i - 1], order[i] = order[i], order[i - 1]
            index[order[i]] = i
            index[order[i - 1]] = i - 1

    for (t_code, ch), max_rank in PAGE1_MAX_RANK.items():
        if t_code != code or ch not in index:
            continue
        guard = 0
        while index[ch] > max_rank - 1 and guard < 40:
            guard += 1
            i = index[ch]
            prev = order[i - 1]
            if base[prev] >= WIN_ANCHOR_MIN and base[ch] < WIN_ANCHOR_MIN:
                break
            order[i - 1], order[i] = order[i], order[i - 1]
            index[order[i]] = i
            index[order[i - 1]] = i - 1

    for i in range(len(order) - 2, -1, -1):
        above, below = order[i], order[i + 1]
        if weight[above] <= weight[below]:
            weight[above] = weight[below] + 1
    return [(ch, weight[ch]) for ch in order]


def apply_win_page_boost(
    rows: list[tuple[str, str, int]],
    win_top9: dict[str, list[str]],
) -> list[tuple[str, str, int]]:
    by_code: dict[str, list[tuple[str, int]]] = {}
    for ch, code, w in rows:
        by_code.setdefault(code, []).append((ch, w))
    out: list[tuple[str, str, int]] = []
    for code, entries in by_code.items():
        entries.sort(key=lambda r: (-r[1], r[0]))
        for ch, w in _boost_code(code, entries, win_top9.get(code, [])):
            out.append((ch, code, w))
    out.sort(key=lambda r: (r[1], -r[2], r[0]))
    return out


def assert_page1_targets(rows: list[tuple[str, str, int]]) -> None:
    grouped: dict[str, list[str]] = {}
    for ch, code, _w in rows:
        grouped.setdefault(code, []).append(ch)
    # rows are sorted by code then weight desc, so order within a code is rank.
    failures: list[str] = []
    for (code, ch), max_rank in PAGE1_MAX_RANK.items():
        seq = grouped.get(code, [])
        rank = seq.index(ch) + 1 if ch in seq else -1
        if rank < 1 or rank > max_rank:
            failures.append(f"{ch}@{code} rank {rank} (want ≤{max_rank})")
    anchors = {"hi": "我", "ai": "時", "vd": "好"}
    for code, ch in anchors.items():
        seq = grouped.get(code, [])
        rank = seq.index(ch) + 1 if ch in seq else -1
        if rank != 1:
            failures.append(f"{ch}@{code} rank {rank} (want 1)")
    if failures:
        raise SystemExit("Win page boost missed targets: " + "; ".join(failures))


def load_entries(path: Path) -> list[tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    body = text.split("...", 1)[1] if "..." in text else text
    out: list[tuple[str, str]] = []
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        char, code = parts[0], parts[1]
        if len(char) != 1:
            continue
        base = code.split("'")[0]
        if not base or not re.fullmatch(r"[a-z]+", base):
            continue
        # Drop sole-z / z-prefix oddballs (cangjie "我\tz" etc.)
        if base == "z" or base.startswith("z"):
            continue
        q = base if len(base) == 1 else base[0] + base[-1]
        out.append((char, q))
    return out


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--cangjie",
        type=Path,
        default=Path("/usr/share/rime-data/cangjie5.dict.yaml"),
    )
    p.add_argument(
        "--supplement",
        type=Path,
        default=ROOT / "third_party/rime-quick/quick5.supplement.dict.yaml",
    )
    p.add_argument(
        "--essay",
        type=Path,
        default=Path("/usr/share/rime-data/essay.txt"),
    )
    p.add_argument(
        "--essay-cantonese",
        type=Path,
        default=Path("/usr/share/rime-data/essay-cantonese.txt"),
    )
    p.add_argument(
        "--win-top9",
        type=Path,
        default=ROOT / "schemas/kinfx-quick/win_quick_top9.tsv",
    )
    p.add_argument(
        "--out",
        type=Path,
        default=ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml",
    )
    args = p.parse_args()

    essay = load_weights(args.essay)
    canto = load_weights(args.essay_cantonese)

    seen: set[tuple[str, str]] = set()
    rows: list[tuple[str, str, int]] = []
    skipped_rare = skipped_deny = skipped_weight = 0
    for src in (args.cangjie, args.supplement):
        if not src.exists():
            print(f"skip missing {src}")
            continue
        for char, q in load_entries(src):
            key = (char, q)
            if key in seen:
                continue
            seen.add(key)
            if char in DENYLIST:
                skipped_deny += 1
                continue
            if not is_basic_cjk(char):
                skipped_rare += 1
                continue
            w = combined_weight(char, essay, canto)
            if w < MIN_WEIGHT:
                skipped_weight += 1
                continue
            rows.append((char, q, w))

    # Stable: higher weight first within same code helps some RIME builds.
    rows.sort(key=lambda r: (r[1], -r[2], r[0]))
    win_top9 = load_win_top9(args.win_top9)
    rows = apply_win_page_boost(rows, win_top9)
    assert_page1_targets(rows)

    header = """# encoding: utf-8
# Generated by scripts/gen_quick_dict.py — Sucheng/Quick = Cangjie first+last.
# Weights: essay.txt + 5× essay-cantonese.txt (HK bias), then a Windows
# first-page near-tie boost (win_quick_top9.tsv) plus explicit lifts for
# 夏@me and 倉@or. Filtered: non-BMP, denylist, z-codes.
# Licenses: see NOTICE and third_party/rime-quick/LICENSE (LGPL-3.0 upstream).
# Ranking notes: docs/WIN_QUICK_RANK.md.

---
name: kinfx_quick
version: "0.1.1"
sort: by_weight
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
...

"""
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        f.write(header)
        for char, q, w in rows:
            f.write(f"{char}\t{q}\t{w}\n")
    print(
        f"wrote {args.out} ({len(rows)} entries; "
        f"skip rare={skipped_rare} deny={skipped_deny} weight0={skipped_weight})"
    )


if __name__ == "__main__":
    main()
