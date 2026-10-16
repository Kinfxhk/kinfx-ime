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

# Windows first page is row order within each code (`sort: original`).
# Essay weights stay put. A rare page pin must not inherit a champion weight:
# that chain fills the single-letter menu (h) with 么／我／丟 ahead of ordinary
# completions. Exact 竹 stays first.
# See docs/WIN_QUICK_RANK.md. No per-keystroke filter.
WIN_PAGE_LEN = 9

# Win glyphs placed on a code they do not have in Cangjie. Must stay strictly
# below every real reading so they cannot become the primary code.
INJECTED_WEIGHT = 0


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
        page: list[str] = []
        seen: set[str] = set()
        for ch in chars:
            if ch in seen:
                continue
            seen.add(ch)
            page.append(ch)
            if len(page) == WIN_PAGE_LEN:
                break
        out[code] = page
    return out


def _alts_index(
    rows: list[tuple[str, str, int]],
) -> dict[str, list[tuple[int, int, str]]]:
    """char -> (weight, code length, code) for the best row of each code."""
    best: dict[tuple[str, str], int] = {}
    for ch, code, weight in rows:
        key = (ch, code)
        if weight > best.get(key, -1):
            best[key] = weight
    alts: dict[str, list[tuple[int, int, str]]] = {}
    for (ch, code), weight in best.items():
        alts.setdefault(ch, []).append((weight, len(code), code))
    return alts


def _injectable(ch: str) -> bool:
    return is_basic_cjk(ch) and ch not in DENYLIST


def _page_chars(raw: list[str], entries: dict[str, int]) -> list[str]:
    """Windows glyphs we can actually place on this code, in Windows order."""
    page: list[str] = []
    for ch in raw:
        if ch in entries or _injectable(ch):
            page.append(ch)
    return page


def _winner(
    ch: str, weight_maps: dict[str, dict[str, int]]
) -> tuple[int, int, str] | None:
    cands = [
        (wmap[ch], len(code), code)
        for code, wmap in weight_maps.items()
        if ch in wmap
    ]
    if not cands:
        return None
    return max(cands)


def _guarantee_primaries(
    weight_maps: dict[str, dict[str, int]],
    alts: dict[str, list[tuple[int, int, str]]],
) -> None:
    """Fail the build if any code outranks a character's real Cangjie primary.

    Injected Win-only rows stay at INJECTED_WEIGHT, so this is a hard check
    rather than a best-effort weight nudge that prints leftover flips.
    """
    primaries = {ch: max(cands)[2] for ch, cands in alts.items()}
    stolen: list[str] = []
    for ch, primary in primaries.items():
        win = _winner(ch, weight_maps)
        if win is not None and win[2] != primary:
            stolen.append(f"{ch}:{win[2]}!={primary}")
    if stolen:
        raise SystemExit("primary code stolen: " + "; ".join(stolen[:12]))


def apply_win_top9_pin(
    rows: list[tuple[str, str, int]],
    win_top9: dict[str, list[str]],
) -> list[tuple[str, str, int]]:
    """Put each Windows page first in row order. Weights stay essay frequency.

    librime `sort: original` keeps that row order, so page 1 does not need a
    weight chain. A rare pin such as 凡 on hi therefore cannot inherit 我's
    weight and drag 么／我／丟 into the single-letter h menu ahead of 竹.

    Glyphs the page shows on a code absent from Cangjie are inserted at
    INJECTED_WEIGHT. That cannot outrank a real primary (綜 stays on vf,
    網 stays on vv). Common characters are not lifted over the page.
    倉 is not forced onto page 1.
    """
    by_code: dict[str, dict[str, int]] = {}
    real_pairs: set[tuple[str, str]] = set()
    for ch, code, weight in rows:
        real_pairs.add((ch, code))
        slot = by_code.setdefault(code, {})
        if weight > slot.get(ch, -1):
            slot[ch] = weight
    alts = _alts_index(rows)
    orders: dict[str, list[str]] = {}
    weight_maps: dict[str, dict[str, int]] = {}
    injected = 0
    for code, entries in by_code.items():
        page = _page_chars(win_top9.get(code, []), entries)
        page_set = set(page)
        for ch in page:
            if (ch, code) not in real_pairs:
                entries[ch] = INJECTED_WEIGHT
                injected += 1
        rest = sorted(
            (ch for ch in entries if ch not in page_set),
            key=lambda ch: (-entries[ch], ch),
        )
        orders[code] = page + rest
        weight_maps[code] = dict(entries)
    _guarantee_primaries(weight_maps, alts)
    out: list[tuple[str, str, int]] = []
    for code in sorted(orders):
        wmap = weight_maps[code]
        for ch in orders[code]:
            out.append((ch, code, wmap[ch]))
    print(
        f"win top9: pinned {sum(1 for c in orders if win_top9.get(c))} codes; "
        f"injected {injected}; primaries held"
    )
    return out


def assert_win_top9(
    rows: list[tuple[str, str, int]],
    win_top9: dict[str, list[str]],
) -> None:
    grouped: dict[str, list[str]] = {}
    for ch, code, _w in rows:
        grouped.setdefault(code, []).append(ch)
    failures: list[str] = []
    for code, raw in win_top9.items():
        seq = grouped.get(code, [])
        present = set(seq)
        want = [
            ch
            for ch in raw
            if ch in present or _injectable(ch)
        ]
        for i, ch in enumerate(want):
            got = seq[i] if i < len(seq) else "∅"
            if got != ch:
                failures.append(f"{code}[{i + 1}] got {got} want {ch}")
                break
    if failures:
        raise SystemExit("Win top9 pin missed: " + "; ".join(failures[:12]))


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
    rows = apply_win_top9_pin(rows, win_top9)
    assert_win_top9(rows, win_top9)

    header = """# encoding: utf-8
# Generated by scripts/gen_quick_dict.py — Sucheng/Quick = Cangjie first+last.
# Weights stay essay.txt + 5× essay-cantonese.txt (HK bias). They are not
# chained to force Windows order: a rare page pin must not inherit a champion
# weight (凡 must not bury 竹 on h under enable_completion).
# Page order is row order (`sort: original`): win_quick_top9.tsv first (at
# most 9; vd ends 網綜), then frequency. Win-only codes absent from Cangjie
# are weight 0 and cannot outrank the real primary (網@vv, 綜@vf).
# No hot-char lift. Filtered: non-BMP, denylist, z-codes.
# Licenses: see NOTICE and third_party/rime-quick/LICENSE (LGPL-3.0 upstream).
# Ranking notes: docs/WIN_QUICK_RANK.md.

---
name: kinfx_quick
version: "0.1.2"
sort: original
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
