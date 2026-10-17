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
import re
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
NAMES_DICT = ROOT / "lexicon/en/kinfx_names.dict.yaml"  # v0.5.4 brand names
HAND_NAMES = ROOT / "lexicon/en/kinfx_en_names.txt"  # v0.5.2 hand list (Acer, OpenAI)
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
    if NAMES_DICT.exists():
        words = sorted(set(words) | set(ges.load_words(NAMES_DICT)))
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


def load_hot():
    """3+ letter Chinese phrase prefixes (kinfx_capture.txt, non-+word lines).

    A word whose 3+ letter prefix at an even offset is hot is held as a Chinese
    phrase (hold_kind returns 'zh' before 'en'), so it cannot be typed as
    English; the article model must not pick it.
    """
    hot: set[str] = set()
    p = ROOT / "lexicon/hk/kinfx_capture.txt"
    if p.exists():
        for line in p.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("+"):
                continue
            if len(line) >= 3 and line.isalpha() and line.islower():
                hot.add(line)
    return hot


def load_phrase_prefixes():
    """5+ letter prefixes of the compiled phrase tables (from key 5 any phrase
    prefix holds Chinese, so an English word colliding with one is not typeable)."""
    prefixes: set[str] = set()
    for name in ("kinfx_hk_words.dict.yaml", "kinfx_hk_idioms.dict.yaml"):
        p = ROOT / "lexicon/hk" / name
        if not p.exists():
            continue
        in_body = False
        for line in p.read_text(encoding="utf-8").splitlines():
            if line.rstrip("\r\n") == "...":
                in_body = True
                continue
            if not in_body or not line or line.startswith("#"):
                continue
            parts = line.rstrip("\r\n").split("\t")
            if len(parts) >= 2 and parts[1].isalpha():
                code = parts[1].lower()
                for i in range(5, len(code) + 1):
                    prefixes.add(code[:i])
    return prefixes


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


def load_hold_words() -> list[str]:
    """+word lines of kinfx_capture.txt (Gmail, scriptwriting, voiceover)."""
    out = []
    for line in (ROOT / "lexicon/hk/kinfx_capture.txt").read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\+([a-z]+)", line)
        if m:
            out.append(m.group(1))
    return out


def hand_names() -> dict[str, str]:
    """code -> display of kinfx_en_names.txt (Display<TAB>code or a bare code)."""
    out: dict[str, str] = {}
    for line in HAND_NAMES.read_text(encoding="utf-8").splitlines():
        line = line.rstrip("\r\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        code = parts[-1].strip()
        if re.fullmatch(r"[a-z][a-z0-9]*", code):
            out[code] = parts[0] if len(parts) > 1 else code
    return out


def space_words(unsafe: set[str]) -> set[str]:
    """Words Space commits (mirrors english_mix.lua space_text): 3+ letters,
    not unsafe, and a lowercase entry exists or the word is a +hold extra."""
    texts = en_texts()
    extras = set(load_hold_words())
    names = set(ges.load_words(NAMES_DICT)) if NAMES_DICT.exists() else set()
    names |= set(hand_names())
    return {w for w, ts in texts.items()
            if len(w) >= 3 and w not in unsafe and (w in ts or w in extras or w in names)}


def english_keys(word: str, space_ok: set[str]) -> str:
    if word not in space_ok:
        return word + "{Shift_L}{Release+Shift_L}"
    return word + "{space}"


def english_text(word: str, space_ok: set[str]) -> str:
    return word + (" " if word in space_ok else "")


def gen_article(best, words: set[str], unsafe: set[str], freq: dict[str, int],
                n_chars: int, rng: random.Random):
    """(c) alternating Chinese runs and English words, as (kind, units)."""
    typeable = [ch for ch in freq if ch in best]
    weights = [freq[ch] for ch in typeable]
    # Only words every complete pair of which is a real Sucheng code can be held
    # as English (all_pairs_valid); a word with an invalid pair (sz/tz/xz/zz)
    # cannot be typed as English, so the article model must not pick it.
    codes2 = {code for code, _, _ in best.values() if len(code) == 2}
    hot = load_hot()
    phrase_pfx = load_phrase_prefixes()

    def typeable_en(w: str) -> bool:
        # every complete pair a real code, no 3+ letter prefix at an even offset
        # is a hot Chinese phrase, and no 5+ letter prefix is a phrase prefix
        # (from key 5 any phrase in the compiled table holds it Chinese).
        if not all(w[i:i + 2] in codes2 for i in range(0, len(w) - 1, 2)):
            return False
        for off in range(0, len(w) - 2, 2):
            for ln in range(3, len(w) - off + 1):
                if w[off:off + ln] in hot:
                    return False
        for ln in range(5, len(w) + 1):
            if w[:ln] in phrase_pfx:
                return False
        return True

    word_list = sorted(w for w in words if 2 <= len(w) <= 9 and typeable_en(w))
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
    shutil.copy(str(ROOT / "lexicon/en/kinfx_en_names.txt"), str(d / "kinfx_en_names.txt"))
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


HINT_RE = re.compile(r" (‹[^›]*›)?[␣⇧][A-Za-z]+$")


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
            # smart mode shows a hint after the caret; it is not text.
            pre = HINT_RE.sub("", parts[3])
            out[parts[1]] = (parts[2], pre)
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

def seq_has_en_prefix(seq: str, prefixes: set[str]) -> bool:
    """True if any 3+ letter run at an even offset in the sequence (letters
    separated by digits/{space}/... are distinct runs) is an English prefix —
    i.e. smart mode would hold it and delay top-out."""
    for run in re.findall(r"[a-z]+", seq):
        for off in range(0, len(run) - 2, 2):
            for ln in range(3, len(run) - off + 1):
                if run[off:off + ln] in prefixes:
                    return True
    return False


TOKEN_TEXT = {"{space}": " ", "{comma}": "，", "{period}": "。"}


def tail_text(rest: str) -> str | None:
    """App text the keys after the English word produce once the composition is
    empty (digits and Space pass through; comma/period become full-width)."""
    out = []
    for tok in re.findall(r"\{[^}]+\}|.", rest):
        if tok in TOKEN_TEXT:
            out.append(TOKEN_TEXT[tok])
        elif tok.isdigit():
            out.append(tok)
        elif tok == "{Return}":
            continue
        else:
            return None
    return "".join(out)


def classify(seq: str, smart_app: str, control_app: str, ctx) -> str:
    """Strict: 'designed' only for the one change v0.5 is meant to make.

    The leading letters split at an even offset k into topped-out pairs
    letters[:k] and an English word w = letters[k:] (>= 3 letters) that Space
    may commit; the next key is Space or comma/period; control did NOT hold w as
    a Chinese phrase; and smart typed exactly
        Windows(letters[:k]) + text(w) + (" " for Space) + passthrough(rest).
    Everything else is unexpected. The classifier is never widened to pass.
    """
    m = re.match(r"[a-z]+", seq)
    if not m:
        return "unexpected"
    letters, rest = m.group(0), seq[m.end():]
    if not (rest.startswith("{space}") or rest.startswith("{comma}") or rest.startswith("{period}")):
        return "unexpected"
    for k in range(0, len(letters) - 2, 2):
        w = letters[k:]
        if w not in ctx["space_ok"]:
            continue
        if ctx["control_held"].get(letters):
            continue
        pre = ""
        ok = True
        for i in range(0, k, 2):
            t = ctx["top1"].get(letters[i:i + 2])
            if t is None:
                ok = False
                break
            pre += t
        if not ok:
            continue
        sep = " " if rest.startswith("{space}") else ""
        after = rest[len("{space}"):] if sep else rest
        tail = tail_text(after)
        if tail is None:
            continue
        for t in ctx["word_text"].get(w, {w}):
            if smart_app == pre + t + sep + tail:
                return "designed"
    return "unexpected"


def chinese_changed(control_app: str, smart_app: str) -> bool:
    """Smart dropped or replaced Chinese that control typed (beyond what an
    English word legitimately replaces): the Chinese of smart must be a prefix
    of control's Chinese."""
    cz = "".join(ch for ch in control_app if "\u3400" <= ch <= "\u9fff" or ord(ch) > 0x20000)
    sz = "".join(ch for ch in smart_app if "\u3400" <= ch <= "\u9fff" or ord(ch) > 0x20000)
    return not cz.startswith(sz)


def en_texts() -> dict[str, set[str]]:
    """code -> every display text kinfx_en has for it (Gmail, gmail, ...)."""
    out: dict[str, set[str]] = {}
    for path in (EN_DICT, NAMES_DICT):
        if not path.exists():
            continue
        body = False
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("..."):
                body = True
                continue
            if not body or not line or line.startswith("#"):
                continue
            parts = line.rstrip("\r\n").split("\t")
            if len(parts) >= 2:
                out.setdefault(parts[1], set()).add(parts[0])
    for code, text in hand_names().items():
        out.setdefault(code, set()).add(text)
    return out


def space_collision(seq, s_app, c_app, space_ok, texts) -> bool:
    """True when the only change is a Space-committed English word: some letter
    run immediately before a {space} ends in a space-safe word w (starting at a
    code boundary of that run), and smart's text equals control's text with the
    Chinese typed by those keys replaced by w + " " (checked by the common
    prefix/suffix of the two outputs)."""
    i = 0
    while i < min(len(s_app), len(c_app)) and s_app[i] == c_app[i]:
        i += 1
    j = 0
    while (j < min(len(s_app), len(c_app)) - i
           and s_app[len(s_app) - 1 - j] == c_app[len(c_app) - 1 - j]):
        j += 1
    s_mid = s_app[i:len(s_app) - j]
    for m in re.finditer(r"([a-z]+)\{space\}", seq):
        run = m.group(1)
        for k in range(0, len(run) - 2, 2):
            w = run[k:]
            if w in space_ok and any(t in s_mid for t in texts.get(w, {w})):
                return True
    return False


def build_ctx(order, unsafe, control_dir: Path, diffs):
    """Facts the strict classifier needs. control_held is measured in rimeh:
    the control variant still shows >= 3 raw letters after typing them."""
    texts = en_texts()
    top1 = {c: v[0] for c, v in order.items() if len(c) == 2 and v}
    space_ok = space_words(unsafe)
    letters = sorted({re.match(r"[a-z]*", d[0]).group(0) for d in diffs})
    letters = [x for x in letters if len(x) >= 3]
    held: dict[str, bool] = {}
    for i in range(0, len(letters), 4000):
        chunk = letters[i:i + 4000]
        res = run_chunk(control_dir, chunk)
        for x in chunk:
            pre = res.get(x, ("", ""))[1]
            m = re.search(r"[a-z]+$", pre)
            held[x] = bool(m and len(m.group(0)) >= 3)
    return {"top1": top1, "space_ok": space_ok, "word_text": texts, "control_held": held}


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

    ctx = build_ctx(order, unsafe, dirs["control"], diffs)
    designed = [d for d in diffs if classify(d[0], d[1], d[2], ctx) == "designed"]
    unexpected = [d for d in diffs if classify(d[0], d[1], d[2], ctx) != "designed"]
    zh_changed = [d for d in unexpected if chinese_changed(d[2], d[1])]

    print(f"codes2={len(codes2)} english_words={len(words)} unsafe={len(unsafe)}")
    print(f"sequences={len(seqs)} variants={list(variants)}")
    print(f"smart-vs-control diffs={len(diffs)} "
          f"(designed={len(designed)} unexpected={len(unexpected)} "
          f"chinese_changed={len(zh_changed)})")
    for d in unexpected[:30]:
        print(f"  UNEXPECTED {d[0]} smart=[{d[1]}] control=[{d[2]}]")

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
    article_space: list = []
    article_zh_designed = 0
    article_en_miss = 0
    article_en_total = 0
    article_chars = 0
    if not args.no_article and not args.limit and ESSAY.exists():
        freq = load_char_freq(ESSAY)
        units = gen_article(best, words, unsafe, freq, args.article_chars, rng)
        art_space = space_words(unsafe)
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
                art_seqs.append(english_keys(w, art_space))
                art_expect.append(english_text(w, art_space))
                art_kinds.append("en")
        en_text_map = en_texts()
        space_ok = art_space
        sdir = dirs["smart"]
        cdir = dirs["control"]
        s_art = run_variant(sdir, art_seqs, chunk=400)
        c_art = run_variant(cdir, art_seqs, chunk=400)
        for seq, kind, expect in zip(art_seqs, art_kinds, art_expect):
            s_app = s_art.get(seq, ("", ""))[0]
            c_app = c_art.get(seq, ("", ""))[0]
            if kind == "zh":
                # Strict: a Chinese run must type exactly what control types,
                # except the designed Space collision: the letters before a
                # Space spell a space-safe English word and smart typed exactly
                # that word where control typed Chinese. Each one is listed.
                if s_app != c_app:
                    if space_collision(seq, s_app, c_app, space_ok, en_text_map):
                        article_space.append((seq, s_app, c_app))
                    else:
                        article_zh_mismatch += 1
                        if article_zh_mismatch <= 20:
                            print(f"  ARTICLE-ZH {seq[:70]} smart=[{s_app}] control=[{c_app}]")
            else:
                article_en_total += 1
                # Display form may differ in case (SCOWL proper nouns: Bethe).
                if s_app.lower() != expect.lower():
                    article_en_miss += 1
                    if article_en_miss <= 20:
                        print(f"  ARTICLE-EN {seq} smart=[{s_app}] want=[{expect}]")
        zh_chars = sum(len(u) for k, u in units if k == "zh")
        article_chars = zh_chars
        print(f"article: zh-chars={zh_chars} space-collisions={len(article_space)} "
              f"({len(article_space) / max(1, zh_chars) * 1e4:.2f} per 10k chars)")
        for row in article_space:
            print(f"  SPACE {row[0][:70]} smart=[{row[1]}] control=[{row[2]}]")
        print(f"article: zh-mismatch={article_zh_mismatch} "
              f"zh-designed={article_zh_designed} "
              f"english={article_en_total - article_en_miss}/{article_en_total} correct")

    if args.write_report:
        write_report(seqs, diffs, designed, unexpected, zh_changed, len(codes2), len(words),
                     len(unsafe), args,
                     (article_zh_mismatch, article_en_total, article_en_miss, article_space,
                      article_chars),
                     assoc_diffs)

    sys.exit(1 if unexpected or zh_changed or article_zh_mismatch or article_en_miss
             or assoc_diffs else 0)


def write_report(seqs, diffs, designed, unexpected, zh_changed, n_codes, n_words, n_unsafe,
                 args, article, assoc_diffs):
    import datetime
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    zh_mis, en_total, en_miss, space_rows, zh_chars = article
    rate = len(designed) / max(1, len(seqs)) * 1e4
    lines = [
        "# v0.5 離線比對（tools/rimeh/compare.py）",
        "",
        f"日期：{datetime.date.today().isoformat()}。對照組 control＝`english/mode: shift`"
        "（v0.4.1 行為）；實驗組 smart＝預設值；兩組都關閉聯想同常用熱門頁。",
        "",
        f"- 兩碼碼數：{n_codes}；英文詞：{n_words}；空白不安全詞：{n_unsafe}",
        f"- 比對序列：{len(seqs)}（全部兩碼＋兩碼，加三段連打抽樣，每組帶結尾鍵）",
        "",
        "## smart 對 control（嚴格分類）",
        "",
        "「設計內」只限：前面已頂字嘅兩碼照 Windows 上屏，之後 3 個字母或以上嘅"
        "空白安全英文詞，遇空白或標點上屏成英文，而對照組冇用中文詞語留住呢串字母。",
        "",
        f"- 差異總數：{len(diffs)}",
        f"- 設計內：{len(designed)}（每 1 萬組序列 {rate:.2f} 組）",
        f"- 意外差異：{len(unexpected)}（必須為 0）",
        f"- 中文改變：{len(zh_changed)}（必須為 0）",
        "",
    ]
    if not args.no_article and not args.limit:
        lines += [
            "## 文章重打（smart）",
            "",
            f"- 中文字數：{zh_chars}；英文詞：{en_total}，正確 {en_total - en_miss}",
            f"- 空白規則撞中文（設計內，逐個列出）：{len(space_rows)}"
            f"（每 1 萬中文字 {len(space_rows) / max(1, zh_chars) * 1e4:.2f}；"
            "模型估計見 kinfx_en_unsafe.txt 檔頭）",
            f"- 其他中文改變：{zh_mis}（必須為 0）",
            "",
        ]
        lines += [f"  - `{r[0][:60]}…` smart=[{r[1]}] control=[{r[2]}]" for r in space_rows]
        if space_rows:
            lines.append("")
    if assoc_diffs is not None and args.assoc:
        lines += [f"- 聯想（assoc 對 smart）差異：{len(assoc_diffs)}", ""]
    for title, rows in (("意外差異", unexpected[:50]), ("設計內差異（前 40 個）", designed[:40])):
        if rows:
            lines += [f"### {title}", ""]
            lines += [f"- `{d[0]}` smart=[{d[1]}] control=[{d[2]}]" for d in rows]
            lines.append("")
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {REPORT}")


if __name__ == "__main__":
    main()
