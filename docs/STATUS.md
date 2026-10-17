# KINFX 中英混打輸入法 — STATUS

**版本**：v0.5.3（2026-10-18）

## v0.5.3（打 code／網址）

| 項目 | 狀態 |
| --- | --- |
| Shift 符號（`:` `_` `^` `!` `"`）：撳住 Shift 打符號唔當英文上屏 tap | ✅ 修正（Windows 實機 `好：`、`https://x.com`） |
| URL：`www.` `https:` `http:` `ftp:` `mailto:` `file:` 開頭保留做網址 | ✅ 修正 |
| 英文詞開頭／未知字 5 個字母起空白上屏（6 字母除外） | ✅ 修正（`const␣`、`async␣`） |
| 連字號：英文詞後 `-` 接駁（`english/hyphen`） | ✅ 新增 |
| Ctrl+C／V／X 打緊字：收起輸入（`english/clipboard`） | ✅ 新增 |
| `;` `'` 唔再做速成分隔符：`vd;` → 好； | ✅ 修正 |
| `'` `"` `_` 出半形（Windows 11 微軟速成實測：`'`→' `_`→_ `"`→"）；，。：照舊全形 | ✅ 修正（Linux 報 `好‘`、`——`） |
| 名表 +141（科技詞、縮寫） | ✅ 新增 |
| 預編輯顯示字母（`of`／成個 `hello`），唔再係字根；`english/preedit: radicals` 還原 | ✅ 新增（Windows 實機截圖確認） |
| `hello` Esc／Ctrl+C 仍會將已頂字嘅中文上屏（Windows 行為：頂咗字就已經上屏） | 🟡 跟 Windows，冇改 |
| camelCase（`getUserById`）頭 3 個細楷仍然頂字 | ⬜ 未做；用左 Shift：`get` 左 Shift `UserById` |
| 2 字母英文撳空白（`gg`、`of`） | ⬜ 未做（空白係速成翻頁）；用左 Shift |

## v0.5.2（用戶親測回報）

| 項目 | 狀態 |
| --- | --- |
| `/` 直出半形 /；`\` 直出「、」 | ✅ 修正 |
| Tab 展開：提示唔再放喺預編輯（唔會寫入文件）；Esc／上屏／清空後自動關 | ✅ 修正 |
| 英文提示（⇧／␣）、常用熱門提示改放候選註釋，唔再放預編輯 | ✅ 修正 |
| Backspace 喺英文詞中間：退一個字母，唔再將擺住嘅中文上屏 | ✅ 修正 |
| 冇打字撳左 Shift：唔再入底線英文模式（`english/empty_shift: noop`）；打緊 `好API` 撳左 Shift＝照顯示上屏 | ✅ 修正 |
| 公司／產品名：新增 `kinfx_en_names.txt`（333 個，例如 Wondershare、GitLab、OpenAI），同未知長英文字（`english/hold_min`） | ✅ 新增 |
| Ctrl+. 切中英文標點（寫 code 用） | ✅ 新增 |


## v0.5.1（Linux VM 實測修正）

| 項目 | 狀態 |
| --- | --- |
| 揀字後打「.」唔上屏（key_binder 將 period 當翻頁）：而家關聯想詞再打「。」；`-` `?` `:` `;` 等同樣 | ✅ 修正 |
| 揀字後空白被聯想詞吞咗，英文詞前冇空格：預設 `association/space: type`（打空格）；`page`＝Windows 翻聯想頁 | ✅ 修正 |
| `passion` 拆字（`pass` 前面已頂字，尾段 `ion` 撞中文詞語）：前面有待上屏頂字時，英文詞成串優先 | ✅ 修正 |
| 「多」出「夀」：本機 `ni` 3＝多、`gi` 第 33 個＝夀，同 Windows 實測一致；VM 計劃檔按鍵要再對 | 🟡 待 VM 重測 |
| `vd1␣␣`Shift+1：預設（type）＝「好  」再 `!`；`association/space: page` 時＝好笑。聯想表係 essay-cantonese 頻率，唔係 Windows 聯想次序 | 🟡 已知差異 |
| Linux 左 Shift：`scripts/linux-free-left-shift.sh` 移除 Fcitx5 Shift_L 熱鍵；Caps Lock 改為唔建議 | ✅ Linux VM 實測 |
| Linux VM（Fcitx5 5.1.19 + gedit）v0.5.1 驗收：「。」9/9、passion、`of`＋左 Shift、505 字文章去空格後 453/453、30 個英詞 | ✅ 外部實測 |


## v0.5.0

| 項目 | 狀態 |
| --- | --- |
| 細楷英文直接打：仲係英文詞開頭就延遲頂字；空白上屏安全詞、左 Shift 上屏短詞 | ✅ 真機 Windows 11（小狼毫 0.17.4） |
| 打中文結果同 v0.4.1 一樣 | ✅ 離線比對 1,904,967 組序列：意外差異 0、中文改變 0（`docs/eval/V05_COMPARE.md`） |
| 中文詞語優先（`abac` 明顯、`abac3` abaci 照舊） | ✅ 真機＋離線 |
| 聯想詞（揀完單字出跟尾詞，Shift＋數字揀，同 Windows 實測行為） | ✅ 真機 |
| 離線驗收 | ✅ accept 58／58、flex 22／22、fullorder 658／658 |
| Windows 11 真機驗收 | ✅ 37／37（`windows-acceptance-v05.ps1`） |
| 安裝腳本測試 | ✅ `scripts/test-windows-rime.ps1` 0 failure |
| 打字延遲 | ✅ 16 粒鍵中文 p50 約 2.3 ms、23 粒鍵英文句 p50 約 2.3 ms（每粒鍵約 0.1–0.2 ms） |
| Linux CI smoke | 見 GitHub Actions |
| Linux Fcitx5 實打（左 Shift） | ⬜ 未做；測試清單 `docs/eval/LINUX_V05_CASES.md` |

## v0.4.1

| 項目 | 狀態 |
| --- | --- |
| `vd` 第 8、9 個＝綑綵（重新實測確認；`win_quick_top9.tsv` 嘅「網綜」係認字錯） | ✅ |
| `win_quick_top9.tsv` 只留 18 個未實測單碼；同實測衝突時生成器會退出 | ✅ |
| 補實測單碼 `a`（日曰） | ✅ |
| 細楷英文 Shift 流程寫入 README／CONFIG／驗收清單 | ✅ |
| Linux（Fcitx5 + gedit）505 字實打 byte-exact | ✅ 外部實測（Mac 側 VM，v0.4.0） |
|**顯示名**：KINFX 中英混打輸入法（repo slug `kinfx-ime`）|

## v0.4.0

| 項目 | 狀態 |
| --- | --- |
| 候選次序逐頁跟 Windows 11 微軟速成 | ✅ 658／658 兩碼逐格一致（`tools/rimeh/fullorder.sh`） |
| 打字延遲 | ✅ 每粒鍵 p50 約 0.03–0.06 ms（v0.3 約 70 ms；rimeh，小狼毫 0.17.4 rime.dll） |
| 港字補齊 | ✅ 喺 Windows 清單之後補 2,163 個港字／Ext 字 |
| 第 3 碼頂字跟 Windows，常用詞留鍵 | ✅ 字頻加權後約 0.6% 組合結果有變，大部分變好（上而 → 上面） |
| 3 碼詞（人類、中國、一個、大家） | ✅ |
| 詞庫改用原生表 | ✅ 唔再喺 Lua heap 載入詞庫 |
| 候選窗：正黑體、圓角、淺／深色 | ✅ 真機截圖確認 |
| Windows 11 真機驗收 | ✅ 26／26（小狼毫 0.17.4，zh-TW） |
| Windows 離線驗收 | ✅ 34／34（`tools/rimeh/accept.sh`） |
| 安裝腳本測試 | ✅ `scripts/test-windows-rime.ps1` 0 failure |
| Linux CI smoke | 見 GitHub Actions |
| Linux 實打 | ✅ 505／505（Fcitx5 5.1.19 + gedit，外部實測） |

## 之前版本

- v0.3.3：頭 9 釘 Windows、輕量皮膚
- v0.3.2：Windows 11 小狼毫安裝腳本
- v0.3.1：英詞 extras
- v0.3.0：詞前綴
- v0.2.0：空白翻頁、Enter 確認

## Next

1. 真四欄候選格（而家 Tab 展開仍然用註釋顯示）
2. macOS Squirrel
3. 倉頡、注音、拼音方案
4. 設定介面

## 已知限制

- 候選窗由小狼毫畫，唔係 Windows 原生 UI。
- `ms_quick_order.tsv` 喺「固定候選字順序」關、Ext-A／B／HKSCS 關嘅情況下量度；如果你改咗 Windows 速成設定，次序可能唔同。
- 英文詞表（SCOWL）要喺有 `/usr/share/dict/words` 嘅機器先可以重新生成。
