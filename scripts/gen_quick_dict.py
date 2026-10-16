#!/usr/bin/env python3
"""Generate kinfx_quick.dict.yaml in Microsoft Quick (速成) order.

Order source: schemas/kinfx-quick/ms_quick_order.tsv, the full candidate list
of every code as Windows 11 Pro shows it (captured with tools/mscapture).
Each code's rows are written in that order and the dict uses `sort: original`,
so librime shows exactly the Windows sequence on every page, not only page 1.

Coverage: characters that Windows does not list on a code but Cangjie 5 /
the rime-quick supplement do (HK glyphs such as 㗎, 𠻹 and Ext-A/B forms) are
appended after the Windows list in HK frequency order. Windows never shows
them, so they cannot move a Windows slot.

Weights are informational (phrase encoding picks each character's best code):
the essay frequency, so 我 keeps hi as its main code and 網 keeps vv.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

DENYLIST = frozenset({"丂", "丄", "丅", "丆", "丏", "丒", "丗"})
VERSION = "0.4.0"


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
        if w > out.get(parts[0], 0):
            out[parts[0]] = w
    return out


def combined_weight(ch: str, essay: dict[str, int], canto: dict[str, int]) -> int:
    return essay.get(ch, 0) + canto.get(ch, 0) * 5


def is_cjk(ch: str) -> bool:
    o = ord(ch)
    return (
        0x3400 <= o <= 0x4DBF  # Ext-A
        or 0x4E00 <= o <= 0x9FFF
        or 0xF900 <= o <= 0xFAFF
        or 0x20000 <= o <= 0x3134F  # Ext-B..G (HKSCS lives in B)
    )


def is_simplified_only(ch: str, trad_ok: set[str]) -> bool:
    return ch not in trad_ok


def load_ms_order(path: Path) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        code, _, chars = line.partition("\t")
        seen: set[str] = set()
        row: list[str] = []
        for ch in chars.split(" "):
            if ch and ch not in seen:
                seen.add(ch)
                row.append(ch)
        out[code] = row
    return out


def load_cangjie(path: Path) -> list[tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    body = text.split("\n...", 1)[1] if "\n..." in text else text
    out: list[tuple[str, str]] = []
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2 or len(parts[0]) != 1:
            continue
        base = parts[1].split("'")[0]
        if not re.fullmatch(r"[a-z]+", base) or base.startswith("z"):
            continue
        q = base if len(base) == 1 else base[0] + base[-1]
        out.append((parts[0], q))
    return out


def build_rows(
    ms: dict[str, list[str]],
    cangjie: list[tuple[str, str]],
    essay: dict[str, int],
    canto: dict[str, int],
    extra_min_weight: int = 1,
) -> tuple[list[tuple[str, str, int]], dict[str, int]]:
    """Rows in final order: per code, Windows list then frequency-ordered extras."""
    ms_chars = {ch for row in ms.values() for ch in row}
    extras: dict[str, dict[str, int]] = {}
    for ch, code in cangjie:
        if ch in DENYLIST or not is_cjk(ch):
            continue
        if ch in ms.get(code, ()):
            continue
        w = combined_weight(ch, essay, canto)
        # Glyphs Windows lists somewhere are real; for unseen glyphs require
        # some HK/essay usage so that unencoded Extension noise stays out.
        if ch not in ms_chars and w < extra_min_weight:
            continue
        slot = extras.setdefault(code, {})
        slot[ch] = max(slot.get(ch, 0), w)
    stats = {"ms": 0, "extra": 0}
    real = set(cangjie)
    rows: list[tuple[str, str, int]] = []
    codes = sorted(set(ms) | set(extras))
    for code in codes:
        # Windows lists are kept verbatim (even rare components such as 丂),
        # so every slot matches 微軟速成. DENYLIST only filters the HK tail.
        # A glyph Windows shows on a code Cangjie does not give it (網 on vd)
        # gets weight 0, so phrase encoding still picks its real code (vv).
        for ch in ms.get(code, []):
            w = combined_weight(ch, essay, canto) if (ch, code) in real or not real else 0
            rows.append((ch, code, w))
            stats["ms"] += 1
        tail = sorted(extras.get(code, {}).items(), key=lambda kv: (-kv[1], kv[0]))
        for ch, w in tail:
            rows.append((ch, code, w))
            stats["extra"] += 1
    return rows, stats


def assert_ms_order(rows: list[tuple[str, str, int]], ms: dict[str, list[str]]) -> None:
    grouped: dict[str, list[str]] = {}
    for ch, code, _w in rows:
        grouped.setdefault(code, []).append(ch)
    bad = []
    for code, want in ms.items():
        got = grouped.get(code, [])[: len(want)]
        if got != want:
            bad.append(code)
    if bad:
        raise SystemExit("Windows order lost on: " + " ".join(bad[:20]))


HEADER = """# encoding: utf-8
# Generated by scripts/gen_quick_dict.py — do not hand-edit.
# Sucheng / Microsoft Quick: Cangjie first + last code.
# Row order per code = Windows 11 Pro 微軟速成 full candidate list
# (schemas/kinfx-quick/ms_quick_order.tsv), then HK glyphs Windows lacks
# (Cangjie 5 / rime-quick supplement) in essay + 5x essay-cantonese order.
# `sort: original` keeps that row order on every page.
# Weights are essay frequency only (used to pick each glyph's main code).
# Licenses: NOTICE, third_party/rime-quick/LICENSE (LGPL-3.0 upstream).

---
name: kinfx_quick
version: "{version}"
sort: original
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
...

"""


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--cangjie", type=Path, default=Path("/usr/share/rime-data/cangjie5.dict.yaml"))
    p.add_argument(
        "--supplement",
        type=Path,
        default=ROOT / "third_party/rime-quick/quick5.supplement.dict.yaml",
    )
    p.add_argument("--essay", type=Path, default=Path("/usr/share/rime-data/essay.txt"))
    p.add_argument(
        "--essay-cantonese",
        type=Path,
        default=Path("/usr/share/rime-data/essay-cantonese.txt"),
    )
    p.add_argument("--ms-order", type=Path, default=ROOT / "schemas/kinfx-quick/ms_quick_order.tsv")
    p.add_argument(
        "--single",
        type=Path,
        default=ROOT / "schemas/kinfx-quick/win_quick_top9.tsv",
        help="fallback for single-letter codes (Windows shows them only after Space)",
    )
    p.add_argument("--out", type=Path, default=ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml")
    args = p.parse_args()

    ms = load_ms_order(args.ms_order)
    if args.single.exists():
        for line in args.single.read_text(encoding="utf-8").splitlines():
            if not line or line.startswith("#"):
                continue
            code, _, chars = line.partition("\t")
            if len(code) == 1 and code not in ms:
                ms[code] = list(dict.fromkeys(chars.strip()))
    essay = load_weights(args.essay)
    canto = load_weights(args.essay_cantonese)
    cangjie: list[tuple[str, str]] = []
    for src in (args.cangjie, args.supplement):
        if src.exists():
            cangjie.extend(load_cangjie(src))
        else:
            print(f"skip missing {src}")
    rows, stats = build_rows(ms, cangjie, essay, canto)
    assert_ms_order(rows, ms)
    with args.out.open("w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER.format(version=VERSION))
        for ch, code, w in rows:
            f.write(f"{ch}\t{code}\t{w}\n")
    print(
        f"wrote {args.out}: {len(rows)} rows "
        f"(windows {stats['ms']}, hk extras {stats['extra']}, codes {len({r[1] for r in rows})})"
    )


if __name__ == "__main__":
    main()
