#!/usr/bin/env python3
"""Build lexicon/en/kinfx_en_unsafe.txt: English words that Space must NOT commit.

KINFX v0.5 lets Space commit a held letter run as English when the run is an
English word (english/space: safe). That changes the Windows result only when
someone typing Chinese the Windows way produces the same letter run and then
presses Space (to page, or to list a one-letter code). This script estimates,
for every English word, how often that happens per 10,000 Chinese characters
and lists the words above a threshold. Space keeps its Windows meaning for them.

Model
  * Every character is typed with its cheapest Windows code (letters, Space per
    page, digit when not the first candidate or when the code is one letter).
  * A held run starts at a code boundary. It reaches word w and then Space only
    if w splits into pieces c1 .. ck + t where each ci is a two-letter code whose
    wanted character is its first candidate (topped out by the next key) and t
    is a code whose wanted character needs Space.
  * Character sequences use a first-order chain from essay-cantonese weights
    (within-word bigrams plus word-boundary pairs).

Inputs: schemas/kinfx-quick/ms_quick_order.tsv, win_quick_top9.tsv,
lexicon/en/kinfx_en.dict.yaml, essay-cantonese.txt (rime-cantonese).
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_order(path: Path, order: dict[str, list[str]], split_space: bool) -> None:
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.rstrip("\r\n")
        if not line or line.startswith("#"):
            continue
        code, _, rest = line.partition("\t")
        if code in order:
            continue
        order[code] = rest.split(" ") if split_space else list(rest)


def code_cost(code: str, rank: int) -> int:
    single = len(code) == 1
    return len(code) + (rank - 1) // 9 + single + (rank > 1 or single)


def load_words(path: Path) -> list[str]:
    words = set()
    body = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("..."):
            body = True
            continue
        if not body or not line or line.startswith("#"):
            continue
        parts = line.rstrip("\r\n").split("\t")
        if len(parts) >= 2 and parts[1].isascii() and parts[1].isalpha():
            words.add(parts[1].lower())
    return sorted(words)


def build(order_tsv: Path, single_tsv: Path, essay: Path, en_dict: Path, max_len: int,
          extra_dicts: tuple[Path, ...] = ()):
    order: dict[str, list[str]] = {}
    read_order(order_tsv, order, True)
    read_order(single_tsv, order, False)
    best: dict[str, tuple[str, int, int]] = {}
    for code, cands in order.items():
        for rank, ch in enumerate(cands, 1):
            k = code_cost(code, rank)
            if ch not in best or k < best[ch][2]:
                best[ch] = (code, rank, k)
    needs_space = {ch for ch, (c, r, _) in best.items() if len(c) == 1 or r > 9}
    rank1_by_code = {c: ch for ch, (c, r, _) in best.items() if len(c) == 2 and r == 1}
    space_by_code: dict[str, list[str]] = defaultdict(list)
    for ch in needs_space:
        space_by_code[best[ch][0]].append(ch)

    uni: Counter = Counter()
    bi: Counter = Counter()
    start: Counter = Counter()
    end: Counter = Counter()
    for line in essay.read_text(encoding="utf-8").splitlines():
        parts = line.rstrip("\r\n").split("\t")
        if len(parts) < 2 or not parts[1].isdigit():
            continue
        word, f = parts[0], int(parts[1])
        if not all(ch in best for ch in word):
            continue
        for ch in word:
            uni[ch] += f
        for a, b in zip(word, word[1:]):
            bi[(a, b)] += f
        start[word[0]] += f
        end[word[-1]] += f
    total = sum(uni.values())
    starts = sum(start.values())
    p_uni = {ch: n / total for ch, n in uni.items()}

    def p_next(a: str, b: str) -> float:
        """P(next char = b | current char = a)."""
        na = uni.get(a, 0)
        if not na:
            return 0.0
        within = bi.get((a, b), 0) / na
        boundary = (end.get(a, 0) / na) * (start.get(b, 0) / starts)
        return within + boundary

    def rate(word: str) -> float:
        """Expected Space collisions per 10k Chinese characters."""
        out = 0.0

        def walk(pos: int, prev: str | None, p: float) -> None:
            """prev = last topped-out character (None at the run start)."""
            nonlocal out
            rest = word[pos:]
            if len(rest) <= 2:
                for b in space_by_code.get(rest, ()):
                    out += p_uni.get(b, 0.0) if prev is None else p * p_next(prev, b)
            if len(rest) >= 3:
                c = rest[:2]
                a = rank1_by_code.get(c)
                if a:
                    pa = p_uni.get(a, 0.0) if prev is None else p * p_next(prev, a)
                    if pa > 1e-12:
                        walk(pos + 2, a, pa)

        walk(0, None, 1.0)
        return out * 1e4

    words = sorted({w for d in (en_dict, *extra_dicts) for w in load_words(d) if len(w) <= max_len})
    rates = {w: rate(w) for w in words}
    # Every two-letter English word that is a real Sucheng code must be unsafe:
    # Space on a two-letter code pages the Chinese menu, so committing English
    # there would break ordinary Sucheng typing. Short English always needs an
    # explicit key (Left Shift) — see docs §4.2. The rate model above counts
    # only high-rank characters that need Space, which understates this.
    for w in rates:
        if len(w) == 2 and w in order:
            rates[w] = 1e9
    return rates


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--essay-cantonese", type=Path, required=True)
    ap.add_argument("--order", type=Path, default=ROOT / "schemas/kinfx-quick/ms_quick_order.tsv")
    ap.add_argument("--single", type=Path, default=ROOT / "schemas/kinfx-quick/win_quick_top9.tsv")
    ap.add_argument("--en-dict", type=Path, default=ROOT / "lexicon/en/kinfx_en.dict.yaml")
    ap.add_argument("--names-dict", type=Path, default=ROOT / "lexicon/en/kinfx_names.dict.yaml",
                    help="v0.5.4 brand names, rated like SCOWL words (missing file = skipped)")
    ap.add_argument("--threshold", type=float, default=0.01,
                    help="max collisions per 10k Chinese chars for Space to commit the word")
    ap.add_argument("--max-len", type=int, default=10)
    ap.add_argument("--out", type=Path, default=ROOT / "lexicon/en/kinfx_en_unsafe.txt")
    args = ap.parse_args()
    extra = (args.names_dict,) if args.names_dict and args.names_dict.exists() else ()
    rates = build(args.order, args.single, args.essay_cantonese, args.en_dict, args.max_len, extra)
    unsafe = sorted(w for w, r in rates.items() if r > args.threshold)
    kept = sum(r for w, r in rates.items() if r <= args.threshold)
    long_unsafe = [w for w in unsafe if len(w) >= 5]
    header = [
        "# Generated by scripts/gen_english_space.py — do not hand-edit.",
        "# English words that Space must not commit (english/space: safe | long).",
        "# Typing Chinese the Windows way reaches these letters and then presses",
        f"# Space more than {args.threshold} times per 10,000 characters (model in the script).",
        f"# Words checked: {len(rates)}; listed: {len(unsafe)} ({len(long_unsafe)} of 5+ letters).",
        f"# Expected Space changes left for all other words: {kept:.3f} per 10,000 characters.",
        "# Word list: SCOWL + kinfx_names (Wikidata, CC0) (lexicon/NOTICE). Weights: rime-cantonese essay (CC BY 4.0).",
    ]
    args.out.write_text("\n".join(header + unsafe) + "\n", encoding="utf-8", newline="\n")
    print(f"wrote {args.out}: {len(unsafe)} unsafe of {len(rates)}; residual {kept:.3f}/10k; "
          f"5+ letters unsafe {len(long_unsafe)} {long_unsafe[:20]}")


if __name__ == "__main__":
    main()
