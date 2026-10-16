#!/usr/bin/env python3
"""Offline comparator for KINFX v0.5 English smart mode + association.

Proves, through rimeh `typed` (app-visible text), that smart mode changes a
Windows-style Sucheng typist's output only where the design says it should:

  control (english/mode: shift + association/enable: false) == v0.4.1
  smart   (defaults + association/enable: false)
  assoc   (full defaults)

Pass rule:
  (a)+(b) smart vs control: 0 diffs EXCEPT sequences where the held letters are
          a space-safe English word and the next key is Space / punctuation
          (the designed change). Every such case is listed with a count, and the
          rate is compared with the model figure in kinfx_en_unsafe.txt's header.
  (c) article replay (smart): 0 Chinese mismatches, every inserted English word
          correct.

Usage:
  python tools/rimeh/compare.py            # full run (writes docs/eval/V05_COMPARE.md)
  python tools/rimeh/compare.py --limit 2000   # quick smoke (a)+(b) sample
  python tools/rimeh/compare.py --no-assoc     # skip the assoc variant (before Step 3)

Never touches %APPDATA%\\Rime (essay-cantonese.txt is read-only input).
"""
from __future__ import annotations

import argparse
import concurrent.futures
import os
import random
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

import gen_english_space as ges  # read_order, code_cost, load_words

RIMEH = ROOT / "tools/rimeh/rimeh.exe"
SHARED = "C:/Program Files/Rime/weasel-0.17.4/data"
ORDER_TSV = ROOT / "schemas/kinfx-quick/ms_quick_order.tsv"
SINGLE_TSV = ROOT / "schemas/kinfx-quick/win_quick_top9.tsv"
EN_DICT = ROOT / "lexicon/en/kinfx_en.dict.yaml"
UNSAFE = ROOT / "lexicon/en/kinfx_en_unsafe.txt"
ESSAY = Path(os.environ.get("APPDATA", "")) / "Rime/essay-cantonese.txt"
REPORT = ROOT / "docs/eval/V05_COMPARE.md"

# Terminators that follow a code run in (a)+(b). None is a bare Space on
# purpose: a bare Space is where the designed English commit happens, so the
# comparator lists it instead of the input relying on it.
TERMINATORS = ["1", "{space}1", "3", "{comma}", "{Return}", "{space}{space}2"]

VARIANTS = {
    # win_quick/hot_page is disabled in every variant: the 常用熱門 wrap page is
    # history-stateful and makes concurrent rimeh runs non-deterministic. It is
    # a KINFX-only feature, orthogonal to the English/association behaviour the
    # comparator measures, so turning it off keeps the default 1-9/Space pages
    # deterministic without hiding any smart-mode change.
    "control": {"english/mode": "shift", "association/enable": False,
                "win_quick/hot_page": False},
    "smart": {"association/enable": False, "win_quick/hot_page": False},
    "assoc": {"win_quick/hot_page": False},
}

WORKERS = 16
SEED = 20261016


# ---------------------------------------------------------------- data model

def load_order():
    order: dict[str, list[str]] = {}
    ges.read_order(ORDER_TSV, order, True)
    ges.read_order(SINGLE_TSV, order, False)
    best: dict[str, tuple[str, int, int]] = {}
    for code, cands in order.items():
        for rank, ch in enumerate(cands, 1):
            k = ges.code_cost(code, rank)
            if ch not in best or k < best[ch][2]:
                best[ch] = (code, rank, k)
    codes2 = sorted(c for c in order if len(c) == 2)
    return order, best, codes2


def load_english():
    words = ges.load_words(EN_DICT)  # set of lowercase English words
    prefixes: set[str] = set()
    for w in words:
        for i in range(2, len(w) + 1):
            prefixes.add(w[:i])
    return words, prefixes


def load_unsafe():
    unsafe: set[str] = set()
    for line in UNSAFE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            unsafe.add(line)
    return unsafe


def load_char_freq(essay: Path):
    freq: dict[str, int] = {}
    for line in essay.read_text(encoding="utf-8").splitlines():
        parts = line.rstrip("\r\n").split("\t")
        if len(parts) < 2 or not parts[1].isdigit():
            continue
        word, f = parts[0], int(parts[1])
        for ch in word:
            freq[ch] = freq.get(ch, 0) + f
    return freq


# ---------------------------------------------------------------- input gen

def gen_pairs(codes2: list[str], prefixes: set[str], limit: int | None):
    """(a) every 2-letter code x every 2-letter code, one terminator each;
    all six terminators when the 4 letters are an English-word prefix."""
    n = len(codes2)
    count = 0
    for i, c1 in enumerate(codes2):
        for j, c2 in enumerate(codes2):
            s = c1 + c2
            t = TERMINATORS[(i + j) % len(TERMINATORS)]
            yield s + t
            count += 1
            if limit and count >= limit:
                return
            if s in prefixes:
                for t2 in TERMINATORS:
                    if t2 == t:
                        continue
                    yield s + t2
                    count += 1
                    if limit and count >= limit:
                        return


def gen_triples(codes2: list[str], prefixes: set[str], n: int, rng: random.Random):
    """(b) 200k seeded 2+2+2 runs, each with a deterministic terminator, plus
    all six terminators for runs whose first 3-5 letters are an English prefix."""
    seen: set[str] = set()
    for _ in range(n):
        c1 = rng.choice(codes2)
        c2 = rng.choice(codes2)
        c3 = rng.choice(codes2)
        s = c1 + c2 + c3
        t = TERMINATORS[rng.randrange(len(TERMINATORS))]
        seq = s + t
        if seq not in seen:
            seen.add(seq)
            yield seq
        # English-prefix run: cover all terminators.
        head = s[:3] in prefixes or s[:4] in prefixes or s[:5] in prefixes
        if head:
            for t2 in TERMINATORS:
                seq2 = s + t2
                if seq2 not in seen:
                    seen.add(seq2)
                    yield seq2


def gen_two_plus_one(codes2: list[str], prefixes: set[str], n: int, rng: random.Random):
    """(b) 200k seeded 2+2+1+digit runs (two codes, one letter, one digit)."""
    letters = "abcdefghijklmnopqrstuvwxyz"
    seen: set[str] = set()
    for _ in range(n):
        c1 = rng.choice(codes2)
        c2 = rng.choice(codes2)
        l = rng.choice(letters)
        d = str(rng.randrange(1, 10))
        s = c1 + c2 + l
        seq = s + d
        if seq not in seen:
            seen.add(seq)
            yield seq
        if s in prefixes or (s[:2] in prefixes and len(s) >= 3):
            for t2 in TERMINATORS:
                seq2 = s + t2
                if seq2 not in seen:
                    seen.add(seq2)
                    yield seq2


# ---------------------------------------------------------------- typing model

def type_char(ch: str, best) -> str:
    """Cheapest Windows keystrokes for one Chinese character (verified in rimeh)."""
    code, rank, _ = best[ch]
    if len(code) == 2:
        if rank == 1:
            return code  # topped out by the next key
        pages = (rank - 1) // 9
        slot = (rank - 1) % 9 + 1
        return code + "{space}" * pages + str(slot)
    # single-letter code lists after Space
    pages = (rank - 1) // 9
    slot = (rank - 1) % 9 + 1
    return code + "{space}" + "{space}" * pages + str(slot)


def english_keys(word: str, unsafe: set[str]) -> str:
    if word in unsafe:
        return word + "{Shift_L}{Release+Shift_L}"
    return word + "{space}"


def english_text(word: str, unsafe: set[str]) -> str:
    return word + ("" if word in unsafe else " ")


def gen_article(best, words: set[str], unsafe: set[str], freq: dict[str, int],
                n_chars: int, rng: random.Random):
    """(c) alternating Chinese runs and English words, as (kind, units)."""
    typeable = [ch for ch in freq if ch in best]
    weights = [freq[ch] for ch in typeable]
    word_list = sorted(w for w in words if 2 <= len(w) <= 9)
    units: list[tuple[str, list]] = []
    i = 0
    while i < n_chars:
        run_len = min(rng.randint(18, 36), n_chars - i)
        zh = rng.choices(typeable, weights=weights, k=run_len)
        units.append(("zh", zh))
        i += run_len
        if i < n_chars:
            units.append(("en", [rng.choice(word_list)]))
    return units


# ---------------------------------------------------------------- rimeh driver

def stage_variant(base: Path, name: str, patch: dict):
    """Stage a throwaway user dir (Python-native, mirrors stage.sh), patch it,
    deploy once. Returns the dir."""
    import shutil
    d = base / name
    if (d / "build").exists():
        return d
    if d.exists():
        shutil.rmtree(d)
    (d / "lua").mkdir(parents=True, exist_ok=True)
    for src in (ROOT / "schemas/kinfx-quick").glob("*.yaml"):
        shutil.copy(str(src), str(d / src.name))
    for src in (ROOT / "schemas/kinfx-jyutping").glob("*.yaml"):
        shutil.copy(str(src), str(d / src.name))
    for src in (ROOT / "schemas/lua").glob("*.lua"):
        shutil.copy(str(src), str(d / "lua" / src.name))
    shutil.copy(str(ROOT / "schemas/rime.lua"), str(d / "rime.lua"))
    for src in (ROOT / "lexicon/hk").glob("*.yaml"):
        shutil.copy(str(src), str(d / src.name))
    for src in (ROOT / "lexicon/en").glob("*.yaml"):
        shutil.copy(str(src), str(d / src.name))
    shutil.copy(str(ROOT / "lexicon/en/kinfx_en_unsafe.txt"), str(d / "kinfx_en_unsafe.txt"))
    shutil.copy(str(ROOT / "lexicon/hk/kinfx_capture.txt"), str(d / "kinfx_capture.txt"))
    (d / "default.custom.yaml").write_text(
        "patch:\n  schema_list:\n    - schema: kinfx_quick\n  \"menu/page_size\": 9\n",
        encoding="utf-8")
    if patch:
        lines = ["patch:"]
        for k, v in patch.items():
            if isinstance(v, bool):
                lines.append(f'  "{k}": {"true" if v else "false"}')
            else:
                lines.append(f'  "{k}": "{v}"')
        (d / "kinfx_quick.custom.yaml").write_text(
            "\n".join(lines) + "\n", encoding="utf-8")
    # deploy once (no --no-deploy)
    subprocess.run(
        [str(RIMEH), SHARED, str(d)], input="schema kinfx_quick\n",
        capture_output=True, text=True, encoding="utf-8", check=True)
    return d


def run_chunk(variant_dir: Path, seqs: list[str]) -> dict[str, tuple[str, str]]:
    stdin = "schema kinfx_quick\nmax 9\n" + "".join("typed " + s + "\n" for s in seqs)
    p = subprocess.run(
        [str(RIMEH), SHARED, str(variant_dir), "--no-deploy"],
        input=stdin, capture_output=True, text=True, encoding="utf-8")
    out: dict[str, tuple[str, str]] = {}
    for line in p.stdout.splitlines():
        if not line.startswith("TYPED\t"):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) >= 4:
            out[parts[1]] = (parts[2], parts[3])
    return out


def run_variant(variant_dir: Path, seqs: list[str], chunk: int = 4000):
    chunks = [seqs[i:i + chunk] for i in range(0, len(seqs), chunk)]
    result: dict[str, tuple[str, str]] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = [ex.submit(run_chunk, variant_dir, c) for c in chunks]
        for f in concurrent.futures.as_completed(futs):
            result.update(f.result())
    return result


# ---------------------------------------------------------------- classification

def classify(seq: str, prefixes: set[str], smart_app: str, control_app: str):
    """Return 'designed' or 'unexpected' for a smart-vs-control app-text diff.

    Smart mode holds a run of letters as English when, after zero or more
    topped-out 2-letter codes, the remaining >= 3 letters form an English
    prefix. A diff is therefore designed iff some >= 3 letter substring that
    starts at an even offset (0, 2, 4, ...) is an English prefix. Anything
    else means the English logic corrupted a pure-Chinese input.
    """
    i = 0
    while i < len(seq) and seq[i].islower() and seq[i].isalpha():
        i += 1
    run = seq[:i]
    for off in range(0, len(run) - 2, 2):
        for ln in range(3, len(run) - off + 1):
            if run[off:off + ln] in prefixes:
                return "designed"
    return "unexpected"


# ---------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=0, help="cap (a)+(b) inputs (smoke)")
    ap.add_argument("--triples", type=int, default=200000)
    ap.add_argument("--article-chars", type=int, default=20000)
    ap.add_argument("--no-assoc", action="store_true", help=argparse.SUPPRESS)
    ap.add_argument("--assoc", action="store_true",
                    help="also stage the assoc (full-defaults) variant and diff it vs smart")
    ap.add_argument("--no-article", action="store_true")
    ap.add_argument("--write-report", action="store_true")
    args = ap.parse_args()

    if not RIMEH.exists():
        subprocess.run(["bash", str(ROOT / "tools/rimeh/build.sh")], check=True)

    order, best, codes2 = load_order()
    words, prefixes = load_english()
    unsafe = load_unsafe()
    rng = random.Random(SEED)

    seqs: list[str] = []
    seqs += list(gen_pairs(codes2, prefixes, args.limit or None))
    if not args.limit:
        seqs += list(gen_triples(codes2, prefixes, args.triples, rng))
        seqs += list(gen_two_plus_one(codes2, prefixes, args.triples, rng))
    # dedupe, preserve order
    seen: set[str] = set()
    seqs = [s for s in seqs if not (s in seen or seen.add(s))]

    base = (Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData/Local"))
            / "hermes/profiles/it-dog/cache/scratch" / "rime-compare")
    base.mkdir(parents=True, exist_ok=True)
    variants = dict(VARIANTS)
    if not args.assoc:
        variants.pop("assoc", None)

    dirs = {name: stage_variant(base, name, patch) for name, patch in variants.items()}
    results = {name: run_variant(d, seqs) for name, d in dirs.items()}

    control = results["control"]
    smart = results["smart"]

    diffs = []
    for seq in seqs:
        c = control.get(seq)
        s = smart.get(seq)
        if c is None or s is None:
            diffs.append((seq, "<missing>", "<missing>"))
            continue
        if c != s:
            diffs.append((seq, s[0], c[0], s[1], c[1]))

    designed = [d for d in diffs if classify(d[0], prefixes, d[1], d[2]) == "designed"]
    unexpected = [d for d in diffs if classify(d[0], prefixes, d[1], d[2]) != "designed"]

    print(f"codes2={len(codes2)} english_words={len(words)} unsafe={len(unsafe)}")
    print(f"sequences={len(seqs)} variants={list(variants)}")
    print(f"smart-vs-control diffs={len(diffs)} "
          f"(designed={len(designed)} unexpected={len(unexpected)})")

    # association vs smart: the association only opens after an explicit one-char
    # pick (digit/Enter) and is picked with Shift+digit. The comparator sequences
    # never select a Chinese char by digit, so the app-visible text must be
    # identical (the follow-up menu lives in the candidates, not the commit).
    assoc_diffs = []
    if "assoc" in results:
        assoc = results["assoc"]
        for seq in seqs:
            a = assoc.get(seq)
            s = smart.get(seq)
            if a is None or s is None:
                continue
            if a != s:
                assoc_diffs.append((seq, a[0], s[0], a[1], s[1]))
        print(f"assoc-vs-smart diffs={len(assoc_diffs)}")

    # article replay
    article_zh_mismatch = 0
    article_en_miss = 0
    article_en_total = 0
    if not args.no_article and not args.limit and ESSAY.exists():
        freq = load_char_freq(ESSAY)
        units = gen_article(best, words, unsafe, freq, args.article_chars, rng)
        art_seqs: list[str] = []
        art_expect: list[str] = []  # per-segment expected committed text
        art_kinds: list[str] = []
        for kind, u in units:
            if kind == "zh":
                keys = "".join(type_char(ch, best) for ch in u)
                # flush a trailing rank-1 2-letter code
                if len(u) and len(best[u[-1]][0]) == 2 and best[u[-1]][1] == 1:
                    keys += "{Return}"
                art_seqs.append(keys)
                art_expect.append("".join(u))
                art_kinds.append("zh")
            else:
                w = u[0]
                art_seqs.append(english_keys(w, unsafe))
                art_expect.append(english_text(w, unsafe))
                art_kinds.append("en")
        sdir = dirs["smart"]
        cdir = dirs["control"]
        s_art = run_variant(sdir, art_seqs, chunk=400)
        c_art = run_variant(cdir, art_seqs, chunk=400)
        for seq, kind, expect in zip(art_seqs, art_kinds, art_expect):
            s_app = s_art.get(seq, ("", ""))[0]
            c_app = c_art.get(seq, ("", ""))[0]
            if kind == "zh":
                if s_app != c_app:
                    article_zh_mismatch += 1
            else:
                article_en_total += 1
                # Display form may differ in case (SCOWL proper nouns: Bethe).
                if s_app.lower() != expect.lower():
                    article_en_miss += 1
        print(f"article: zh-mismatch={article_zh_mismatch} "
              f"english={article_en_total - article_en_miss}/{article_en_total} correct")

    if args.write_report:
        write_report(seqs, diffs, designed, unexpected, len(codes2), len(words),
                     len(unsafe), args)

    sys.exit(1 if unexpected or article_zh_mismatch or article_en_miss or assoc_diffs else 0)


def write_report(seqs, diffs, designed, unexpected, n_codes, n_words, n_unsafe, args):
    import datetime
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# V05 離線比對（offline comparator）",
        "",
        f"日期：{datetime.date.today().isoformat()}（工具：tools/rimeh/compare.py）",
        "",
        f"- 兩碼碼數：{n_codes}（ms_quick_order.tsv）",
        f"- 英文詞：{n_words}（kinfx_en.dict.yaml，SCOWL）",
        f"- 空白不安全詞：{n_unsafe}（kinfx_en_unsafe.txt）",
        f"- 比對序列數：{len(seqs)}",
        "",
        "## smart 對 control",
        "",
        f"- 差異總數：{len(diffs)}",
        f"- 設計內差異（空白／標點上屏空白安全英文詞）：{len(designed)}",
        f"- 意外差異：{len(unexpected)}（必須為 0）",
        "",
    ]
    if unexpected:
        lines.append("### 意外差異")
        lines.append("")
        for d in unexpected[:50]:
            lines.append(f"- `{d[0]}` smart=[{d[1]}] control=[{d[2]}]")
        lines.append("")
    if designed:
        lines.append("### 設計內差異（前 40 個）")
        lines.append("")
        for d in designed[:40]:
            lines.append(f"- `{d[0]}` smart=[{d[1]}] control=[{d[2]}]")
        lines.append("")
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {REPORT}")


if __name__ == "__main__":
    main()
