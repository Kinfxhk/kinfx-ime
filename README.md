# KINFX 中英混打輸入法

香港繁體速成。打英文不必切換模式，候選字次序與 Windows 11 微軟速成逐頁一致。

**最新版本：v0.5.10**（2026-10-19）· [發佈頁](https://github.com/Kinfxhk/kinfx-ime/releases/tag/v0.5.10)

本 repo 是 Rime 方案檔，供小狼毫（Windows）、鼠鬚管（macOS）和 Fcitx5-Rime（Linux）使用。想獨立直裝，用 [KINFX Input v0.1.3](https://github.com/Kinfxhk/kinfx-input/releases/tag/v0.1.3)。

**OpenVanilla `.cin`：** 而家唔支援 OpenVanilla `.cin` 匯出；詞庫係 Rime `.dict.yaml`。

## 特色

- **與微軟速成一樣**：658 個兩碼的候選次序逐頁逐格對照 Windows 11；第三碼頂字上屏，打字習慣不用改。
- **中英混打**：直接打細楷英文，按空白上屏並自動加一個空格（`startup` → `startup `）；短字按一下左 Shift（`of`）。
- **認得常用名稱**：公司、品牌、網站名自動大小寫（`adsense` → `AdSense`、`openai` → `OpenAI`）。
- **港字齊全**：㗎、嘅、𠻹、𨋢 等 Windows 沒有的字，排在 Windows 候選之後，不打亂原有位置。
- **常用詞**：`ofc` → 人類、`ofca` → 無錯、`hioa` → 我會。
- **聯想詞**：選字後出跟尾詞，按 Shift＋數字選（`hi` 7 再 Shift+2 → 我講）。
- **打 code、網址不用切換**：`https://x.com`、`tool-calling`、`/` 直接打出。
- **反應快**：每個按鍵約 0.1 毫秒。
- **另有粵拼方案**：有聲調（`nei5` → 你）。

## 安裝

已用小狼毫、鼠鬚管或 Fcitx5：用本方案包。小狼毫、鼠鬚管、Fcitx5 是 Rime 上游宿主，請另行安裝。安裝腳本會先備份原有設定，也不會刪除原有方案。

| 平台 | 方案包（[v0.5.10](https://github.com/Kinfxhk/kinfx-ime/releases/tag/v0.5.10)） |
| --- | --- |
| Windows | [kinfx-ime-windows-share.zip](https://github.com/Kinfxhk/kinfx-ime/releases/download/v0.5.10/kinfx-ime-windows-share.zip) |
| macOS | [kinfx-ime-macos.zip](https://github.com/Kinfxhk/kinfx-ime/releases/download/v0.5.10/kinfx-ime-macos.zip) |
| Linux | 沒有 zip。Clone 本 repo 後執行 `scripts/install-linux.sh` |

### 獨立直裝（[KINFX Input](https://github.com/Kinfxhk/kinfx-input)）

| 平台 | 安裝包（[v0.1.3](https://github.com/Kinfxhk/kinfx-input/releases/tag/v0.1.3)） |
| --- | --- |
| macOS | [KINFX-Input-0.1.3-macOS.pkg](https://github.com/Kinfxhk/kinfx-input/releases/download/v0.1.3/KINFX-Input-0.1.3-macOS.pkg) |
| Windows | [KINFX-Input-0.1.3-Windows-x64.exe](https://github.com/Kinfxhk/kinfx-input/releases/download/v0.1.3/KINFX-Input-0.1.3-Windows-x64.exe) |
| Linux（amd64） | [kinfx-input_0.1.3_amd64.deb](https://github.com/Kinfxhk/kinfx-input/releases/download/v0.1.3/kinfx-input_0.1.3_amd64.deb) |

macOS 雙擊 `.pkg`。Windows 以系統管理員執行 `.exe`。Linux：`sudo apt install ./kinfx-input_0.1.3_amd64.deb`，然後 `ibus restart`。

### Windows 11

1. 安裝小狼毫：在 PowerShell 執行 `winget install Rime.Weasel`。
2. 下載 [kinfx-ime-windows-share.zip](https://github.com/Kinfxhk/kinfx-ime/releases/download/v0.5.10/kinfx-ime-windows-share.zip)，然後解壓。
3. 在解壓出來的資料夾，用平時打字的帳戶（不要用系統管理員）執行：

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
   ```

4. 按 **Win+Space** 選小狼毫，再按 Ctrl+` 或 F4，選「**KINFX 中英混打輸入法 · 速成**」。

卸載：`scripts\uninstall-windows.ps1`。粵拼方案要另外把 rime-cantonese 的 `jyut6ping3*.yaml` 和 `essay-cantonese.txt` 放進 `%APPDATA%\Rime`。詳細步驟見 `docs/WINDOWS.md`。

### macOS

1. 安裝鼠鬚管：`brew install --cask squirrel-app`（或自行安裝 Squirrel.app）。
2. 下載 [kinfx-ime-macos.zip](https://github.com/Kinfxhk/kinfx-ime/releases/download/v0.5.10/kinfx-ime-macos.zip)，解壓後在資料夾內執行：

   ```bash
   bash scripts/install-macos.sh
   ```

3. 系統設定 → 鍵盤 → 輸入方式 → 加入「鼠鬚管」。
4. 按 Ctrl+` 選「KINFX 中英混打輸入法 · 速成」。

不需要系統管理員權限。

### Linux（Fcitx5）

1. 安裝套件：

   ```bash
   sudo apt install fcitx5 fcitx5-rime librime-bin librime-plugin-lua \
     rime-data-cangjie5 rime-data-jyut6ping3 rime-essay rime-prelude rime-data-luna-pinyin
   ```

2. 沒有 zip。Clone 後安裝：`git clone https://github.com/Kinfxhk/kinfx-ime.git && cd kinfx-ime && ./scripts/install-linux.sh`
3. Fcitx5 設定 → 加入「中州韻」→ 選「KINFX 中英混打輸入法 · 速成」。
4. 讓左 Shift 可以上屏英文：`./scripts/linux-free-left-shift.sh`。Fcitx5 預設用左 Shift 切換輸入法；這個腳本只移除左 Shift，保留 Ctrl+Space，執行 `--undo` 可還原。

### 裝好後試打

`vd` 1 → 好　`vd.` → 好。　`startup` 空白 → `startup `　`of` 左 Shift → `of`

## 三個平台的分別

| 項目 | Windows | macOS | Linux |
| --- | --- | --- | --- |
| 載入 KINFX 的輸入法 | 小狼毫 | 鼠鬚管 | Fcitx5 + fcitx5-rime |
| 安裝 | zip + `install-windows.ps1` | zip + `install-macos.sh` | git + `install-linux.sh` |
| 左 Shift 上屏英文 | 直接可用 | 直接可用 | 先執行 `linux-free-left-shift.sh` |
| 打字中途貼上 | Ctrl+V：收起輸入再貼上 | Cmd+V：已打的字母會先上屏，請先按 Esc 再貼 | Ctrl+V：與 Windows 相同 |
| 候選窗外觀 | KINFX 皮膚（正黑體、圓角） | 跟鼠鬚管主題 | 跟 Fcitx5 主題 |
| 粵拼方案 | 要自行放入粵拼資料 | 未包括 | 隨套件安裝 |
| 測試方式 | 程式按鍵逐個打入視窗（66 項） | 程式按鍵打入 TextEdit（部分項目），其餘直接測 Rime 引擎 | v0.5.1 實機打文章，新版直接測 Rime 引擎 |

速成次序、頂字、英文、聯想等結果，三個平台用同一套方案檔，結果一致。

## 怎樣打

### 速查

| 輸入 | 結果 |
| --- | --- |
| `vd` 1 | 好 |
| `vd` 空白 1 | 嫻（第 2 頁第 1 個，與 Windows 相同） |
| `vd` `of` 3 | 好係（第三碼照 Windows 頂字） |
| `ofc` 1 | 人類 |
| `vd.` | 好。 |
| `startup` 空白 | `startup ` |
| `of` 左 Shift | `of` |
| `adsense` 空白 | `AdSense ` |
| `Sony` 空白 `PS5` 空白 | `Sony PS5 ` |
| `vd` `API` | 好API（大寫直接出） |
| `iPhone` 空白 | `iPhone `（細階單碼後接大楷，照字母出） |
| Shift+4 `48` | $48 |
| `20,000` | 20,000（數字中間的逗號是半形） |
| `llama.cpp` 空白 | `llama.cpp `（字母中間的 . 和 - 保持半形） |
| `hi` 7 再 Shift+2 | 我講（聯想詞） |
| `vd` 1 再 Shift+9 | 好（ |
| `/`　`\` | /　、 |

### 打英文

| 情況 | 做法 | 例子 |
| --- | --- | --- |
| 一般英文詞 | 打完按空白，會自動加空格 | `startup` 空白 → `startup ` |
| 兩個字母的短詞（of、to、on） | 按一下左 Shift | `of` 左 Shift → `of` |
| 容易與中文混淆的詞（例如 door） | 按一下左 Shift | `door` 左 Shift → `door` |
| 公司、品牌、網站名 | 按空白或左 Shift | `openai` 空白 → `OpenAI ` |
| 打到一半變了中文 | 按一下左 Shift，照字母打出 | `zdrav` 左 Shift → `zdrav` |
| 大寫字、縮寫 | 直接打，按空白會加空格 | `AI` 空白 → `AI ` |
| 細階開頭再接大楷（iPhone、eSIM、xAI） | 直接打 | `iPhone` 空白 → `iPhone ` |
| 英文詞後接「」」 | 直接打 | `[` 1 `nudification` `]` 1 → 「nudification」 |
| 網址、電郵、連字號 | 直接打 | `https://x.com`、`a@b.com`、`tool-calling` |
| 字母中間有 . 或 -（檔名、網域、連字詞） | 直接打 | `llama.cpp`、`openai.com`、`bait-and-switch` |
| 長段英文 | Ctrl+Shift+2 切英文模式，再按一次切回中文 | — |

英文不會佔用 1–9 號候選位置。按了英文以外的鍵（數字、標點），結果與一般速成相同。

### 符號與快捷鍵

- `'` `"` `_` `$` `%` `#` `@` 是半形，其餘中文標點是全形。
- 數字後的 `,` `.` `:` 保持半形（20,000、3.14、12:30）；連按兩下就是中文標點。
- 寫程式要全部半形標點：按 **Ctrl+.** 切換，再按一次切回。
- 打字中途按 Ctrl+C／V／X：先收起輸入，再交給程式處理（macOS 見上表）。

### 聯想詞

- 選一個字後會出跟尾詞，按 Shift+1 至 Shift+8 選。
- 直接按數字、標點或空白，就照打出來，並收起聯想詞。
- 聯想詞次序依粵語語料字頻，不是 Windows 的次序。

## 已知限制

- **常用詞未選完時按數字，會選中詞語**：習慣不看候選直接按數字的話，可能多出字（`成功將` → `成功率將`）。這是常用詞功能本身的行為；不想要可設 `"phrase_mix/capture": none`，第三碼就會與 Windows 一樣頂字。
- **打字中途按方向鍵是翻頁**：想移動游標，先按 Esc。
- **`fn` 這類兩個字母的英文**：空白是速成翻頁，請用左 Shift。
- `!!` 會變「！！」。
- **5 個字母的英文詞開頭按空白會出英文**（例如 `fogge`）。不想要可設 `"english/space": long`。
- **macOS**：打字中途貼上，見上面「三個平台的分別」。用遠端桌面或模擬按鍵工具在鼠鬚管 1.1.2 打 Shift+9，可能多出一個「日」，這是鼠鬚管的問題，上游已修正但未出正式版。
- **Linux 舊版 librime（1.13 以前，例如 Ubuntu 24.04 的 1.10）**：數字中間的逗號仍會變全形（20，000）；Ubuntu 26.04（1.16）沒有這個問題。
- **Linux**：不要把 Caps Lock 設為英文上屏鍵（之後會全部變大寫）；Fcitx5 開新視窗有時會切回英文鍵盤，看托盤圖示即可。
- **突然打不到中文**：按 Ctrl+Shift+2，或在工作列把輸入法切回「中」。

## 常見問題

### 可以匯出 .cin 給 OpenVanilla 匯入嗎？

KINFX 沒有匯出按鈕。日常打字用的是 Rime 方案（小狼毫、鼠鬚管、Fcitx5），設定在 yaml。

想自己拿速成字碼去 OpenVanilla 試匯入，在專案目錄執行：

```bash
python3 scripts/export_quick_cin.py
```

腳本讀取 `schemas/kinfx-quick/kinfx_quick.dict.yaml`，寫入 `exports/kinfx_quick.cin`。這個檔案不會提交進 git，跑完指令才會出現。

這是一張靜態碼表：開頭是 `%gen_inp`，按鍵名在 `%keyname`，字碼在 `%chardef`，次序跟字典一樣。表內只有字和碼。中英混打、Lua、聯想詞都不在這張表裡。英文名稱是 `KINFX-Quick`，跟 OpenVanilla 內建的簡易（Simplex）表分開。

請用 OpenVanilla 的「匯入」自己試。本專案不保證這張表與內建簡易表完全一致。

授權跟速成字典相同，見 `NOTICE`（rime-quick、rime-cangjie、rime-essay 為 LGPL-3.0，全文在 `licenses/rime-quick-LGPL-3.0.txt` 和 `third_party/rime-quick/LICENSE`）。匯出腳本是本專案程式，MIT（`LICENSE`）。

## 設定

預設已跟 Windows。要改的話，把下表的設定加進 `kinfx_quick.custom.yaml`（範例：`schemas/examples/kinfx_quick.custom.yaml.example`；說明：`docs/CONFIG.md`）。

| 想要 | 設定 |
| --- | --- |
| 純 Windows 頂字，不出常用詞 | `"phrase_mix/capture": none` |
| 關掉英文 | `"english/enable": false` |
| 空白只上屏 5 個字母以上的英文 | `"english/space": long` |
| 關掉聯想詞 | `"association/enable": false` |
| 選字後空白翻聯想頁（Windows 做法） | `"association/space": page` |
| 「.」翻頁，不上屏 | `"win_quick/period_pages": true` |
| 選字後 Shift+9 選第 9 個聯想詞 | `"association/paren_pick": true` |
| 空白選字，不翻頁 | `"win_quick/space_pages": false` |
| 中文即時上屏（關掉左 Shift 補救） | `"english/rescue_min": 0` |
| 預編輯顯示字根，不顯示字母 | `"english/preedit": radicals` |

## 實測

| 項目 | 結果 | 環境 |
| --- | --- | --- |
| 速成候選次序 | 658 個兩碼，每頁每格與 Windows 一致：**658／658** | 2026-10-15～16，Windows 11 Pro 26H2 微軟速成 |
| Windows 打字 | 自動化驗收 **66／66**，按鍵逐個打入視窗 | v0.5.10，2026-10-19，Windows 11 VM、小狼毫 0.17.4 |
| 打真實文章 | HKEPC 十篇 9,307 字，模擬「不看候選、照 Windows 習慣打」：錯字由 514 減至 **213**，大部分屬上面第一項限制 | v0.5.7／v0.5.8，2026-10-18，Windows VM |
| v0.5.10 修正 | llama.cpp、openai.com、bait-and-switch 等 16 個情境：**16／16**；同一批文章錯字 208 → **195**，沒有段落變差 | v0.5.10，2026-10-19，Windows 11 VM、小狼毫 0.17.4，按鍵逐個打入視窗 |
| v0.5.9 修正 | iPhone、$48、20,000、「nudification」等 17 個情境：**17／17**；同一批文章錯字 213 → **208**，沒有段落變差 | v0.5.9，2026-10-19，Windows 11 VM、小狼毫 0.17.4，按鍵逐個打入視窗 |
| 英文功能有沒有改到中文 | 209 萬組按鍵與沒有英文功能的舊版比較：**中文改變 0** | v0.5.8，離線 |
| macOS 打字 | TextEdit：`vd.` → 好。、`vd` 1 Shift+9 → 好（ | v0.5.8，2026-10-18，鼠鬚管 1.1.2，程式送出按鍵事件，非實體鍵盤 |
| Linux 打字 | 505 字中英文章，去掉空格後 **453／453** 字一致，30 個英文詞全對 | v0.5.1，2026-10-17，Ubuntu 26.04、Fcitx5、gedit |
| 速度 | 每個按鍵約 **0.1 毫秒** | v0.5.1，Windows，離線 |

macOS 與 Linux 新版本的其餘項目，以直接呼叫 Rime 引擎的方式測試，結果與 Windows 相同。

## 更新紀錄

完整紀錄見 [Releases](https://github.com/Kinfxhk/kinfx-ime/releases)。

- **v0.5.10**：字母中間的「.」和「-」保持半形，整個詞照字母出（llama.cpp、openai.com、bait-and-switch）；英文詞後只打「.」仍是「。」。
- **v0.5.9**：iPhone、iPad、eSIM 等細階單碼接大楷不再變成「戈Phone」；Shift+4／5／3／2 出半形 $ % # @，不會吃掉後面的數字；數字中間的逗號保持半形；長英文詞後接「」」先出英文。
- **v0.5.8**：選字後 Shift+9 在各平台都出「（」；新增 macOS 安裝包。
- **v0.5.7**：有候選時「.」直接出「好。」；選字後 Shift+9 出「（」；大寫字後按空白會加空格。
- **v0.5.6**：`ctrl`、`esc`、`ime` 等縮寫按空白出英文；選字後貼上不會收起聯想詞。
- **v0.5.4**：加入約 5 千個品牌、網站名；打到一半變中文時，可按左 Shift 補救。
- **v0.5.3**：可直接打網址、Shift 符號、連字號英文；預編輯顯示字母。
- **v0.5.2**：`/` 直接出；Ctrl+. 切換半形標點；Backspace 只退一個字母。
- **v0.5.1**：修正選字後的標點與空格；新增 Linux 左 Shift 腳本。
- **v0.5.0**：細楷英文直接打、聯想詞。

## 開發者

| 路徑 | 內容 |
| --- | --- |
| `schemas/` | 速成、粵拼方案與 Lua（選字、常用詞、英文、聯想） |
| `lexicon/` | 港詞、四字詞、聯想詞、英文詞與品牌名 |
| `scripts/` | 安裝、卸載、詞表生成；`export_quick_cin.py` 寫出靜態 `.cin` |
| `tools/rimeh/` | 離線測試：`accept.sh`、`fullorder.sh`、`flex.sh`、`compare.py` |
| `tools/mscapture/` | 讀取微軟速成候選次序 |
| `docs/` | 詳細文件，例如 `ENGLISH_MIX.md`、`WIN_QUICK_RANK.md`、`CONFIG.md` |

## 授權

- 程式與文件：MIT（`LICENSE`）。
- 詞庫與上游資料各有授權（LGPL-3.0、CC BY 4.0、SCOWL），見 `NOTICE` 與 `lexicon/NOTICE`；`lexicon/` 不是 MIT。
- `exports/kinfx_quick.cin`（由 `scripts/export_quick_cin.py` 產生）沿用速成字典的 LGPL-3.0，不是 MIT。見 `NOTICE`。
- `ms_quick_order.tsv` 只記錄候選次序作參考，不包含微軟的程式或字庫。

## 支持開發

KINFX 免費、開源。如果對你有幫助，歡迎請我喝杯咖啡：

- [Buy Me a Coffee](https://buymeacoffee.com/kinfxhk)

## English

KINFX is a Hong Kong Traditional Chinese Sucheng (Quick) Rime schema for Weasel (Windows), Squirrel (macOS) and Fcitx5-Rime (Linux). For a standalone input method with installers, use [KINFX Input v0.1.3](https://github.com/Kinfxhk/kinfx-input/releases/tag/v0.1.3).

OpenVanilla `.cin` export is unsupported. Dictionaries are Rime `.dict.yaml`.

- Candidate order matches Windows 11 Microsoft Quick on every page (658/658 two-letter codes); the third key tops out like Windows.
- Type lowercase English without switching modes: Space commits a word and adds a space (`startup` → `startup `); a Left Shift tap commits short words (`of`). Brand names are capitalised (`adsense` → `AdSense`).
- Hong Kong characters, common phrases (`ofc` → 人類) and association words after a pick.
- Schema packages ([v0.5.10](https://github.com/Kinfxhk/kinfx-ime/releases/tag/v0.5.10)): [Windows zip](https://github.com/Kinfxhk/kinfx-ime/releases/download/v0.5.10/kinfx-ime-windows-share.zip), [macOS zip](https://github.com/Kinfxhk/kinfx-ime/releases/download/v0.5.10/kinfx-ime-macos.zip). Linux has no zip; clone the repo and run `scripts/install-linux.sh`, then `scripts/linux-free-left-shift.sh`. Weasel, Squirrel and Fcitx5 are separate host installs.
- Standalone installers ([KINFX Input v0.1.3](https://github.com/Kinfxhk/kinfx-input/releases/tag/v0.1.3)): [macOS .pkg](https://github.com/Kinfxhk/kinfx-input/releases/download/v0.1.3/KINFX-Input-0.1.3-macOS.pkg), [Windows .exe](https://github.com/Kinfxhk/kinfx-input/releases/download/v0.1.3/KINFX-Input-0.1.3-Windows-x64.exe), [Linux .deb](https://github.com/Kinfxhk/kinfx-input/releases/download/v0.1.3/kinfx-input_0.1.3_amd64.deb).
- Platform notes: on macOS, Cmd+V while composing first commits the typed letters, so press Esc first. Linux needs the Left Shift script.
- v0.5.10: `.` and `-` between letters stay half-width and the token stays Latin (`llama.cpp`, `openai.com`, `bait-and-switch`).
- v0.5.9: `iPhone`, `eSIM`, `xAI` stay Latin; Shift+4/5/3/2 give half-width `$ % # @`; the comma inside numbers stays `,` (20,000); a long English word before `」` commits as letters.
- Tested: Windows acceptance 66/66 plus 17 v0.5.9 cases with key events in a VM (v0.5.9); macOS key events in TextEdit for `.` and Shift+9 (v0.5.8); a 505-character article on Linux (v0.5.1). The English feature changed no Chinese output across 2.09 million key sequences.
- A static Sucheng `.cin` table for an OpenVanilla import: `python3 scripts/export_quick_cin.py` writes `exports/kinfx_quick.cin` (generated, not committed). The file is only the character table (`%gen_inp`, `%keyname`, `%chardef`): no mixed English, Lua, or association. `%ename` is `KINFX-Quick`, separate from OpenVanilla's built-in Simplex table. Import it yourself; this project does not claim the table matches that built-in table. Dictionary terms stay LGPL-3.0; see `NOTICE`.
- Code is MIT; dictionaries keep their upstream licences.
