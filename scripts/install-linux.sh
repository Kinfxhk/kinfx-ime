#!/usr/bin/env bash
# Install KINFX IME schemas into a RIME user directory (Fcitx5 default).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${RIME_USER_DIR:-${HOME}/.local/share/fcitx5/rime}"
SYS="${RIME_SHARED_DATA:-/usr/share/rime-data}"
mkdir -p "$TARGET"

echo "Installing KINFX schemas → $TARGET"

# Base presets from system (needed for import_preset / essay / tonal jyutping)
for f in essay.txt essay-cantonese.txt key_bindings.yaml punctuation.yaml symbols.yaml \
         luna_pinyin.dict.yaml luna_quanpin.schema.yaml luna_pinyin.schema.yaml \
         jyut6ping3.dict.yaml jyut6ping3.chars.dict.yaml jyut6ping3.words.dict.yaml \
         jyut6ping3.phrase.dict.yaml jyut6ping3.lettered.dict.yaml jyut6ping3.maps.dict.yaml \
         jyut6ping3.schema.yaml \
         jyutping.dict.yaml jyutping.lettered.dict.yaml jyutping.phrase.dict.yaml \
         jyutping.schema.yaml pinyin.yaml zhuyin.yaml; do
  if [[ -f "$SYS/$f" ]]; then
    if [[ -L "$TARGET/$f" || -f "$TARGET/$f" ]]; then
      :
    else
      ln -s "$SYS/$f" "$TARGET/$f" || cp -a "$SYS/$f" "$TARGET/$f"
      echo "  + $f"
    fi
  else
    echo "  ! missing $SYS/$f"
  fi
done

if [[ -f "$SYS/default.yaml" ]]; then
  cp -a "$SYS/default.yaml" "$TARGET/default.yaml"
else
  echo "ERROR: $SYS/default.yaml missing" >&2
  exit 1
fi

python3 - << PY
from pathlib import Path
import re
p = Path("$TARGET/default.yaml")
text = p.read_text(encoding="utf-8")
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
    text2 = new_list + "\n" + text
text3, n_page = re.subn(
    r"(?m)^menu:\n  page_size:.*\n",
    "menu:\n  page_size: 9\n",
    text2,
    count=1,
)
if n_page == 0:
    text3 = text2.rstrip() + "\n\nmenu:\n  page_size: 9\n"
p.write_text(text3, encoding="utf-8")
print("  patched default.yaml schema_list + menu/page_size: 9")
PY

cp -a "$ROOT/schemas/kinfx-quick/kinfx_quick.schema.yaml" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-quick/kinfx_quick.dict.yaml" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-jyutping/kinfx_jyutping.schema.yaml" "$TARGET/"
echo "  + kinfx_quick + kinfx_jyutping"

if command -v rime_deployer >/dev/null; then
  echo "Deploying with rime_deployer…"
  rime_deployer --build "$TARGET" 2>&1 || true
else
  echo "rime_deployer not found; install librime-bin"
fi

echo "Done. Fcitx5 → 中州韻 → KINFX 速成"
echo "Mixed input default: uppercase Latin inline (no mode switch). See README."
echo "Candidates: 9 per page, select keys 1–9 (schema menu/page_size; not 5)."
echo "Fcitx5 classicui does not override page size; it shows the librime page."
echo "Candidate UX: below caret (docs/ARCHITECTURE.md §4; visual check needs display)."
