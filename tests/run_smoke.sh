#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USER_DIR="${TMPDIR:-/tmp}/kinfx-ime-smoke-user"
rm -rf "$USER_DIR"
mkdir -p "$USER_DIR"

# Minimal user data: our schemas + links to system dicts needed for deploy
export RIME_USER_DIR="$USER_DIR"
"$ROOT/scripts/install-linux.sh"

# Lexicon generator: one code per word, no cartesian product.
python3 "$ROOT/tests/test_gen_quick_phrases.py"
python3 "$ROOT/tests/test_gen_quick_dict.py"

# Also ensure build can see jyutping if selected — primary smoke is quick
cc -O2 -o "$ROOT/tests/rime_smoke" "$ROOT/tests/rime_smoke.c" -lrime
echo "Running headless smoke against $USER_DIR"
"$ROOT/tests/rime_smoke" "$USER_DIR"
