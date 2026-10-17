#!/usr/bin/env bash
# Stage a throwaway Rime user dir from this repo (never touches %APPDATA%\Rime).
#   tools/rimeh/stage.sh <user_dir>
# Shared data comes from the installed Weasel (cangjie5, luna_pinyin, essay ...).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
U="${1:?user dir}"
rm -rf "$U"; mkdir -p "$U/lua"
cp "$ROOT"/schemas/kinfx-quick/*.yaml "$U/"
cp "$ROOT"/schemas/kinfx-jyutping/*.yaml "$U/" 2>/dev/null || true
cp "$ROOT"/schemas/lua/*.lua "$U/lua/"
cp "$ROOT"/schemas/rime.lua "$U/"
cp "$ROOT"/lexicon/hk/*.yaml "$U/"
cp "$ROOT"/lexicon/en/*.yaml "$U/"
cp "$ROOT"/lexicon/en/kinfx_en_unsafe.txt "$U/"
cp "$ROOT"/lexicon/en/kinfx_en_names.txt "$U/"
cp "$ROOT"/lexicon/hk/kinfx_capture.txt "$U/"
cat > "$U/default.custom.yaml" <<'EOF'
patch:
  schema_list:
    - schema: kinfx_quick
  "menu/page_size": 9
EOF
echo "staged $U"
