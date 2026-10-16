#!/usr/bin/env bash
# Flex switches: capture none / english off / phrase off. Offline, via rimeh.
# Usage: tools/rimeh/flex.sh  (exit 0 when all pass)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BASE="${RIMEH_TMP:-$LOCALAPPDATA/hermes/profiles/it-dog/cache/scratch}/rime-flex"
SHARED="${RIMEH_SHARED:-C:/Program Files/Rime/weasel-0.17.4/data}"
[ -x "$ROOT/tools/rimeh/rimeh.exe" ] || bash "$ROOT/tools/rimeh/build.sh" >/dev/null
pass=0; fail=0
check() { # variant patch keys want
  local name="$1" patch="$2" keys="$3" want="$4"
  local U="$BASE/$name"
  if [ ! -d "$U/build" ]; then
    bash "$ROOT/tools/rimeh/stage.sh" "$U" >/dev/null
    printf 'patch:\n%s\n' "$patch" > "$U/kinfx_quick.custom.yaml"
    printf 'schema kinfx_quick\n' | "$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" >/dev/null 2>&1
  fi
  local got
  got=$(printf 'schema kinfx_quick\nkeys %s\n' "$keys" | "$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" --no-deploy 2>/dev/null | tr -d '\r' | awk -F'\t' '$1=="OK"{print $3}')
  if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "OK   [$name] $keys → $got"
  else fail=$((fail+1)); echo "FAIL [$name] $keys → got [$got] want [$want]"; fi
}
rm -rf "$BASE"
NONE='  "phrase_mix/capture": none'
NOEN='  "english/enable": false'
NOPH='  "phrase_mix/enable": false'
check none "$NONE" "ofc1" "伙金"        # pure Windows top-out: of → 伙, then c 1
check none "$NONE" "gmai1" "Gmail"      # English holds still work
check noen "$NOEN" "gmai1" "址昤"        # gm a i: Windows top-out
check noen "$NOEN" "ofc1" "人類"         # Chinese phrases unaffected
check noph "$NOPH" "ofc1" "伙金"
check noph "$NOPH" "gmai1" "Gmail"
check noen "$NOEN" "gma1" "址日"        # English off: gm+a tops out (no Chinese gate on gma)
echo "PASS $pass/$((pass+fail))"
[ "$fail" -eq 0 ]
