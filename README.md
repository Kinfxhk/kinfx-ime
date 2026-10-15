# KINFX IME

開源中文輸入法專案（繁體／香港優先）——以 **librime** 為共用引擎，Linux 先做，macOS 次之，其後 Windows／Android／iOS。

**方案優先**：**速成（做到最好）→ 粵拼 → 倉頡／注音／拼音**  
**硬需求**：中英混打、候選窗**唔遮游標**、Windows 慣用字根排列可選。

## English (short)

Open-source Chinese IME built on **librime** (BSD). Linux-first (Fcitx5 + fcitx5-rime). Primary schema: **Sucheng/Quick** (Microsoft Quick–aligned radicals), then **Jyutping**. Hard acceptances: **CJK+Latin mixed input** (`ascii_composer` / `inline_ascii`) and **candidate popup must not cover the caret** (below-first, edge flip). Code: MIT; dictionaries keep upstream licenses (see `NOTICE`).

## 點解用 RIME

見可行性筆記與 `docs/ARCHITECTURE.md`：唔從零造引擎；schema 覆蓋形碼＋拼音；前端只做系統對接與 UX。Linux 選 **Fcitx5 + fcitx5-rime**（LGPL 系），避免 ibus-rime GPL 鎖死產品殼。

## 目錄

| 路徑 | 說明 |
| --- | --- |
| `schemas/kinfx-quick/` | P0 速成 schema + 生成碼表 |
| `schemas/kinfx-jyutping/` | P1 粵拼 overlay |
| `docs/` | ARCHITECTURE / LAYOUTS / STATUS |
| `scripts/` | 安裝、重新生成碼表 |
| `tests/` | Headless smoke、混打驗收 |
| `third_party/rime-quick/` | 上游速成參考（LGPL-3） |

## Linux 安裝（有桌面）

```bash
# 依賴（Debian/Ubuntu 例）
sudo apt install fcitx5 fcitx5-rime librime-bin \
  rime-data-cangjie5 librime-data-jyutping rime-essay rime-prelude rime-data-luna-pinyin

# 安裝本專案 schema
./scripts/install-linux.sh

# Fcitx5 設定 → 加入「中州韻」→ 選「KINFX 速成」
# 重新部署：於候選列按 F4／或 rime_deployer
```

預設資料目錄：`~/.local/share/fcitx5/rime/`（腳本可改）。

## Headless 測試（本開發機）

無 GUI 時驗證引擎候選：

```bash
./tests/run_smoke.sh
```

預期：編譯 schema 後，輸入速成碼 `me` 候選含「夏」等；`vd` 含「好」。

## 中英混打（速成主測）

| ID | 條件 |
| --- | --- |
| M1 | 中文狀態下一鍵進臨時／持久英文（預設左 Shift = `inline_ascii`） |
| M2 | 組字途中可夾英文片段，唔使切走成個輸入法 |
| M3 | 離開臨時英文後自動回速成 |
| M4 | email／URL 唔被當形碼食掉 |
| M5 | 自動判語（後期） |

清單：`tests/ACCEPTANCE_MIXED_INPUT.md`。

## 候選窗

預設 **跟游標、開喺下方、貼邊自動翻上／下**，唔遮 caret。詳見 `docs/ARCHITECTURE.md` §4、`docs/LAYOUTS.md` §4。

## 排列

預設 **`win_quick`**（微軟速成字根）。`classic_common` 目前同鍵位。表：`docs/LAYOUTS.md`。

## 授權

- 本專案原創程式／文件：**MIT**（`LICENSE`）
- 詞庫／上游方案：見 `NOTICE`（LGPL／CC BY／ODbL 等）——**唔發明專有詞庫**

## 狀態

見 `docs/STATUS.md`。有可打嘅桌面 build 會再通知。

## 參考

- 可行性：`/workspace/notes/open-source/2026-10-15/open-source-ime-feasibility.md`
- [librime](https://github.com/rime/librime) · [rime-quick](https://github.com/rime/rime-quick) · [fcitx5-rime](https://github.com/fcitx/fcitx5-rime)
