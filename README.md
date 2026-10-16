# KINFX 中英混打輸入法

香港繁體速成輸入法，可以中英混打，唔使切換模式。速成候選次序**逐頁跟 Windows 11 微軟速成**，另外補齊港字、常用詞同英文詞。引擎用 [librime](https://github.com/rime/librime)：Windows 11 由 [小狼毫（Weasel）](https://github.com/rime/weasel) 載入，Linux 用 Fcitx5。

**最新版本：v0.5.0**

## 特點

- **候選次序同 Windows 一樣**：658 個兩碼全部喺 Windows 11 Pro 實測，每頁每格逐格比對過，658／658 一致（見 `docs/WIN_QUICK_RANK.md`）。
- **打字唔 lag**：每粒鍵約 0.1–0.2 ms（英文延遲頂字計埋），舊版 v0.3 要約 70 ms（離線測量）。
- **港字齊**：㗎、嘅、𠻹、𨋢 等 Windows 冇嘅字，排喺 Windows 候選之後，唔會郁到 Windows 原本嘅位置。
- **連打順**：第 3 碼照 Windows 頂字上屏。只有打出嚟係常用詞先會留住等你揀，例如：
  - `ofc` → 人類、無錯
  - `ofca` → 無錯
  - `lwm` → 中國
  - 冇詞接得落去就照 Windows 上屏（`vd` `of` `3` → 好係）。
- **細楷英文直接打**：任何英文詞空白上屏（`hello`␣→ hello、`the`␣→ the），短詞用左 Shift（`of` Shift → of）。唔會佔速成嗰 1–9 格。
- **聯想詞**：揀完單字出跟尾詞，Shift+數字揀（`hi7` 揀「我」→ `Shift+2` 揀「講」→ 我講），同 Windows「聯想字」一樣。
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
| `hello` 空白 | hello |
| `of` 左 Shift | of |
| `hi7` `Shift+2` | 我講（聯想） |
| `nei5`（粵拼） | 你 |

## 打英文

v0.5 smart mode：細楷英文詞直接打，大部分用空白上屏。速成碼同英文字母重疊（676 個兩字母組合入面 658 個係速成碼），所以 2 字母短詞要左 Shift 先出到英文。

| 情況 | 做法 | 成本 |
| --- | --- | --- |
| 一般細楷英文詞 | 直接打，空白上屏：`hello`␣→ hello、`startup`␣→ startup | 0 次切換 |
| 2 字母短詞（of、to、on、or…） | 打兩個字母，撳一下**左 Shift**：`of` Shift → of | 1 下 |
| 空白唔上屏嘅詞（少見／有歧義） | 打完成個詞，撳左 Shift 上屏 | 1 下 |
| 大寫開頭、email、URL | 直接打：`Startup`、`a@b.com`、`www.x.com` | 0 次切換 |
| 打長段英文 | `Ctrl+Shift+2` 切英文模式，再撳一次返中文 | — |

空白上屏係「安全詞表」（SCOWL 字頻篩選）：會同速成碼撞車嘅短詞、或者太生僻嘅詞，空白唔會上屏，改用左 Shift。詳情見 `docs/ENGLISH_MIX.md`。

打英文期間，頂字嘅中文會擺住等你決定；撳其他鍵就照 Windows 上屏，打中文結果唔變。

## 設定

全部跟 Windows 預設，要改先改，見 `docs/CONFIG.md` 同 `schemas/examples/kinfx_quick.custom.yaml.example`。

| 想要 | 設定 |
| --- | --- |
| 純 Windows 頂字，唔出詞 | `"phrase_mix/capture": none` |
| 關掉英文詞 | `"english/enable": false` |
| 英文改返 v0.4.1（只限 extras.tsv 字） | `"english/mode": "shift"` |
| 關掉聯想詞 | `"association/enable": false` |
| 空白揀字而唔係翻頁 | `"win_quick/space_pages": false` |

## 方案

| 選單名 | schema_id |
| --- | --- |
| KINFX 中英混打輸入法 · 速成 | `kinfx_quick` |
| KINFX 中英混打輸入法 · 粵拼 | `kinfx_jyutping` |

## 測試

| 指令 | 內容 |
| --- | --- |
| `bash tools/rimeh/accept.sh` | Windows，離線 47 項，用已安裝嘅小狼毫 rime.dll |
| `bash tools/rimeh/fullorder.sh` | 658 個碼逐格同 Windows 比對 |
| `bash tools/rimeh/flex.sh` | 設定開關（英文 mode/space、聯想、詞語）20 項 |
| `python tools/rimeh/compare.py` | 逐鍵 app 文字離線比對（smart 對 control、聯想對 smart） |
| `pwsh -File scripts/test-windows-rime.ps1` | 安裝／卸載腳本 |
| `python tests/test_gen_quick_dict.py`<br>`python tests/test_gen_quick_phrases.py`<br>`python tests/test_gen_assoc.py`<br>`python tests/test_gen_english_space.py` | 碼表／聯想／英文詞表生成器 |
| `./scripts/smoke-linux.sh` | Linux／CI headless smoke |

## 目錄

| 路徑 | 內容 |
| --- | --- |
| `schemas/kinfx-quick/` | 速成方案、碼表、Windows 實測次序 `ms_quick_order.tsv` |
| `schemas/kinfx-jyutping/` | 粵拼方案 |
| `schemas/lua/` | 選字（`win_quick.lua`）、詞語留鍵（`phrase_mix.lua`）、英文混打（`english_mix.lua`）、聯想（`assoc.lua`） |
| `lexicon/` | 港詞、四字詞、聯想詞、英文詞（各自授權） |
| `scripts/` | 安裝、卸載、生成碼表 |
| `tools/mscapture/` | 讀取 Windows 微軟速成候選次序 |
| `tools/rimeh/` | 離線測試同效能量度 |
| `docs/` | 詳細文件 |

## 授權

- 本專案程式同文件：MIT（`LICENSE`）
- 詞庫同上游資料：見 `NOTICE` 同 `lexicon/NOTICE`（LGPL-3.0、CC BY 4.0、SCOWL）。`lexicon/` 唔係 MIT。
- `ms_quick_order.tsv` 只記錄候選次序作為參考，唔包含微軟程式或者字庫檔。

## English

KINFX is a Hong Kong Traditional Chinese Sucheng (Quick) IME on librime. On Windows 11 it runs inside Weasel; on Linux it runs inside Fcitx5. v0.5 follows the Windows 11 Microsoft Quick candidate order on every page (all 658 two-letter codes measured and matching 658/658), holds keys only for common phrases (`ofc` → 人類), commits lowercase English words on Space with a safe-word list (Left Shift for short words), and opens Windows-style association words after a single-character pick. Measured offline, a two-letter code takes about 0.2 ms and a long English word about 0.2 ms per key; v0.3 took about 70 ms. Install with `scripts/install-windows.ps1` or `scripts/install-linux.sh`. Code is MIT; dictionaries keep their upstream licenses.
