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
# Cases: keys <TAB> expected commit (C:...), first candidates (M:a|b|c) or preedit (P:...)
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
j	M:十
hi	M:凡|么|丟|夙|舟|卵|我|私|的
of	M:伙|你|係|偽|氮|焦|無|絛|僚
h	M:竹|丿
of	P:of
hello	P:hello
vdhe	P:he
ofc	P:ofc
vdAPI	P:好API
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
    P:*) got=$(printf '%s' "$line" | cut -f4); exp="${want#P:}";;
  esac
  if [ "$got" = "$exp" ]; then pass=$((pass+1)); echo "OK   $k → $got"
  else fail=$((fail+1)); echo "FAIL $k → got [$got] want [$exp]"; fi
done <<<"$CASES"
printf '%s\n' "$OUT" | grep '^BENCH' | sed 's/^/     /'
# v0.5.1 app-visible text (rimeh `typed`): passthrough keys count. "·" = space.
# Keep hello{Caps_Lock} last: Caps_Lock leaves ascii_mode on in rimeh (no Caps light).
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
adsense{space}	AdSense·
godaddy{Shift_L}{Release+Shift_L}	GoDaddy
zendesk{comma}	Zendesk，
cpanel{space}	cPanel·
zdrav{Shift_L}{Release+Shift_L}	zdrav
etsy{Shift_L}{Release+Shift_L}	etsy
zdrav1	。啪女
zdrav{space}1	。啪女
adse{space}1	杲馺
adsens1	杲尿乃
zdravo{BackSpace}{Shift_L}{Release+Shift_L}	。啪v
kubernetes{space}	Kubernetes·
openai{space}	OpenAI·
word{space}	word·
apple{space}	apple·
wonderxyz{space}	wonderxyz·
const{space}	const·
async{space}	async·
consts{space}	欲乃
morton{space}1	仄啦俐
giorj{space}1	去合十
j{space}1	十
vda1	好日
gg{Shift_L}{Release+Shift_L}	gg
wp{Shift_L}{Release+Shift_L}	wp
defau{space}	defau·
json{space}	JSON·
{Shift+A}{Shift+I}{space}	AI·
{Shift+S}ony{space}{Shift+P}{Shift+S}5{space}vd1	Sony·PS5·好
vd{Shift+A}{Shift+P}{Shift+I}{space}	好API·
{Shift+A}{Shift+I}{Return}	AI
{Shift+A}{Shift+I}{comma}	AI，
ctrl{space}	ctrl·
esc{space}	esc·
ime{space}	ime·
utf{space}	utf·
del{space}	del·
cfg{space}	cfg·
pid{space}	pid·
ct1	盆
es1	污
lol{Shift_L}{Release+Shift_L}	lol
{Shift_L}{Shift+colon}{Shift+Release+Shift_L}vd1	：好
https{Shift_L}{Shift+colon}{Shift+Release+Shift_L}//x.com{space}	https://x.com·
{Control+period}{Shift_L}{Shift+colon}{Shift+Release+Shift_L}{Shift_L}{Shift+underscore}{Shift+Release+Shift_L}{Shift_L}{Shift+asciicircum}{Shift+Release+Shift_L}{Control+period}	:_^
hel{Shift_L}{Shift+Release+Shift_L}	hel
hel{Shift_L}{Shift+colon}{Shift_L}{Shift+Release+Shift_L}	反中：
{Shift_L}{Shift+colon}{Shift+Release+Shift_L}hel{Shift_L}{Release+Shift_L}	：hel
hi7{Shift_L}{Release+Shift_L}hel{Shift_L}{Release+Shift_L}	我hel
vd{apostrophe}	好'
vd{Shift_L}{Shift+underscore}{Shift+Release+Shift_L}	好_
{Shift_L}{Shift+quotedbl}{Shift+Release+Shift_L}	"
vd,	好，
tool{minus}calling{space}	tool-calling·
json{minus}schema{space}	JSON-schema·
abac{minus}{Return}	明顯
vd{minus}{Return}	好
https://x.com{space}	https://x.com·
www.x.com{space}	www.x.com·
a@b.com{space}	a@b.com·
https{Shift_R}{Shift+colon}{Shift+Release+Shift_R}//x.com{space}	https://x.com·
vd{Shift_R}{Shift+colon}{Shift+Release+Shift_R}	好：
vd;	好；
const;	欲乃廿；
vd{Control+v}	v
vdof{Control+v}	v
zdra{Control+v}	v
vd{Super+v}	v
vd{Meta+v}	v
vd{Control+v}vd1	v好
vd1{Control+v}{Shift+exclam}	好ZZ似
vd.	好。
of.	伙。
ofc.	人類。
vd{space}.	嫻。
vd{Right}.	嫻。
vd{space}1	嫻
vd{Right}1	嫻
vd1{Shift_L}{Shift+parenleft}{Shift+Release+Shift_L}	好（
vd1{Shift+9}	好（
vd1{Shift+KP_9}	好（
vd1{Shift+1}	好似
vd1{Shift+8}	好過
vd19	好9
vd1{Shift_L}{Shift+exclam}{Shift+Release+Shift_L}	好似
vd1{Shift_L}{Shift+asterisk}{Shift+Release+Shift_L}	好過
hello.	hello。
gmai.	Gmail。
11.4	11.4
www.x.com{space}	www.x.com·
vd1{Control+v}{Control+v}	好ZZZZ
vd1{Escape}{Control+v}	好v
hel{Control+c}	反c
{Control+period};'"()_^:!{Control+period}	;'"()_^:!
{Control+period}const;{Control+period}	const;
{Control+period}vd;hi7,{Control+period}	好;我,
{Shift_L}{Release+Shift_L}vd1	好
{Control+period}vd1,{period}{slash}{semicolon}{Control+period}vd1,	好,./;好，
iPhone{space}	iPhone·
iPad{space}	iPad·
iOS{space}	iOS·
eSIM{space}	eSIM·
xAI{space}	xAI·
vdiPhone{space}	好iPhone·
{dollar}48	$48
{percent}	%
{numbersign}	#
{at}	@
HK{dollar}20{comma}000	HK$20,000
20{comma}000	20,000
20{comma}{comma}	20，
1{period}5	1.5
vd1{dollar}	好奇
vd1{percent}	好的
i1	戈
i{space}1	戈
{bracketleft}1nudification{bracketright}1	「nudification」
{bracketleft}1jailbreak{bracketright}1	「jailbreak」
{bracketleft}1hello{bracketright}1	「hello」
{braceleft}1firmware{braceright}1	『firmware』
{bracketleft}1vd1{bracketright}1	「好」
hi7{bracketright}1	我」
vdbr{bracketright}1	好同」
door{bracketright}1	來合」
hello{Caps_Lock}	反川
EOF
)
{
  echo "schema kinfx_quick"
  while IFS=$'\t' read -r k _; do [ -n "$k" ] && echo "typed $k"; done <<<"$TYPED_CASES"
} > "$U/typed.txt"
# Paste cases read the clipboard: set ZZ for the run, restore it after.
CLIP_SAVE="$U/clip_save.txt"
powershell.exe -NoProfile -Command "Get-Clipboard -Raw | Set-Content -Encoding UTF8 -NoNewline '$(cygpath -w "$CLIP_SAVE")'; Set-Clipboard -Value ZZ"
TOUT=$("$ROOT/tools/rimeh/rimeh.exe" "$SHARED" "$(cygpath -m "$U")" --no-deploy < "$U/typed.txt" 2>/dev/null | tr -d '\r')
powershell.exe -NoProfile -Command "Set-Clipboard -Value (Get-Content -Raw -Encoding UTF8 '$(cygpath -w "$CLIP_SAVE")')"
while IFS=$'\t' read -r k want; do
  [ -z "$k" ] && continue
  got=$(printf '%s\n' "$TOUT" | awk -F'\t' -v k="$k" '$1=="TYPED" && $2==k {print $3; exit}' | sed 's/ /·/g')
  if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "OK   typed $k → $got"
  else fail=$((fail+1)); echo "FAIL typed $k → got [$got] want [$want]"; fi
done <<<"$TYPED_CASES"
echo "PASS $pass/$((pass+fail))"
[ "$fail" -eq 0 ]
