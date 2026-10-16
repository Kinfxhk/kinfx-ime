#!/usr/bin/env bash
# Offline acceptance on the installed Weasel librime (rime.dll) through rimeh.
# Never touches %APPDATA%\Rime. Usage: tools/rimeh/accept.sh
# Exit 0 when every case passes. Prints p50 latency per keystroke too.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
U="${RIMEH_TMP:-$LOCALAPPDATA/hermes/profiles/it-dog/cache/scratch}/rime-accept"
SHARED="${RIMEH_SHARED:-C:/Program Files/Rime/weasel-0.17.4/data}"
[ -x "$ROOT/tools/rimeh/rimeh.exe" ] || bash "$ROOT/tools/rimeh/build.sh" >/dev/null
bash "$ROOT/tools/rimeh/stage.sh" "$U" >/dev/null
# Cases: keys <TAB> expected commit (C:...) or expected first candidates (M:a|b|c)
CASES=$(cat <<'EOF'
vd1	C:好
vd{space}1	C:嫻
vd{space}3	C:樂
vdof3	C:好係
hi7	C:我
hiofrr1	C:凡伙呂
ofc1	C:人類
ofc2	C:無錯
ofca1	C:無錯
ofch1	C:無錫
ofcx1	C:伙鏽
lwm1	C:中國
mor1	C:一個
kjo1	C:大家
vdvd1	C:好好
ymml1	C:上面
vdbr1	C:好同
hioa1	C:我會
gmai1	C:Gmail
scriptwriti1	C:scriptwriting
voiceove1	C:voiceover
vdAPI{space}	C:好API
or9	C:含
of3	C:係
me5	C:夏
ai2	C:時
mk1	C:天
rr9	C:唔
vd	M:好|她|妹|紆|巢|媒|彙|綑|綵
hi	M:凡|么|丟|夙|舟|卵|我|私|的
of	M:伙|你|係|偽|氮|焦|無|絛|僚
h	M:竹|丿
me	M:汞|歿|泵|玻|夏|破|球|豉|瑕
rd	M:吁|呆|味|呼|咪|咻|哮|喋|嗓
EOF
)
{
  echo "schema kinfx_quick"
  echo "max 9"
  while IFS=$'\t' read -r k _; do [ -n "$k" ] && echo "keys $k"; done <<<"$CASES"
  echo "bench vd 100"
  echo "bench vdvdvdvd 50"
  echo "bench hiofrrvdmkaihime 30"
} > "$U/cmds.txt"
OUT=$("$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" < "$U/cmds.txt" 2>/dev/null | tr -d '\r')
pass=0; fail=0
while IFS=$'\t' read -r k want; do
  [ -z "$k" ] && continue
  line=$(printf '%s\n' "$OUT" | awk -F'\t' -v k="$k" '$1=="OK" && $2==k {print; exit}')
  commit=$(printf '%s' "$line" | cut -f3)
  menu=$(printf '%s' "$line" | cut -f5 | sed 's/~[^|]*//g')
  case "$want" in
    C:*) got="$commit"; exp="${want#C:}";;
    M:*) got="$menu"; exp="${want#M:}";;
  esac
  if [ "$got" = "$exp" ]; then pass=$((pass+1)); echo "OK   $k → $got"
  else fail=$((fail+1)); echo "FAIL $k → got [$got] want [$exp]"; fi
done <<<"$CASES"
printf '%s\n' "$OUT" | grep '^BENCH' | sed 's/^/     /'
echo "PASS $pass/$((pass+fail))"
[ "$fail" -eq 0 ]
