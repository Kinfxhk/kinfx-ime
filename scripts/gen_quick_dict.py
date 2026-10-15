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

# Windows first page is pinned by weight. See docs/WIN_QUICK_RANK.md.
# No per-keystroke filter: librime sort: by_weight reads these numbers.
WIN_PAGE_LEN = 9


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


def _assign_code(
    order: list[str],
    page_len: int,
    original: dict[str, int],
) -> dict[str, int]:
    """Keep frequency weights. Raise a glyph only to sit strictly above the next.

    The tail is already frequency-sorted, so it usually stays put. Windows
    page glyphs bubble up in front of that tail. Absolute weights stay in the
    essay range, which keeps phrase-code ties and sentence quality stable.
    """
    weights = {ch: max(original.get(ch, 0), 0) for ch in order}
    if not order:
        return weights
    if weights[order[-1]] < 1:
        weights[order[-1]] = 1
    if page_len <= 0:
        return weights
    for i in range(len(order) - 2, -1, -1):
        if weights[order[i]] <= weights[order[i + 1]]:
            weights[order[i]] = weights[order[i + 1]] + 1
    return weights


def _fits(weight_of: dict[str, int], order: list[str], ch: str, target: int) -> bool:
    if target < 1:
        return False
    idx = order.index(ch)
    if idx > 0 and target >= weight_of[order[idx - 1]]:
        return False
    if idx + 1 < len(order) and target <= weight_of[order[idx + 1]]:
        return False
    return True


def _restore_primaries(
    weight_maps: dict[str, dict[str, int]],
    orders: dict[str, list[str]],
    alts: dict[str, list[tuple[int, int, str]]],
) -> int:
    """Move weights back when a pin stole a character's best code and order allows it."""
    old_code = {ch: max(cands)[2] for ch, cands in alts.items()}

    def winner(ch: str) -> tuple[int, int, str] | None:
        cands = [
            (wmap[ch], len(code), code)
            for code, wmap in weight_maps.items()
            if ch in wmap
        ]
        if not cands:
            return None
        return max(cands)

    flips = 0
    for _ in range(4):
        progress = False
        for ch, primary in old_code.items():
            win = winner(ch)
            if win is None or win[2] == primary:
                continue
            new_code = win[2]
            if primary not in weight_maps or ch not in weight_maps[primary]:
                continue
            if new_code not in weight_maps or ch not in weight_maps[new_code]:
                continue
            primary_w = weight_maps[primary][ch]
            new_w = weight_maps[new_code][ch]
            # Prefer keeping the historical primary: lower the pinned code if
            # it still sits strictly between its neighbours.
            if (len(new_code), new_code) < (len(primary), primary):
                lower_to = primary_w
            else:
                lower_to = primary_w - 1
            if _fits(weight_maps[new_code], orders[new_code], ch, lower_to):
                weight_maps[new_code][ch] = lower_to
                progress = True
                continue
            if (len(primary), primary) > (len(new_code), new_code):
                raise_to = new_w
            else:
                raise_to = new_w + 1
            if _fits(weight_maps[primary], orders[primary], ch, raise_to):
                weight_maps[primary][ch] = raise_to
                progress = True
        if not progress:
            break
    seen: set[str] = set()
    for ch, primary in old_code.items():
        win = winner(ch)
        if win is not None and win[2] != primary and ch not in seen:
            seen.add(ch)
            flips += 1
    return flips


def apply_win_top9_pin(
    rows: list[tuple[str, str, int]],
    win_top9: dict[str, list[str]],
) -> list[tuple[str, str, int]]:
    """Pin each Windows page to ranks 1..n by weight. Tail stays frequency order.

    Common characters are not lifted over that page. 我／係／唔 stay where
    Windows put them. 倉 is not forced onto page 1.
    """
    by_code: dict[str, dict[str, int]] = {}
    for ch, code, weight in rows:
        slot = by_code.setdefault(code, {})
        if weight > slot.get(ch, -1):
            slot[ch] = weight
    alts = _alts_index(rows)
    orders: dict[str, list[str]] = {}
    weight_maps: dict[str, dict[str, int]] = {}
    for code, entries in by_code.items():
        page = _page_chars(win_top9.get(code, []), entries)
        for ch in page:
            entries.setdefault(ch, 0)
        page_set = set(page)
        rest = sorted(
            (ch for ch in entries if ch not in page_set),
            key=lambda ch: (-entries[ch], ch),
        )
        order = page + rest
        orders[code] = order
        weight_maps[code] = _assign_code(order, len(page), entries)
    flips = _restore_primaries(weight_maps, orders, alts)
    out: list[tuple[str, str, int]] = []
    for code, order in orders.items():
        wmap = weight_maps[code]
        for ch in order:
            out.append((ch, code, wmap[ch]))
    out.sort(key=lambda r: (r[1], -r[2], r[0]))
    print(f"win top9: pinned {sum(1 for c in orders if win_top9.get(c))} codes; "
          f"primary-code flips {flips}")
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
# Weights: essay.txt + 5× essay-cantonese.txt (HK bias), then Windows top-9
# pinned to ranks 1–9 (win_quick_top9.tsv; vd ends 網綜). No hot-char lift.
# Filtered: non-BMP, denylist, z-codes.
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
