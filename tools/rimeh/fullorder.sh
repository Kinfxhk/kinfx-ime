#!/usr/bin/env bash
# Compare every captured Windows code against KINFX through rimeh (full list,
# all pages). Usage: tools/rimeh/fullorder.sh  → prints mismatching codes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
U="${RIMEH_TMP:-$LOCALAPPDATA/hermes/profiles/it-dog/cache/scratch}/rime-full"
SHARED="${RIMEH_SHARED:-C:/Program Files/Rime/weasel-0.17.4/data}"
[ -x "$ROOT/tools/rimeh/rimeh.exe" ] || bash "$ROOT/tools/rimeh/build.sh" >/dev/null
bash "$ROOT/tools/rimeh/stage.sh" "$U" >/dev/null
TSV="$ROOT/schemas/kinfx-quick/ms_quick_order.tsv"
{ echo "schema kinfx_quick"; echo "max 400"
  awk -F'\t' '!/^#/ && length($1)==2 {print "keys " $1}' "$TSV"; } > "$U/cmds.txt"
"$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" < "$U/cmds.txt" 2>/dev/null | tr -d '\r' > "$U/out.txt"
python - "$(cygpath -m "$TSV")" "$(cygpath -m "$U/out.txt")" <<'PY'
import sys
want = {}
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("#") or "\t" not in line:
        continue
    code, chars = line.rstrip("\n").split("\t", 1)
    if len(code) == 2:
        want[code] = chars.split(" ")
got = {}
for line in open(sys.argv[2], encoding="utf-8"):
    p = line.rstrip("\n").split("\t")
    if len(p) >= 5 and p[0] == "OK":
        got[p[1]] = [c.split("~")[0] for c in p[4].split("|") if c]
bad = []
for code, w in want.items():
    g = got.get(code, [])
    if g[: len(w)] != w:
        i = next((k for k in range(len(w)) if k >= len(g) or g[k] != w[k]), None)
        bad.append((code, i, w[i] if i is not None and i < len(w) else "", g[i] if i is not None and i < len(g) else "∅"))
print(f"codes {len(want)}  exact-prefix match {len(want) - len(bad)}  mismatch {len(bad)}")
for code, i, w, g in bad[:30]:
    print(f"  {code} slot {i + 1}: want {w} got {g}")
sys.exit(1 if bad else 0)
PY
