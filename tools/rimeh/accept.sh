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
# v0.5: English smart mode commits on Space/Left Shift; association opens after
# a one-character pick. C: with nothing after it asserts "no commit" (Space paged).
CASES=$(cat <<'EOF'
{slash}	C:/
{backslash}	C:、
vdAPI{Shift_L}{Release+Shift_L}	C:好API
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
vd8	C:綑
vd9	C:綵
ymml1	C:上面
vdbr1	C:好同
hioa1	C:我會
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
the{space}	C:the 
hello{space}	C:hello 
startup{space}	C:startup 
gmail{space}	C:Gmail 
the{comma}	C:the，
meeting{Return}	C:汞泣划土
of{Shift_L}{Release+Shift_L}	C:of
of{space}	C:
door{space}	C:來
hel1	C:反中
vdo	M:好人|媒人|好氣|彙集|妹會|樂仔|好入|好傷|好使
hi7{Shift+exclam}	C:我同
hi7{Shift+at}	C:我講
hi71	C:我1
vdhello{space}	C:好hello 
vdthe{space}	C:好the 
abac{comma}	C:明顯，
abac3	C:abaci
abac1	C:明顯
ofcthe{space}	C:伙盆
gmai1	C:Gmail
scriptwriti1	C:scriptwriting
startup{Shift_L}{Release+Shift_L}	C:startup
vdof{Shift_L}{Release+Shift_L}	C:好of
hello{Return}	C:反川人
EOF
)
{
  echo "schema kinfx_quick"
  echo "max 9"
  while IFS=$'\t' read -r k _; do [ -n "$k" ] && echo "keys $k"; done <<<"$CASES"
  echo "bench vd 100"
  echo "bench vdvdvdvd 50"
  echo "bench hiofrrvdmkaihime 30"
  echo "bench thequickbrownfox{space} 30"
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
# v0.5.1 app-visible text (rimeh `typed`): passthrough keys count. "·" = space.
TYPED_CASES=$(cat <<'EOF'
vd1.	好。
hi7.	我。
ofc1.	人類。
vd1,	好，
vd1{question}	好？
vd1{colon}	好：
vd1{minus}	好-
vd1{space}startup{space}	好·startup·
hi9{space}startup{space}	的·startup·
startup{space}	startup·
passion{space}	passion·
rr1passion{space}	呂passion·
abac{comma}	明顯，
abac{space}1	明顯
vd1{exclam}	好似
hi7{space}{space}	我··
vdni3	好多人
of{space}	
vd1{BackSpace}	好
hello{BackSpace}{space}	hell·
hellp{BackSpace}o{space}	hello·
startup{BackSpace}{BackSpace}up{space}	startup·
of{BackSpace}{BackSpace}vd1	好
wondershare{space}	Wondershare·
gitlab{space}	GitLab·
kubernetes{space}	Kubernetes·
openai{space}	OpenAI·
word{space}	word·
apple{space}	apple·
wonderxyz{space}	wonderxyz·
{Shift_L}{Release+Shift_L}vd1	好
{Control+period}vd1,{period}{slash}{semicolon}{Control+period}vd1,	好,./;好，
EOF
)
{
  echo "schema kinfx_quick"
  while IFS=$'\t' read -r k _; do [ -n "$k" ] && echo "typed $k"; done <<<"$TYPED_CASES"
} > "$U/typed.txt"
TOUT=$("$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" --no-deploy < "$U/typed.txt" 2>/dev/null | tr -d '\r')
while IFS=$'\t' read -r k want; do
  [ -z "$k" ] && continue
  got=$(printf '%s\n' "$TOUT" | awk -F'\t' -v k="$k" '$1=="TYPED" && $2==k {print $3; exit}' | sed 's/ /·/g')
  if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "OK   typed $k → $got"
  else fail=$((fail+1)); echo "FAIL typed $k → got [$got] want [$want]"; fi
done <<<"$TYPED_CASES"
echo "PASS $pass/$((pass+fail))"
[ "$fail" -eq 0 ]
