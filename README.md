# KINFX IME

開源中文輸入法專案（繁體／香港優先）——以 **librime** 為共用引擎，Linux 先做，macOS 次之，其後 Windows／Android／iOS。

**方案優先**：**速成（做到最好）→ 粵拼 → 倉頡／注音／拼音**  
**硬需求**：中英混打（**預設全程零切換**）、候選窗**唔遮游標**、候選**每頁 9 個（選字鍵 1–9，同 Windows 官方速成）**、Windows 慣用字根排列可選。  
**Flex**：預設清楚；混打／Shift／ASCII／排序等**全部可設定改**（`docs/CONFIG.md`）。

## English (short)

Open-source Chinese IME on **librime** (BSD). Linux-first (Fcitx5 + fcitx5-rime). Primary: **Sucheng/Quick**, then **Jyutping with tones** (`jyut6`, `nei5`). Default mixed input: **uppercase Latin / email / URL inline without switching** to ASCII mode; Shift/`ascii_mode` remain optional and configurable. Candidate page defaults to **9** (select keys 1–9), same as Windows Quick. Code: MIT; dictionaries keep upstream licenses (`NOTICE`).

## 點解用 RIME

見 `docs/ARCHITECTURE.md`：唔從零造引擎；schema 覆蓋形碼＋拼音；前端只做系統對接與 UX。Linux 選 **Fcitx5 + fcitx5-rime**（LGPL 系）。

## 目錄

| 路徑 | 說明 |
| --- | --- |
| `schemas/kinfx-quick/` | P0 速成 schema + 單字碼表（字頻權重／罕用字過濾） |
| `lexicon/` | 詞／四字帶／英詞（各自授權，見 `lexicon/NOTICE`，唔係 MIT） |
| `schemas/kinfx-jyutping/` | P1 粵拼（`jyut6ping3` 有聲調） |
| `schemas/examples/` | `*.custom.yaml.example`（Flex 設定） |
| `docs/` | ARCHITECTURE／LAYOUTS／STATUS／**CONFIG**／**WIN_QUICK_RANK**／**WIN_QUICK_SELECT**／**PHRASE_MIX**／**desktop-verify** |
| `scripts/` | 安裝、smoke、GUI checklist、重新生成碼表 |
| `tests/` | Headless smoke、混打驗收 |
| `third_party/rime-quick/` | 上游速成參考（LGPL-3） |

## Linux 安裝（有桌面）

```bash
# 依賴（Debian/Ubuntu 例）
sudo apt install fcitx5 fcitx5-rime librime-bin librime-plugin-lua \
  rime-data-cangjie5 rime-data-jyut6ping3 rime-essay rime-prelude rime-data-luna-pinyin

# 安裝本專案 schema
./scripts/install-linux.sh

# Fcitx5 設定 → 加入「中州韻」→ 選「KINFX 速成」
```

預設資料目錄：`~/.local/share/fcitx5/rime/`。

### Fcitx5 與左 Shift

Fcitx5 預設常用 **LShift** 切輸入法／鍵盤，會**搶走** rime `inline_ascii`。  
**預設混打唔依賴呢個鍵**：同一輸入流打大寫英文即可（例：`今日用 API 測試`）。  
若要 rime 食到 Shift：用 `fcitx5-configtool` 改綁定，或見 `docs/CONFIG.md`。

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

桌面 checklist（**候選窗視覺需顯示器**）：`docs/desktop-verify.md`、`./scripts/verify-gui-mixed.sh`。

## 候選

每頁 **9** 個、**直列**、選字鍵 **1–9**。**空白翻頁**，**Enter／1–9 選焦點**，**Tab 展開**多欄，多頁碼有「常用熱門」環頁。無候選窗時空白仍然上屏（`好API`）。詳見 `docs/WIN_QUICK_SELECT.md`。頭頁對照：`docs/WIN_QUICK_RANK.md`。視窗預設 **跟游標、開喺下方、貼邊自動翻**。直列同展開格仔嘅目測標 **需顯示器**。見 `docs/ARCHITECTURE.md` §4。Flex：`docs/CONFIG.md`。

## 排列

預設 **`win_quick`**。表：`docs/LAYOUTS.md`。

## 授權

- 本專案原創程式／文件：**MIT**（`LICENSE`）
- 詞庫／上游：見 `NOTICE` 同 `lexicon/NOTICE`（LGPL／CC BY／SCOWL 等）。`lexicon/` 唔係 MIT

## 狀態

見 `docs/STATUS.md`。
