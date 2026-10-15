#!/usr/bin/env bash
# Install KINFX IME schemas into a RIME user directory (Fcitx5 default).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${RIME_USER_DIR:-${HOME}/.local/share/fcitx5/rime}"
SYS="${RIME_SHARED_DATA:-/usr/share/rime-data}"
mkdir -p "$TARGET"

echo "Installing KINFX schemas → $TARGET"

# Base presets from system (needed for import_preset: default / punctuator / essay)
for f in essay.txt key_bindings.yaml punctuation.yaml symbols.yaml \
         luna_pinyin.dict.yaml luna_quanpin.schema.yaml luna_pinyin.schema.yaml \
         jyutping.dict.yaml jyutping.lettered.dict.yaml jyutping.phrase.dict.yaml \
         jyutping.schema.yaml pinyin.yaml zhuyin.yaml; do
  if [[ -f "$SYS/$f" ]]; then
    if [[ -L "$TARGET/$f" || -f "$TARGET/$f" ]]; then
      : # keep existing
    else
      ln -s "$SYS/$f" "$TARGET/$f" || cp -a "$SYS/$f" "$TARGET/$f"
      echo "  + $f"
    fi
  else
    echo "  ! missing $SYS/$f"
  fi
done

# Start from system default.yaml (has key_binder / recognizer / punctuator includes)
if [[ -f "$SYS/default.yaml" ]]; then
  cp -a "$SYS/default.yaml" "$TARGET/default.yaml"
else
  echo "ERROR: $SYS/default.yaml missing" >&2
  exit 1
fi

# Patch schema_list + ascii_composer mixed-input defaults via rime_patch if available,
# else rewrite with Python
python3 - << PY
from pathlib import Path
p = Path("$TARGET/default.yaml")
text = p.read_text(encoding="utf-8")
# Replace schema_list block (simple approach: write our preferred head fields)
import re
# Ensure ascii_composer uses inline_ascii (usually already)
if "Shift_L: inline_ascii" not in text and "ascii_composer:" in text:
    text = text.replace("Shift_L:", "Shift_L: inline_ascii  # kinfx\n    # was:")
# Replace schema_list
new_list = """schema_list:
  - schema: kinfx_quick
  - schema: kinfx_jyutping
"""
text2, n = re.subn(
    r"schema_list:\n(?:  - schema:.*\n)+",
    new_list,
    text,
    count=1,
)
if n == 0:
    # prepend
    text2 = new_list + "\n" + text
p.write_text(text2, encoding="utf-8")
print("  patched default.yaml schema_list")
PY

cp -a "$ROOT/schemas/kinfx-quick/kinfx_quick.schema.yaml" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-quick/kinfx_quick.dict.yaml" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-jyutping/kinfx_jyutping.schema.yaml" "$TARGET/"
echo "  + kinfx_quick + kinfx_jyutping"

if command -v rime_deployer >/dev/null; then
  echo "Deploying with rime_deployer…"
  # Prefer building in user dir
  rime_deployer --build "$TARGET" 2>&1 || true
else
  echo "rime_deployer not found; install librime-bin"
fi

echo "Done. Fcitx5 → 中州韻 → KINFX 速成"
echo "Candidate UX: below caret, never cover typing line (docs/ARCHITECTURE.md §4)."
