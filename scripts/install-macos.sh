#!/usr/bin/env bash
# Install KINFX 中英混打輸入法 into Squirrel (鼠鬚管) on macOS.
#   ./scripts/install-macos.sh            install + deploy + reload Squirrel
#   RIME_USER_DIR=/tmp/x ./scripts/install-macos.sh --no-reload   (test dir)
# Backs up the user dir first (minus build/). Never touches system files.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SQ="${SQUIRREL_APP:-/Library/Input Methods/Squirrel.app}"
TARGET="${RIME_USER_DIR:-$HOME/Library/Rime}"
SHARED="$SQ/Contents/SharedSupport"
RELOAD=1
[[ "${1:-}" == "--no-reload" ]] && RELOAD=0

[[ -x "$SQ/Contents/MacOS/rime_deployer" ]] || {
  echo "ERROR: Squirrel not found at $SQ (brew install --cask squirrel-app)" >&2; exit 1; }
mkdir -p "$TARGET/lua"

if [[ -n "$(ls -A "$TARGET" 2>/dev/null | grep -v '^build$' | grep -v '^lua$' || true)" ]]; then
  BK="$TARGET.backup-$(date +%Y%m%d-%H%M%S)"
  rsync -a --exclude build "$TARGET/" "$BK/"
  echo "Backup → $BK"
fi

echo "Installing KINFX schemas → $TARGET"
for f in kinfx_quick.schema.yaml kinfx_quick.dict.yaml kinfx_phrase.schema.yaml \
         kinfx_en.schema.yaml kinfx_assoc.schema.yaml; do
  cp "$ROOT/schemas/kinfx-quick/$f" "$TARGET/"
done
# Flat copy: rime compiles dictionaries from the user dir, not subfolders.
for f in kinfx_quick_phrase.dict.yaml kinfx_hk_words.dict.yaml kinfx_hk_idioms.dict.yaml \
         kinfx_assoc.dict.yaml kinfx_capture.txt; do
  cp "$ROOT/lexicon/hk/$f" "$TARGET/"
done
for f in kinfx_en.dict.yaml kinfx_en_unsafe.txt kinfx_en_names.txt; do
  cp "$ROOT/lexicon/en/$f" "$TARGET/"
done
cp "$ROOT/schemas/rime.lua" "$TARGET/rime.lua"
for f in win_quick phrase_mix english_mix assoc; do
  cp "$ROOT/schemas/lua/$f.lua" "$TARGET/lua/$f.lua"
done
# v0.4 dropped the Lua-heap lexicon loaders. Remove stale copies.
rm -f "$TARGET/lua/melt_eng.lua" "$TARGET/lua/lexicon_index.lua"

# schema_list: add kinfx_quick without replacing Squirrel's list or other patches.
# "schema_list/+" appends to the shipped list; an existing schema_list patch gets
# one more item. A copy of the old file is kept as default.custom.yaml.bak-*.
DC="$TARGET/default.custom.yaml"
if [[ -f "$DC" ]] && grep -q 'schema: *kinfx_quick' "$DC"; then
  echo "  default.custom.yaml already lists kinfx_quick (kept)"
elif [[ -f "$DC" ]]; then
  cp "$DC" "$DC.bak-$(date +%Y%m%d-%H%M%S)"
  if grep -qE '^[[:space:]]+"?schema_list"?:' "$DC"; then
    awk '{print} /^[[:space:]]+"?schema_list"?:[[:space:]]*$/ && !done {print "    - schema: kinfx_quick"; done=1}' "$DC" > "$DC.tmp"
  elif grep -q '^patch:' "$DC"; then
    awk '{print} /^patch:/ && !done {print "  \"schema_list/+\":"; print "    - schema: kinfx_quick"; done=1}' "$DC" > "$DC.tmp"
  else
    { cat "$DC"; printf 'patch:\n  "schema_list/+":\n    - schema: kinfx_quick\n'; } > "$DC.tmp"
  fi
  mv "$DC.tmp" "$DC"
  echo "  added kinfx_quick to default.custom.yaml (backup kept)"
else
  printf '# KINFX: add the schema to the Squirrel list\npatch:\n  "schema_list/+":\n    - schema: kinfx_quick\n' > "$DC"
  echo "  wrote default.custom.yaml (schema_list/+: kinfx_quick)"
fi

# Two-arg form: one-arg --build reuses the user dir as shared data and fails
# to load punctuation / key_bindings presets.
echo "Deploying: rime_deployer --build"
"$SQ/Contents/MacOS/rime_deployer" --build "$TARGET" "$SHARED"
for b in kinfx_quick.table.bin kinfx_quick_phrase.table.bin kinfx_en.table.bin kinfx_assoc.table.bin; do
  [[ -s "$TARGET/build/$b" ]] || { echo "ERROR: build/$b missing" >&2; exit 1; }
done
grep -m1 'version:' "$TARGET/build/kinfx_quick.schema.yaml"

if [[ $RELOAD == 1 ]]; then
  "$SQ/Contents/MacOS/Squirrel" --reload || true
  echo "Squirrel reloaded."
fi
echo "Done. 系統設定 → 鍵盤 → 輸入方式 → 加入「鼠鬚管」，再揀 KINFX 中英混打輸入法 · 速成。"
echo "Short English words: Left Shift tap (macOS has no Fcitx5-style Shift hotkey to free)."
