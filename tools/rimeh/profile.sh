#!/usr/bin/env bash
# Per-component latency profile. Usage: tools/rimeh/profile.sh [variant ...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BASE="${RIMEH_TMP:-$LOCALAPPDATA/hermes/profiles/it-dog/cache/scratch}/rimeprof"
SHARED="${RIMEH_SHARED:-C:/Program Files/Rime/weasel-0.17.4/data}"
run() {
  local name="$1"; local patch="$2"
  local U="$BASE/$name"
  bash "$ROOT/tools/rimeh/stage.sh" "$U" >/dev/null
  printf 'patch:\n%s\n' "$patch" > "$U/kinfx_quick.custom.yaml"
  printf 'schema kinfx_quick\nbench vd 40\nbench vdvdvdvd 20\n' |
    timeout 300 "$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" 2>/dev/null |
    awk -v n="$name" -F'\t' '/^BENCH/{printf "%-22s %-10s %s\n", n, $2, $3}'
}
declare -A V=(
  [base]='  noop: 0'
  [no_reverse]='  "engine/translators": [punct_translator, table_translator, lua_translator@phrase_mix_tr, lua_translator@melt_eng_tr]'
  [no_phrase_tr]='  "engine/translators": [punct_translator, table_translator, lua_translator@melt_eng_tr, reverse_lookup_translator]'
  [no_melt_tr]='  "engine/translators": [punct_translator, table_translator, lua_translator@phrase_mix_tr, reverse_lookup_translator]'
  [only_table]='  "engine/translators": [punct_translator, table_translator]'
  [no_lua_filter]='  "engine/filters": [simplifier, uniquifier]'
  [no_simplifier]='  "engine/filters": [uniquifier, lua_filter@win_quick_menu]'
)
names=("$@"); [ ${#names[@]} -eq 0 ] && names=(base no_reverse no_phrase_tr no_melt_tr only_table no_lua_filter no_simplifier)
for n in "${names[@]}"; do run "$n" "${V[$n]}"; done
