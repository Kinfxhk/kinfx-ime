# KINFX 中英混打輸入法

Desktop 優先的開源中英混打輸入法（繁體／香港）。同一套打法要在全平台都好用；**這一版先把 Desktop 打磨好**：Linux（Fcitx5）已經可用，Windows 11 用小狼毫載入同一套 schema（見 `docs/WINDOWS.md`），macOS、手機其後。共用引擎係 **librime**。GitHub repo slug 仍然係 `kinfx-ime`。

設計目標：中文同英文夾在同一輸入流，預設唔使切模式。候選窗、選字鍵、詞庫都按 Desktop 打字習慣收斂，再帶到其他平台。

**方案優先**：**速成（做到最好）→ 粵拼 → 倉頡／注音／拼音**

## 功能（v0.3.1）

- **速成優先**：倉頡字根、只取首尾二碼，對齊 Windows 微軟速成。**粵拼有聲調**（`jyut6ping3`，例 `nei5`、`jyut6`）。
- **中英混打預設零切換**：大寫拉丁、email、URL 直出，唔使切英文模式。
- **候選（Windows 選字習慣）**：每頁 9 個、直列；空白翻頁；Enter／1–9 選字；Tab 展開；多頁碼有常用熱門環頁。
- **詞／成語前綴**：例 `ofc`→無錯。**英詞補全**：`gmai`→Gmail；另有 scriptwriting、voiceover。
- **短碼中文首位**：`me`／`or`／`of` 唔會被英詞搶走。
- **Flex**：混打、Shift、ASCII、排序、頁數全部可設定（`docs/CONFIG.md`）。
- **引擎 librime**；**Linux Desktop（Fcitx5）先**。候選窗跟游標、開喺下方、貼邊自動翻（目測需顯示器，見 `docs/ARCHITECTURE.md` §4）。

Fcitx 選單（`schema_id` 冇改）：

| 選單名 | schema_id |
| --- | --- |
| KINFX 中英混打輸入法 · 速成 | `kinfx_quick` |
| KINFX 中英混打輸入法 · 粵拼 | `kinfx_jyutping` |

## 點解用 RIME

見 `docs/ARCHITECTURE.md`：唔從零造引擎；schema 覆蓋形碼＋拼音；前端只做系統對接與 UX。Linux 選 **Fcitx5 + fcitx5-rime**（LGPL 系）。

## 目錄

| 路徑 | 說明 |
| --- | --- |
| `schemas/kinfx-quick/` | P0 速成 schema + 單字碼表（字頻權重／罕用字過濾） |
| `lexicon/` | 詞／四字帶／英詞（各自授權，見 `lexicon/NOTICE`，唔係 MIT） |
| `schemas/kinfx-jyutping/` | P1 粵拼（`jyut6ping3` 有聲調） |
| `schemas/examples/` | `*.custom.yaml.example`（Flex 設定） |
| `docs/` | ARCHITECTURE／LAYOUTS／STATUS／**CONFIG**／**WIN_QUICK_RANK**／**WIN_QUICK_SELECT**／**PHRASE_MIX**／**desktop-verify**／**WINDOWS** |
| `scripts/` | 安裝（Linux／Windows）、smoke、GUI checklist、重新生成碼表 |
| `tests/` | Headless smoke、混打驗收 |
| `third_party/rime-quick/` | 上游速成參考（LGPL-3） |

## Linux Desktop 安裝

```bash
# 依賴（Debian/Ubuntu 例）
sudo apt install fcitx5 fcitx5-rime librime-bin librime-plugin-lua \
  rime-data-cangjie5 rime-data-jyut6ping3 rime-essay rime-prelude rime-data-luna-pinyin

# 安裝本專案 schema
./scripts/install-linux.sh

# Fcitx5 設定 → 加入「中州韻」→ 選「KINFX 中英混打輸入法 · 速成」
# schema_id 係 kinfx_quick（粵拼選單：「KINFX 中英混打輸入法 · 粵拼」／ kinfx_jyutping）
```

預設資料目錄：`~/.local/share/fcitx5/rime/`。

### Fcitx5 與左 Shift

Fcitx5 預設常用 **LShift** 切輸入法／鍵盤，會**搶走** rime `inline_ascii`。  
**預設混打唔依賴呢個鍵**：同一輸入流打大寫英文即可（例：`今日用 API 測試`）。  
若要 rime 食到 Shift：用 `fcitx5-configtool` 改綁定，或見 `docs/CONFIG.md`。

## Windows 11 安裝

Windows 11 用 **Weasel（小狼毫）** 做 TSF 宿主。本 repo 只部署 schema／詞庫，唔包含自寫 TSF DLL、純 MSIX 註冊、或 Weasel fork。步驟、驗收表、卸載、簽章／Store 說明見 **`docs/WINDOWS.md`**。

```powershell
# 先裝小狼毫（安裝器要系統管理員；或用 GitHub Releases 官方安裝器）
winget install Rime.Weasel

# schema 部署去打字用戶的 %APPDATA%\Rime（唔好用管理員身分跑）
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

重新部署（小狼毫右鍵 → **重新部署**）之後，**Win+Space** 揀小狼毫，選單選 **KINFX 中英混打輸入法 · 速成**（`kinfx_quick`）。粵拼選單係 **KINFX 中英混打輸入法 · 粵拼**（`kinfx_jyutping`）。UX 同 v0.3.1：每頁 9、直列、空白翻頁、1–9／Enter 選字、Tab 展開。

分享 zip：`.\scripts\pack-windows-share.ps1` → `dist/kinfx-ime-windows-share.zip`。

**建議標籤 v0.3.2**（文件同 Windows 腳本；標籤由維護者 merge 之後先打）。Win11 真機驗收仍然係手動。

## 中英混打（預設＝零切換）

| ID | 條件 |
| --- | --- |
| M0 | **零切換**：大寫拉丁／email／URL 直出；唔使切英文模式 |
| M1 | 可選 Shift 臨時西文／`ascii_mode`（可關、可改鍵） |
| M2 | 組字途中可夾英文（`好API`） |
| M4 | email／URL 唔被形碼食掉 |

清單：`tests/ACCEPTANCE_MIXED_INPUT.md`。改行為：`docs/CONFIG.md`。

## 粵拼（有聲調）

依賴套件：`rime-data-jyut6ping3`（rime-cantonese）。

| 輸入 | 預期 |
| --- | --- |
| `nei5` | 你 |
| `ngo5` | 我 |
| `jyut6` | 粵 |
| `nei`／`ngo`／`jyut` | 同上（可唔打調號） |

## Headless 測試

```bash
./scripts/smoke-linux.sh
# 等同 ./tests/run_smoke.sh
```

Smoke 用 **schema_id** `kinfx_quick` 選方案，唔靠選單顯示名。桌面 checklist（**候選窗視覺需顯示器**）：`docs/desktop-verify.md`、`./scripts/verify-gui-mixed.sh`。

## 候選

每頁 **9** 個、**直列**、選字鍵 **1–9**。**空白翻頁**，**Enter／1–9 選焦點**，**Tab 展開**多欄，多頁碼有「常用熱門」環頁。無候選窗時空白仍然上屏（`好API`）。詳見 `docs/WIN_QUICK_SELECT.md`。頭頁對照：`docs/WIN_QUICK_RANK.md`。詞／英詞：`docs/PHRASE_MIX.md`。視窗預設 **跟游標、開喺下方、貼邊自動翻**。直列同展開格仔嘅目測標 **需顯示器**。見 `docs/ARCHITECTURE.md` §4。Flex：`docs/CONFIG.md`。

## 排列

預設 **`win_quick`**。表：`docs/LAYOUTS.md`。

## English (short)

**KINFX 中英混打輸入法** is a Desktop-first mixed Chinese–English IME on **librime**. The repository slug stays `kinfx-ime`. Linux Desktop (Fcitx5) is the headless/CI path. Windows 11 uses Weasel (小狼毫) as the TSF host; this repo ships schemas plus `scripts/install-windows.ps1` (`docs/WINDOWS.md`). macOS follows. Suggested tag for the Windows docs and scripts: **v0.3.2** (not tagged in-repo).

As of v0.3.1: Sucheng/Quick first, tonal Jyutping (`jyut6`, `nei5`). Zero-switch mix (uppercase Latin, email, URL). Nine vertical candidates; Space pages; Enter or 1–9 selects; Tab expands; hot-favorites wrap. Phrase prefix `ofc`→無錯; English completion `gmai`→Gmail, plus scriptwriting and voiceover. Short codes `me` / `or` / `of` stay Chinese-first. Flex settings: `docs/CONFIG.md`. Code: MIT; dictionaries keep upstream licenses (`NOTICE`).

## 授權

- 本專案原創程式／文件：**MIT**（`LICENSE`）
- 詞庫／上游：見 `NOTICE` 同 `lexicon/NOTICE`（LGPL／CC BY／SCOWL 等）。`lexicon/` 唔係 MIT

## 狀態

見 `docs/STATUS.md`（v0.3.1 已出；Windows 11 安裝腳本建議標籤 **v0.3.2**，真機驗收仍係手動）。
