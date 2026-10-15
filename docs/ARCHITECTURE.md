# KINFX IME — 架構（ARCHITECTURE）

**日期**：2026-10-15（Asia/Taipei）  
**對齊**：`/workspace/notes/open-source/2026-10-15/open-source-ime-feasibility.md`

## 1. 總覽

```
┌─────────────────────────────────────────────────────────┐
│  Platform frontends (thin)                              │
│  Linux: Fcitx5 + fcitx5-rime   macOS: Squirrel→自研殼   │
│  Win/Android/iOS: later                                 │
│  UX: candidate popup, key sounds, tray                  │
└──────────────────────────▲──────────────────────────────┘
                           │ Rime API / IPC
┌──────────────────────────┴──────────────────────────────┐
│  librime (BSD-3-Clause) — shared engine                 │
│  schema DSL · candidates · user dict · ascii_composer   │
└──────────────────────────▲──────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────┐
│  KINFX schemas (this repo)                              │
│  P0 kinfx_quick（速成）→ P1 kinfx_jyutping（粵拼）      │
│  later: 倉頡 / 注音 / 拼音                              │
│  Dicts: open-licensed only（見 NOTICE）                 │
└─────────────────────────────────────────────────────────┘
```

**點解用 RIME**：五種方案＋詞頻／用戶詞屬邏輯層；重寫引擎成本極高。平台差異集中在 IME API 與 UX（候選窗、按鍵聲）。

## 2. 方案優先序（硬）

| 序 | Schema ID | 名稱 | 狀態 |
| --- | --- | --- | --- |
| P0 | `kinfx_quick` | 速成（MS Quick／Windows 字根對齊） | MVP 主打 |
| P1 | `kinfx_jyutping` | 粵拼 | MVP 次打 |
| P2 | （待） | 倉頡五代 | 依賴同碼表源流 |
| P2 | （待） | 注音 | layout 見 LAYOUTS |
| P2 | （待） | 拼音 | luna 系 |

## 3. 中英混打（硬驗收）

Desktop 多數只「切中／英模式」≠ 組字途中夾英文。本專案：

| 層 | 做法 | 驗收 |
| --- | --- | --- |
| 現成（配置） | `ascii_composer` + `ascii_segmentor`；`Shift_L: inline_ascii` | M1–M3 |
| 輔助 | `recognizer` email／url／uppercase patterns | M4 |
| 後期 | 自動判語（打 `th`／`app` 自動英候選） | M5 加分 |

**速成特別風險**：首尾兩碼空間極密，英文字母易撞碼——**主測必須用速成**，唔好只測拼音。

詳見 `tests/ACCEPTANCE_MIXED_INPUT.md`。

## 4. 候選窗位置（硬 UX）

**原則：候選窗唔可以遮住正在打字嘅游標／當行視線。**

| 偏好 | 說明 |
| --- | --- |
| 預設 | **跟游標（follow caret）**；優先開喺 **caret 下方**（below） |
| 避擋 | 與 caret 垂直留 **≥ 2–4px gap**；水平以 caret 為錨，必要時微偏避免出屏 |
| 翻轉 | 靠近螢幕底邊 → **自動翻到 caret 上方**（above）；頂邊同理 |
| 唔做 | 固定螢幕角落、蓋住 preedit／當行文字（已知痛點，見 Fcitx issue 討論） |

**Linux（Fcitx5）**：

- 定位靠 application IM module 報 caret 座標；Wayland 下需 text-input／kimpanel／client-side popup（見 [Fcitx Wayland wiki](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)）。
- Classic UI／主題可調偏移；產品預設文件寫明「below + flip」。
- 驗收：在編輯器中行、底行、頂行各打速成兩碼，候選窗**唔遮** caret 同當行已上屏字。

**macOS（後期殼）**：IMK 候選窗同樣 follow-cursor；預設 below、edge flip；唔採用遮擋輸入行嘅「螢幕中央大窗」做預設。

## 5. Linux 部署路徑

1. 系統：`librime` + `fcitx5` + `fcitx5-rime` + 詞庫依賴（cangjie 源流／jyutping／essay／luna）。  
2. 本 repo：`scripts/install-linux.sh` → 複製 schema 到 `~/.local/share/fcitx5/rime/`（或 `~/.config/ibus/rime`）。  
3. `rime_deployer` 編譯；Fcitx5 加「中州韻」後選 **KINFX 速成**。  
4. Headless box：用 `tests/rime_smoke` 驗證候選（無 GUI）。

## 6. macOS／其他

- 短期：Squirrel 載入同一套 schema 驗證。  
- 產品：自研／MIT 殼鏈 librime（避 GPL 前端鎖死）。  
- Windows／移動：後期；Weasel GPL 慎用。

## 7. 授權分層

| 層 | 授權 |
| --- | --- |
| 本 repo 原創碼／文件 | MIT |
| librime | BSD-3 |
| rime-quick／cangjie／essay 等碼表 | LGPL-3 等（NOTICE） |
| 粵拼資料 | 多為 CC BY；maps 或 ODbL——發佈前記署名 |
| fcitx5-rime | LGPL-2.1+ |

## English

Shared **librime** engine + thin frontends; schemas prioritize **Sucheng → Jyutping**. Hard acceptances: **CJK+Latin mixed input** (`inline_ascii`) and **candidate popup must not cover the caret** (below-first, edge flip, follow-cursor).
