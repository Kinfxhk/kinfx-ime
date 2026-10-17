#!/usr/bin/env bash
# Self-check for install-macos.sh default.custom.yaml handling (scratch dirs only).
set -u
SRC="$1"   # unpacked repo with scripts/install-macos.sh
pass=0; fail=0
check() { # name setup-content expect-grep...
  local name="$1" content="$2"; shift 2
  local W; W=$(mktemp -d /tmp/kxdc.XXXX); mkdir -p "$W/ud"
  [ -n "$content" ] && printf '%s' "$content" > "$W/ud/default.custom.yaml"
  RIME_USER_DIR="$W/ud" "$SRC/scripts/install-macos.sh" --no-reload > "$W/log" 2>&1
  local rc=$? ok=1
  for pat in "$@"; do grep -qE -- "$pat" "$W/ud/default.custom.yaml" || { ok=0; echo "  missing [$pat]"; }; done
  local n; n=$(grep -c 'schema: *kinfx_quick' "$W/ud/default.custom.yaml")
  [ "$n" = 1 ] || { ok=0; echo "  kinfx_quick listed $n times"; }
  ls "$W/ud/build/"*.table.bin >/dev/null 2>&1 || { ok=0; echo "  no table.bin (rc=$rc)"; tail -3 "$W/log"; }
  # the deployed list must contain kinfx_quick (and keep the Squirrel schemas)
  awk "/^schema_list:/{f=1;next} f && /^[^ ]/{f=0} f" "$W/ud/build/default.yaml" | grep -q "schema: kinfx_quick" || { ok=0; echo "  kinfx_quick not in the deployed list"; }
  if [ $ok = 1 ]; then pass=$((pass+1)); echo "OK   $name"; else fail=$((fail+1)); echo "FAIL $name"; cat "$W/ud/default.custom.yaml"; fi
  rm -rf "$W"
}
check none "" '"schema_list/\+":'
check patch-other $'patch:\n  "menu/page_size": 9\n' '"menu/page_size": 9' '"schema_list/\+":'
check own-list $'patch:\n  schema_list:\n    - schema: luna_pinyin\n' 'schema: luna_pinyin' 'schema_list:'
check no-patch $'# empty comment only\n' '"schema_list/\+":'
check already $'patch:\n  schema_list:\n    - schema: kinfx_quick\n    - schema: cangjie5\n' 'schema: cangjie5'
echo "PASS $pass/$((pass+fail))"
