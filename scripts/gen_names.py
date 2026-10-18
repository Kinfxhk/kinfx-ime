#!/usr/bin/env python3
"""Build lexicon/en/kinfx_names.dict.yaml: brand / product / website names.

v0.5.4. Names SCOWL lacks (AdSense, GoDaddy, Zendesk) broke into Chinese at the
first letter that no English word continues (adsense -> 杲sense). This table is
compiled natively (kinfx_names.schema.yaml, dependency-only) so a few thousand
names cost nothing on the Lua heap; english_mix.lua uses it for the prefix hold
and for the display form (adsense -> AdSense).

Source: Wikidata English labels / aliases (CC0) of items that are an instance
of software, websites, online services, companies, brands, programming
languages, apps ... with at least --min-sitelinks Wikipedia sitelinks.

  python scripts/gen_names.py --fetch            # query Wikidata, then build
  python scripts/gen_names.py --source wd.tsv    # build from a saved extract

Kept: 4-16 ASCII letters; not a lowercase SCOWL word (the word wins anyway);
not already in kinfx_en_names.txt (hand list wins); not on the blocklist below.
Space safety is not decided here: scripts/gen_english_space.py --names rates
these codes like SCOWL words and lists the risky ones in kinfx_en_unsafe.txt.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.5.4"

# Wikidata classes (instance of / subclass of). Kept broad; the sitelink floor
# keeps the list to names people actually write.
CLASSES = [
    "Q7397", "Q19967801", "Q35127", "Q4830453", "Q891723", "Q1058914", "Q166142",
    "Q9135", "Q620615", "Q341", "Q1639024", "Q431289", "Q1668024", "Q3220391",
    "Q20202269", "Q483639", "Q131093", "Q176165", "Q484847", "Q2462003",
    "Q3800506", "Q18922759", "Q3390477", "Q986008", "Q9143", "Q4182287", "Q19541",
    "Q63241860", "Q18388277", "Q1137109", "Q189210", "Q6368", "Q5892272",
    "Q193424", "Q271680",
]
# Adult sites and slurs are not typing targets for a general IME.
BLOCK = {"xvideos", "xhamster", "brazzers", "chaturbate", "pornhub", "xnxx",
         "youporn", "redtube", "incel", "incels", "incelibate", "onlyfans",
         "stripchat", "bongacams", "livejasmin"}
NAME_RE = re.compile(r"^[A-Za-z]{4,16}$")


def fetch(min_sitelinks: int) -> dict[str, int]:
    out: dict[str, int] = {}
    for q in CLASSES:
        sparql = (
            "SELECT ?l (MAX(?sl) AS ?n) WHERE { "
            f"?i wdt:P31/wdt:P279? wd:{q}; wikibase:sitelinks ?sl. FILTER(?sl >= {min_sitelinks}) "
            "?i skos:altLabel|rdfs:label ?l. FILTER(LANG(?l)=\"en\") "
            "FILTER(REGEX(?l, \"^[A-Za-z][A-Za-z0-9]{3,15}$\")) } GROUP BY ?l LIMIT 30000"
        )
        url = "https://query.wikidata.org/sparql?format=json&query=" + urllib.parse.quote(sparql)
        req = urllib.request.Request(url, headers={"User-Agent": "kinfx-ime/0.5.4 (github.com/Kinfxhk/kinfx-ime)"})
        for attempt in range(3):
            try:
                rows = json.load(urllib.request.urlopen(req, timeout=180))["results"]["bindings"]
                for r in rows:
                    label, n = r["l"]["value"], int(r["n"]["value"])
                    out[label] = max(out.get(label, 0), n)
                print(f"{q}: {len(rows)}", file=sys.stderr)
                break
            except Exception as e:  # network / 429: retry, then give up loudly
                print(f"{q}: {e}", file=sys.stderr)
                time.sleep(10 * (attempt + 1))
        else:
            raise SystemExit(f"Wikidata query failed for {q}")
    return out


def read_source(path: Path) -> dict[str, int]:
    out: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.rstrip("\r\n").split("\t")
        if len(parts) >= 2 and parts[1].isdigit():
            out[parts[0]] = max(out.get(parts[0], 0), int(parts[1]))
    return out


def scowl_lower(en_dict: Path) -> set[str]:
    words, body = set(), False
    for line in en_dict.read_text(encoding="utf-8").splitlines():
        if line.startswith("..."):
            body = True
            continue
        parts = line.rstrip("\r\n").split("\t")
        if body and len(parts) >= 2 and parts[0] == parts[1]:
            words.add(parts[1])
    return words


def hand_codes(names_txt: Path) -> set[str]:
    out = set()
    for line in names_txt.read_text(encoding="utf-8").splitlines():
        line = line.rstrip("\r\n")
        if line and not line.startswith("#"):
            out.add(line.split("\t")[-1].strip())
    return out


def rank(label: str, n: int):
    """More sitelinks first; then mixed case over ALL CAPS, then more capitals
    (MediaWiki over Mediawiki, AdSense over Adsense), then a stable order."""
    caps = sum(ch.isupper() for ch in label)
    return (n, not label.isupper(), caps, label.swapcase())


def build(labels: dict[str, int], skip: set[str]) -> list[tuple[str, str, int]]:
    """One row per code: the most linked label; mixed case beats ALL CAPS."""
    best: dict[str, tuple[str, int]] = {}
    for label, n in labels.items():
        if not NAME_RE.match(label):
            continue
        code = label.lower()
        if code in skip or code in BLOCK:
            continue
        cur = best.get(code)
        if cur is None or rank(label, n) > rank(*cur):
            best[code] = (label, n)
    return sorted(((t, c, n) for c, (t, n) in best.items()), key=lambda r: (-r[2], r[1]))


def write_dict(rows, out: Path, n_labels: int, min_sitelinks: int) -> None:
    head = [
        "# encoding: utf-8",
        "# Generated by scripts/gen_names.py — do not hand-edit.",
        "# Brand / product / website names for English typing (v0.5.4).",
        f"# Source: Wikidata English labels and aliases (CC0), >= {min_sitelinks} sitelinks;",
        f"# {n_labels} labels read, {len(rows)} codes kept. Names are trademarks of their",
        "# owners, listed only as typing targets. See lexicon/NOTICE.",
        "",
        "---",
        "name: kinfx_names",
        f'version: "{VERSION}"',
        "sort: by_weight",
        "use_preset_vocabulary: false",
        "columns:",
        "  - text",
        "  - code",
        "  - weight",
        "...",
        "",
    ]
    body = [f"{t}\t{c}\t{n}" for t, c, n in rows]
    out.write_text("\n".join(head + body) + "\n", encoding="utf-8", newline="\n")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--fetch", action="store_true", help="query Wikidata (needs network)")
    ap.add_argument("--source", type=Path, help="label<TAB>sitelinks extract (from --save)")
    ap.add_argument("--save", type=Path, help="write the fetched extract here")
    ap.add_argument("--min-sitelinks", type=int, default=12)
    ap.add_argument("--en-dict", type=Path, default=ROOT / "lexicon/en/kinfx_en.dict.yaml")
    ap.add_argument("--names", type=Path, default=ROOT / "lexicon/en/kinfx_en_names.txt")
    ap.add_argument("--out", type=Path, default=ROOT / "lexicon/en/kinfx_names.dict.yaml")
    args = ap.parse_args()
    if args.fetch:
        labels = fetch(args.min_sitelinks)
        if args.save:
            args.save.write_text("".join(f"{k}\t{v}\n" for k, v in sorted(labels.items(), key=lambda x: -x[1])),
                                 encoding="utf-8", newline="\n")
    elif args.source:
        labels = {k: v for k, v in read_source(args.source).items() if v >= args.min_sitelinks}
    else:
        raise SystemExit("--fetch or --source is required")
    rows = build(labels, scowl_lower(args.en_dict) | hand_codes(args.names))
    write_dict(rows, args.out, len(labels), args.min_sitelinks)
    print(f"wrote {args.out}: {len(rows)} names")


if __name__ == "__main__":
    main()
