# KINFX 中英混打輸入法 — STATUS

**版本**：v0.5.0（2026-10-16，開發中）

## v0.5.0

| 項目 | 狀態 |
| --- | --- |
| 細楷英文自由詞直接出（smart mode）：空白上屏安全詞、左 Shift 上屏短詞 | ✅ 離線（`tools/rimeh/accept.sh` 47 項） |
| 英文同 Windows 速成碼分開，唔佔 1–9 格 | ✅ 離線 |
| 聯想詞（揀完單字出跟尾詞，Shift+數字揀，同 Windows「聯想字」一樣） | ✅ 離線 |
| 離線比對器 `typed`（逐鍵 app 文字）＋ `compare.py` | ✅ |
| 真機驗收（小狼毫） | ⬜ 未做（本回合唔准碰 %APPDATA%\Rime） |
| Linux CI smoke（英文 Space/Shift ＋ 聯想） | ⬜ 未跑（冇本機 C compiler，等 GitHub Actions） |

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
