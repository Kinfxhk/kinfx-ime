#!/usr/bin/env bash
# Install KINFX 中英混打輸入法 schemas into a RIME user directory (Fcitx5 default).
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
cp -a "$ROOT/schemas/kinfx-quick/kinfx_phrase.schema.yaml" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-quick/kinfx_en.schema.yaml" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-quick/kinfx_assoc.schema.yaml" "$TARGET/"
cp -a "$ROOT/lexicon/hk/kinfx_capture.txt" "$TARGET/"
cp -a "$ROOT/lexicon/en/kinfx_en_unsafe.txt" "$TARGET/"
cp -a "$ROOT/schemas/kinfx-jyutping/kinfx_jyutping.schema.yaml" "$TARGET/"
# Phrase / English tables stay licensed under lexicon/NOTICE. Flat copy: rime
# compiles dictionary names from the user-data directory, not from subfolders.
cp -a "$ROOT/lexicon/hk/kinfx_quick_phrase.dict.yaml" "$TARGET/"
cp -a "$ROOT/lexicon/hk/kinfx_hk_words.dict.yaml" "$TARGET/"
cp -a "$ROOT/lexicon/hk/kinfx_hk_idioms.dict.yaml" "$TARGET/"
cp -a "$ROOT/lexicon/hk/kinfx_assoc.dict.yaml" "$TARGET/"
cp -a "$ROOT/lexicon/en/kinfx_en.dict.yaml" "$TARGET/"
mkdir -p "$TARGET/lua"
cp -a "$ROOT/schemas/rime.lua" "$TARGET/rime.lua"
cp -a "$ROOT/schemas/lua/win_quick.lua" "$TARGET/lua/win_quick.lua"
cp -a "$ROOT/schemas/lua/phrase_mix.lua" "$TARGET/lua/phrase_mix.lua"
cp -a "$ROOT/schemas/lua/english_mix.lua" "$TARGET/lua/english_mix.lua"
cp -a "$ROOT/schemas/lua/assoc.lua" "$TARGET/lua/assoc.lua"
# v0.4 dropped the Lua-heap lexicon loaders. Remove stale copies.
rm -f "$TARGET/lua/melt_eng.lua" "$TARGET/lua/lexicon_index.lua"
echo "  + kinfx_quick + native phrase/en/assoc tables + lua (win_quick, phrase_mix, english_mix, assoc)"

# One-arg `rime_deployer --build "$TARGET"` reuses the user dir as shared data
# and silently fails to load punctuation/key_bindings. Always pass shared data.
if [[ ! -d "$SYS" ]]; then
  echo "ERROR: shared rime data dir not found: $SYS" >&2
  exit 1
fi
if command -v rime_deployer >/dev/null; then
  echo "Deploying with rime_deployer --build $TARGET $SYS"
  rime_deployer --build "$TARGET" "$SYS"
else
  echo "ERROR: rime_deployer not found; install librime-bin" >&2
  exit 1
fi

# Vertical candidate list is a Fcitx5 classicui setting, not a librime page.
# Squirrel/Weasel read schema style/horizontal: false instead.
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5/conf"
mkdir -p "$CONF_DIR"
python3 - << PY
from pathlib import Path
import re
p = Path("$CONF_DIR") / "classicui.conf"
text = p.read_text(encoding="utf-8") if p.exists() else ""
key = "Vertical Candidate List"
line = key + "=True"
note = (
    "# KINFX default: vertical candidates (Windows Quick).\n"
    "# Flex: set False for a horizontal list. See docs/CONFIG.md.\n"
)
if not text.strip():
    text = note + line + "\n"
elif re.search(rf"(?m)^{re.escape(key)}=.*$", text):
    text = re.sub(rf"(?m)^{re.escape(key)}=.*$", line, text, count=1)
else:
    text = text.rstrip() + "\n" + line + "\n"
p.write_text(text, encoding="utf-8")
print(f"  classicui: {key}=True ({p})")
PY

echo "Done. Fcitx5 → 中州韻 → KINFX 中英混打輸入法 · 速成 (schema_id: kinfx_quick)"
echo "Mixed input default: uppercase Latin inline (no mode switch). See README."
echo "Select: vertical list, 9 per page, Space=page, 1-9/Enter=commit, Tab=expand."
echo "Hot-favorites wrap page is on by default. See docs/WIN_QUICK_SELECT.md."
echo "Fcitx5 classicui does not override page size; it shows the librime page."
echo "Candidate UX: below caret (docs/ARCHITECTURE.md §4; visual check needs display)."
