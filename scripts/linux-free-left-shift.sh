#!/usr/bin/env bash
# Free Left Shift for KINFX on Fcitx5 (so a Left Shift tap reaches librime and
# commits the held letters as English: of + Left Shift -> of).
#
# Fcitx5 binds Left Shift (TriggerKeys / AltTriggerKeys) to switch input
# methods by default, so librime never sees the tap. This script removes the
# Shift_L entries from TriggerKeys / AltTriggerKeys in ~/.config/fcitx5/config
# (other keys such as Ctrl+Space stay; a backup is written next to it) and
# restarts Fcitx5. Linux VM (fcitx5 5.1.19, both lists emptied): of + Left
# Shift commits "of" and the IM stays on rime.
#
#   scripts/linux-free-left-shift.sh          # apply
#   scripts/linux-free-left-shift.sh --undo   # restore the backup
#
# Switch input methods afterwards with Ctrl+Space (kept) or the tray menu.
set -euo pipefail
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5/config"
BAK="$CONF.kinfx-backup"

if [ "${1:-}" = "--undo" ]; then
  if [ -f "$BAK" ]; then
    cp -a "$BAK" "$CONF"
    echo "restored $CONF from $BAK"
  else
    echo "no backup at $BAK" >&2
    exit 1
  fi
else
  mkdir -p "$(dirname "$CONF")"
  if [ -f "$CONF" ] && [ ! -f "$BAK" ]; then
    cp -a "$CONF" "$BAK"
    echo "backup: $BAK"
  fi
  "${PYTHON:-python3}" - "$CONF" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8") if p.exists() else ""
text = text.replace("\r\n", "\n")

# Fcitx5 stores a key list as a [Hotkey/<Name>] section with 0=, 1=, ... lines.
# Default: TriggerKeys = Control+space ...; AltTriggerKeys = Shift_L.
# Drop only Shift_L entries; keep every other switch key (Ctrl+Space stays).
SEC = r"(?m)^\[Hotkey/{name}\]\n((?:(?!\[)[^\n]*\n?)*)"

def keys_of(text, name):
    m = re.search(SEC.format(name=name), text)
    if not m:
        return None, text
    keys = [l.split("=", 1)[1] for l in m.group(1).splitlines() if re.match(r"^\d+=", l)]
    return keys, text[:m.start()] + text[m.end():]

def ensure_hotkey(text):
    if not re.search(r"(?m)^\[Hotkey\]\s*$", text):
        text = text.rstrip() + ("\n\n" if text.strip() else "") + "[Hotkey]\n"
    return text

for name, default in (("TriggerKeys", None), ("AltTriggerKeys", ["Shift_L"])):
    keys, text = keys_of(text, name)
    if keys is None:
        keys = default
    if keys is None:
        continue  # default list has no Shift_L
    keep = [k for k in keys if k != "Shift_L"]
    text = re.sub(rf"(?m)^{name}=.*\n?", "", text)
    if keep:
        body = "".join(f"{i}={k}\n" for i, k in enumerate(keep))
        text = text.rstrip() + f"\n\n[Hotkey/{name}]\n" + body
    else:
        text = ensure_hotkey(text)
        text = re.sub(r"(?m)^\[Hotkey\]\s*$", f"[Hotkey]\n{name}=", text, count=1)
    print(f"  {name}: {keys} -> {keep}")

text = re.sub(r"\n{3,}", "\n\n", text).lstrip("\n")
p.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8", newline="\n")
print(f"  wrote {p}")
PY
fi

if command -v fcitx5 >/dev/null 2>&1; then
  fcitx5 -r -d >/dev/null 2>&1 || true
  echo "fcitx5 restarted"
else
  echo "restart Fcitx5 to apply"
fi
