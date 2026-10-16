#!/usr/bin/env bash
# Build tools/rimeh/rimeh.exe from rimeh.cs with the .NET Framework compiler
# that ships with Windows (no SDK needed). Usage: tools/rimeh/build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CSC="${CSC:-/c/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe}"
[ -x "$CSC" ] || { echo "csc.exe not found: $CSC" >&2; exit 1; }
cd "$DIR"
"$CSC" -nologo -platform:x64 -out:rimeh.exe rimeh.cs >/dev/null
echo "built $DIR/rimeh.exe"
