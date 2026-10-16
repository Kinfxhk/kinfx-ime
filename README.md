# KINFX 中英混打輸入法

香港繁體速成輸入法，可以中英混打，唔使切換模式。速成候選次序**逐頁跟 Windows 11 微軟速成**，另外補齊港字、常用詞同英文詞。引擎用 [librime](https://github.com/rime/librime)：Windows 11 由 [小狼毫（Weasel）](https://github.com/rime/weasel) 載入，Linux 用 Fcitx5。

**最新版本：v0.4.0**

## 特點

- **候選次序同 Windows 一樣**：658 個兩碼全部喺 Windows 11 Pro 實測，每頁每格逐格比對過，658／658 一致（見 `docs/WIN_QUICK_RANK.md`）。
- **打字唔 lag**：每粒鍵約 0.03–0.06 ms，舊版 v0.3 要約 70 ms（離線測量）。
- **港字齊**：㗎、嘅、𠻹、𨋢 等 Windows 冇嘅字，排喺 Windows 候選之後，唔會郁到 Windows 原本嘅位置。
- **連打順**：第 3 碼照 Windows 頂字上屏。只有打出嚟係常用詞先會留住等你揀，例如：
  - `ofc` → 人類、無錯
  - `ofca` → 無錯
  - `lwm` → 中國
  - 冇詞接得落去就照 Windows 上屏（`vd` `of` `3` → 好係）。
- **英文**：大寫開頭英文、email、URL 直接輸入；`gmai` → Gmail。
- **選字同 Windows**：每頁 9 個、直列；空白翻頁；1–9／Enter 選字；Tab 展開；第 1 頁按左開「常用熱門」。
- **候選窗**：正黑體、圓角、淺陰影，淺色／深色跟系統。
- **粵拼**：有聲調（`nei5` → 你）。

## Windows 11 安裝

```powershell
# 1. 安裝小狼毫
winget install Rime.Weasel

# 2. 粵拼資料（可選）：將 rime-cantonese 嘅 jyut6ping3*.yaml 同 essay-cantonese.txt 放入 %APPDATA%\Rime

# 3. 安裝 KINFX（用平時打字嗰個帳戶，唔好用系統管理員）
git clone https://github.com/Kinfxhk/kinfx-ime.git
cd kinfx-ime
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

安裝完會自動重新部署。按 **Win+Space** 揀小狼毫，再喺方案選單（Ctrl+` 或 F4）揀「**KINFX 中英混打輸入法 · 速成**」。

卸載：`scripts\uninstall-windows.ps1`。詳細步驟：`docs/WINDOWS.md`。

## Linux（Fcitx5）安裝

```bash
sudo apt install fcitx5 fcitx5-rime librime-bin librime-plugin-lua \
  rime-data-cangjie5 rime-data-jyut6ping3 rime-essay rime-prelude rime-data-luna-pinyin
./scripts/install-linux.sh
```

Fcitx5 設定 → 加入「中州韻」→ 揀「KINFX 中英混打輸入法 · 速成」。

## 打法速查

| 輸入 | 結果 |
| --- | --- |
| `vd` 1 | 好 |
| `vd` 空白 1 | 嫻（第 2 頁第 1 個，同 Windows） |
| `vd` `of` 3 | 好係（Windows 頂字） |
| `ofc` 1 | 人類 |
| `ofca` 1 | 無錯 |
| `hioa` 1 | 我會 |
| `vd` `API` 空白 | 好API |
| `gmai` 1 | Gmail |
| `nei5`（粵拼） | 你 |

## 設定

全部跟 Windows 預設，要改先改，見 `docs/CONFIG.md` 同 `schemas/examples/kinfx_quick.custom.yaml.example`。

| 想要 | 設定 |
| --- | --- |
| 純 Windows 頂字，唔出詞 | `"phrase_mix/capture": none` |
| 關掉英文詞 | `"english/enable": false` |
| 空白揀字而唔係翻頁 | `"win_quick/space_pages": false` |

## 方案

| 選單名 | schema_id |
| --- | --- |
| KINFX 中英混打輸入法 · 速成 | `kinfx_quick` |
| KINFX 中英混打輸入法 · 粵拼 | `kinfx_jyutping` |

## 測試

| 指令 | 內容 |
| --- | --- |
| `bash tools/rimeh/accept.sh` | Windows，離線 34 項，用已安裝嘅小狼毫 rime.dll |
| `bash tools/rimeh/fullorder.sh` | 658 個碼逐格同 Windows 比對 |
| `pwsh -File scripts/test-windows-rime.ps1` | 安裝／卸載腳本 |
| `python tests/test_gen_quick_dict.py`<br>`python tests/test_gen_quick_phrases.py` | 碼表生成器 |
| `./scripts/smoke-linux.sh` | Linux／CI headless smoke |

## 目錄

| 路徑 | 內容 |
| --- | --- |
| `schemas/kinfx-quick/` | 速成方案、碼表、Windows 實測次序 `ms_quick_order.tsv` |
| `schemas/kinfx-jyutping/` | 粵拼方案 |
| `schemas/lua/` | 選字（`win_quick.lua`）、詞語留鍵（`phrase_mix.lua`） |
| `lexicon/` | 港詞、四字詞、英文詞（各自授權） |
| `scripts/` | 安裝、卸載、生成碼表 |
| `tools/mscapture/` | 讀取 Windows 微軟速成候選次序 |
| `tools/rimeh/` | 離線測試同效能量度 |
| `docs/` | 詳細文件 |

## 授權

- 本專案程式同文件：MIT（`LICENSE`）
- 詞庫同上游資料：見 `NOTICE` 同 `lexicon/NOTICE`（LGPL-3.0、CC BY 4.0、SCOWL）。`lexicon/` 唔係 MIT。
- `ms_quick_order.tsv` 只記錄候選次序作為參考，唔包含微軟程式或者字庫檔。

## English

KINFX is a Hong Kong Traditional Chinese Sucheng (Quick) IME on librime. On Windows 11 it runs inside Weasel; on Linux it runs inside Fcitx5. v0.4 follows the Windows 11 Microsoft Quick candidate order on every page. All 658 two-letter codes were measured on Windows 11 Pro and match 658/658. It also adds HK glyphs after the Windows list, holds keys only for common phrases (`ofc` → 人類), and moves the lexicons to native tables. Measured offline, a keystroke takes about 0.05 ms; v0.3 took about 70 ms. Install with `scripts/install-windows.ps1` or `scripts/install-linux.sh`. Code is MIT; dictionaries keep their upstream licenses.
