# 驗收：中英混打（硬需求）

主測方案：**KINFX 中英混打輸入法 · 速成**（`schema_id`：`kinfx_quick`）。粵拼選單係「KINFX 中英混打輸入法 · 粵拼」（`kinfx_jyutping`）。設定 flex：`docs/CONFIG.md`。

| ID | 通過條件 | 最低棒 | 預設實作 |
| --- | --- | --- | --- |
| M0 | **全程零切換**夾英文（例「今日用 API 測試」）；`ascii_mode` 保持關閉 | **必須** | `recognizer` `uppercase`／email／url |
| M1 | 可選：一鍵臨時／持久英文（Shift／ascii_mode） | 可選 | `Shift_L: inline_ascii`；`Control+Shift+2` toggle（**可改**） |
| M2 | 組字緩衝未清時可插入英文片段（如 `vd` 後打 `API`→`好API`） | 必須 | 同上 uppercase 路徑 |
| M3 | 可選離開臨時英文後回速成 | 可選 | RIME inline_ascii 行為 |
| M4 | Email／URL 唔被誤當形碼 | 應有 | `recognizer` patterns |
| M5 | 小寫英詞前綴：`gmai`→`Gmail`／`GMAIL`；`me`／`or`／`of` 英詞唔搶 | **必須** | `melt_eng` + `lexicon/en`（SCOWL）。`len≥4` 或長度 3 全中先抬。見 `docs/PHRASE_MIX.md` |
| P9 | 候選每頁 **9**、選字鍵 1–9；頭頁跟 Windows 速成頭 9（`hi` 凡第 1、`me` 夏第 5；倉唔喺 `or` 頭頁） | **必須** | `menu/page_size: 9`；排序見 `docs/WIN_QUICK_RANK.md` |
| W1 | `ofc`→無錯（末碼前綴）；`ofca`→無錯且排名不高過 `ofc`；數字鍵上屏係個詞 | **必須** | 詞庫連碼，唔笛卡爾。`phrase_mix` 只喺長度 ≥ 3 出詞 |
| K1 | 有候選窗時 **空白＝翻頁**（`vd`+空白唔上屏「好」） | **必須** | `key_binder` `space → Page_Down` when `has_menu` |
| K2 | **Enter＝焦點候選**（`vd`+Enter 上屏「好」，唔係 `vd`）；空白後 Enter 上屏**當頁**第 1 個 | **必須** | `editor/bindings/Return: confirm` |
| K3 | **無候選窗**時空白／Enter 仍上屏成文（`vdAPI` → `好API`） | **必須** | `has_menu` 先翻頁；confirm 喺無選單時退回 Commit |
| K4 | 直列；Tab 展開當欄 1–9；左右換頁／欄；多頁碼有 9 格「常用熱門」環頁（第 1 頁按左入熱門頁） | **必須** | 見 `docs/WIN_QUICK_SELECT.md` |

## Flex

唔寫死單一模式：可用 `kinfx_quick.custom.yaml` 改混打策略、Shift／ASCII、排序（見 `schemas/examples/`）。

## Headless

`./scripts/smoke-linux.sh`（或 `./tests/run_smoke.sh`）含 M0／M2、每頁 9、Windows 頭 9 次序、K1–K4（空白翻頁、Enter 選焦點、`vdAPI`、熱門環頁、Tab 展開），以及 W1／M5（`ofc`／`ofca`／`gmai`、短碼英詞保護）。GUI 視覺：`docs/desktop-verify.md`（**直列同四欄格仔需顯示器**）。

選字預設可改：`win_quick/space_pages: false` 恢復空白選焦點。見 `docs/CONFIG.md`。上屏後關聯詞唔喺本驗收。

M5 用獨立 `lexicon/en`（SCOWL，唔係 rime-ice）。英詞 quality 低過中文詞帶；1–2 碼（包括 `me`／`or`／`of`）唔出英詞。大寫拉丁仍然係 M0 直出。
