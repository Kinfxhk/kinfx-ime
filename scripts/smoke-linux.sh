#!/usr/bin/env bash
# Headless Linux smoke (schema deploy + Sucheng + zero-switch mixed + optional Jyutping tones).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tests/run_smoke.sh"
