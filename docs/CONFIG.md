# KINFX 中英混打輸入法 — 設定（Flex）

預設行為跟 Windows 11 微軟速成；要偏離先改。全部設定用 RIME `*.custom.yaml` 寫。

## 預設

| 項目 | 預設 | 說明 |
| --- | --- | --- |
| 主方案 | `kinfx_quick` 速成 | `schema_list` 第一 |
| 排序 | **全表跟 Windows 11 微軟速成** | 見 `docs/WIN_QUICK_RANK.md`。唔學字（`enable_user_dict: false`） |
| 每頁候選 | **9**，選字鍵 1–9 | `menu/page_size` |
| 選字 | 直列；空白翻頁；Enter／1–9 選字；Tab 展開 | 見 `docs/WIN_QUICK_SELECT.md` |
| 頂字 | 第 3 碼照 Windows 上屏 | 常用詞前綴例外，見 `docs/PHRASE_MIX.md` |
| 詞語 | 開（`phrase_mix/capture: hot`） | `ofc` → 人類／無錯、`ofca` → 無錯 |
| 英文詞 | 開（`english/mode: smart`） | 空白上屏安全詞（`hello`␣→ hello）、左 Shift 上屏短詞（`of` Shift→ of） |
| 聯想詞 | 開（`association/enable: true`） | 揀完單字出跟尾詞，Shift+數字揀 |
| 混打 | 零切換 | 大寫英文、email、URL 直出 |
| 常用熱門 | 開 | 第 1 頁按左 |
| 候選窗 | 正黑體、圓角、淺／深色跟系統 | `weasel.custom.yaml` 入面嘅 `kinfx-ime:weasel-skin` 段 |

## 點改

1. 複製 `schemas/examples/kinfx_quick.custom.yaml.example`：
   - Windows：放去 `%APPDATA%\Rime\kinfx_quick.custom.yaml`
   - Linux：放去 `~/.local/share/fcitx5/rime/kinfx_quick.custom.yaml`
2. 取消註解要改嘅項目。
3. 重新部署：
   - 小狼毫：右鍵 → 重新部署
   - Linux：`rime_deployer --build <user_dir> /usr/share/rime-data`

## 常用設定

| 想要 | patch |
| --- | --- |
| 純 Windows 頂字，唔留住任何詞 | `"phrase_mix/capture": none` |
| 任何詞前綴都留住（較少頂字） | `"phrase_mix/capture": all` |
| 完全關掉詞語 | `"phrase_mix/enable": false` |
| 關掉英文詞 | `"english/enable": false` |
| 英文改返 v0.4.1（只限 extras.tsv 字） | `"english/mode": "shift"` |
| 唔留英文（純 Windows 頂字） | `"english/mode": "off"` |
| 空白只上屏 5 字或以上嘅英文 | `"english/space": "long"` |
| 空白唔上屏英文（都要左 Shift） | `"english/space": "off"` |
| 關掉聯想詞 | `"association/enable": false` |
| 空白改回揀焦點候選 | `"win_quick/space_pages": false` |
| 關掉常用熱門 | `"win_quick/hot_page": false` |
| Tab 唔展開 | `"win_quick/tab_expand": false` |
| 候選打橫 | `"style/horizontal": true` |
| 學字（會改 Windows 次序） | `"translator/enable_user_dict": true` |
| 每頁 5 個 | `"menu/page_size": 5` |

## 混打

| 模式 | 做法 |
| --- | --- |
| 零切換（預設） | 細楷英文詞直接打，空白上屏（`hello`␣→ hello）。安全詞表唔畀上屏嘅（短詞、少見詞）就撳一下左 Shift 上屏。大寫、email、URL 直出 |
| 短詞（`of`、`to`、`on`…） | 打到一半撳一下左 Shift：已打字母變英文（`of` Shift → of）。Linux 要先解除 Fcitx5 左 Shift 熱鍵（見下） |
| 揀字後嘅空白／標點 | `vd` 1 之後撳空白＝打空格，撳 `.`＝「。」（會關聯想詞）。想同 Windows 一樣（空白翻聯想頁）：`association/space: page` |
| 持久英文 | `Control+Shift+2` 切換 `ascii_mode` |
| 一定要切先打英文 | 清空 `recognizer/patterns/uppercase` |

## v0.5.2 新開關

| 開關 | 預設 | 作用 |
| --- | --- | --- |
| `english/empty_shift` | `noop` | 冇打字撳左 Shift：`noop` 乜都唔做；`ascii` 照 librime 切臨時英文（v0.5.1） |
| `english/hold_min` | `4` | 英文開頭夠呢個字母數之後，詞表冇嘅字都繼續留住；`0` 關 |
| `english/hold_extra` | `8` | 上面留住最多再多幾多個字母 |
| `english/unknown_space_min` | `5`（v0.5.2 係 `7`） | 詞表冇嘅字，幾多個字母或以上先可以撳空白上屏（6 個字母除外；短啲用左 Shift） |
| `punctuator/half_shape` `/`、`\` | `/`、「、」 | `/` 直出；「、」由 `\` 出 |
| Ctrl+. | — | 切中英文標點（`ascii_punct`），寫 code 用 |

## v0.5.3 新開關

| 開關 | 預設 | 作用 |
| --- | --- | --- |
| `english/preedit` | `letters` | 預編輯顯示打咗嘅字母（`of`、`hello`）；`radicals` 顯示速成字根（`人火`，v0.5.2） |
| `english/hyphen` | `word` | 英文詞後面打 `-` 接駁（`tool-calling`）；`off` 交返標點（v0.5.2） |
| `english/clipboard` | `clear` | 打緊字撳 Ctrl+C／V／X：收起輸入，快捷鍵交返程式；`keep` 照 v0.5.2 |

公司名／產品名表：`lexicon/en/kinfx_en_names.txt`（「顯示字<Tab>細楷碼」）。安裝後喺 Rime 用戶目錄，改完重新部署。

## 自動化測試注意

- **空白上屏英文會自帶一個空格**：`startup` 空白 → `startup `，嗰下空白已經用咗。測試計劃打完英文詞唔好再加一個空白，否則會變雙空格。左 Shift 上屏（`of` 左 Shift → `of`）就冇空格，要空格先再撳空白。
- **揀字後第一下空白係打空格**（`association/space: type`），唔會翻聯想頁。
- **Fcitx5**：重啟或者開新視窗時，輸入法有時會返去 `keyboard-us`。自動化開始前先執行 `fcitx5-remote -s rime`。

### librime 按鍵序列（`simulate_key_sequence`／rimeh `keys`）常見寫錯

三平台（Windows Weasel、Linux Fcitx5、macOS Squirrel）用同一套檔，候選次序一樣。以下寫法錯咗會報假差異：

| 想測 | ✅ 正確 | ❌ 錯誤 | 錯咗會點 |
| --- | --- | --- | --- |
| 揀第 5 個 | `me5` → 夏 | `me 5` | 空白係翻頁，變咗揀第 2 頁第 5 個（璦） |
| 撳一下左 Shift | `is{Shift_L}{Release+Shift_L}` → is | `is{Shift_L}` | 只有按下、冇放開，唔當撳一下，乜都唔出 |
| Shift 打符號 | `{Shift_L}{Shift+colon}{Shift+Release+Shift_L}` → ： | `{Shift+;}` | librime 唔認呢個鍵名，整串序列失敗 |
| 用詞表嘅詞 | 先睇 `kinfx_en_names.txt` 有冇（`grep -P "\tyolo$"`） | — | 版本未有嗰個詞，就會照速成出中文（v0.5.2 `/yolo` → /亥） |

另外：Ctrl+. 切英文標點會記住喺 `user.yaml`（`ascii_punct`）。一連串 case 之前先清走，否則之後所有符號 case 都受影響。

## Fcitx5 同左 Shift

Fcitx5 預設用左 Shift 切輸入法，rime 收唔到。大部分英文詞用空白上屏，唔受影響；但短詞（`of`、`to`）要左 Shift，喺預設 Fcitx5 上面撳落去會切走輸入法，`of` 變返中文（伙）。

**建議：解除 Fcitx5 左 Shift 熱鍵。**

```bash
./scripts/linux-free-left-shift.sh          # 由 TriggerKeys／AltTriggerKeys 移除 Shift_L（Ctrl+Space 保留），備份後重啟 Fcitx5
./scripts/linux-free-left-shift.sh --undo   # 還原
```

2026-10-17 Linux VM（Fcitx5 5.1.19）實測（嗰次兩組熱鍵全部清空）：`of` + 左 Shift → of，輸入法保持 rime。腳本只移除 Shift_L，切輸入法仍可用 Ctrl+Space 或者托盤選單。

**唔建議 `english/commit_key: Caps_Lock`（Linux）**：同一次實測，XKB 嘅 Caps Lock 切換攔唔到，之後全部變大寫（hello → HELLO），`of` 亦冇上屏。
