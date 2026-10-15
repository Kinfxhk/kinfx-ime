#!/usr/bin/env bash
# Desktop GUI checklist for mixed input + candidate window.
# Headless / no monitor: prints checklist and exits 0 with SKIP note.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== KINFX IME GUI verify (mixed + caret) ==="
echo "Repo scripts:"
echo "  headless smoke: $ROOT/scripts/smoke-linux.sh  (→ tests/run_smoke.sh)"
echo "  install:        $ROOT/scripts/install-linux.sh"
echo "  this checklist: $ROOT/scripts/verify-gui-mixed.sh"
echo

if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  echo "SKIP: no DISPLAY/WAYLAND_DISPLAY — candidate-window visual check needs a monitor."
  echo "See docs/desktop-verify.md"
  exit 0
fi

echo "Manual checklist (docs/desktop-verify.md):"
echo "  [ ] Fcitx5 → 中州韻 → KINFX 速成"
echo "  [ ] Zero-switch mix: type 今日用 API 測試 (ASCII uppercase, no mode toggle)"
echo "  [ ] Optional: Shift inline_ascii (if Fcitx5 does not steal LShift)"
echo "  [ ] Candidate popup below caret; edge flip — NEEDS DISPLAY"
echo "  [ ] Vertical list of 9; Space pages; Enter/1-9 select; Tab expand — layout NEEDS DISPLAY"
echo "  [ ] of: Left from page 1 opens 常用熱門; Space returns to page 1"
echo "  [ ] Jyutping: nei5 / ngo5 / jyut6"
exit 0
