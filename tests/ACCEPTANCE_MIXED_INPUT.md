# 驗收：中英混打（硬需求）

主測方案：**KINFX 速成**（`kinfx_quick`）。粵拼音複測。設定 flex：`docs/CONFIG.md`。

| ID | 通過條件 | 最低棒 | 預設實作 |
| --- | --- | --- | --- |
| M0 | **全程零切換**夾英文（例「今日用 API 測試」）；`ascii_mode` 保持關閉 | **必須** | `recognizer` `uppercase`／email／url |
| M1 | 可選：一鍵臨時／持久英文（Shift／ascii_mode） | 可選 | `Shift_L: inline_ascii`；`Control+Shift+2` toggle（**可改**） |
| M2 | 組字緩衝未清時可插入英文片段（如 `vd` 後打 `API`→`好API`） | 必須 | 同上 uppercase 路徑 |
| M3 | 可選離開臨時英文後回速成 | 可選 | RIME inline_ascii 行為 |
| M4 | Email／URL 唔被誤當形碼 | 應有 | `recognizer` patterns |
| M5 | 免切換自動判語（小寫英文） | 加分 | 後期（本版未做；見 STATUS） |
| P9 | 候選每頁 **9**、選字鍵 1–9；`me`→夏喺頭 5、`or`→倉喺頭 9 | **必須** | `menu/page_size: 9`；排序見 `docs/WIN_QUICK_RANK.md` |

## Flex

唔寫死單一模式：可用 `kinfx_quick.custom.yaml` 改混打策略、Shift／ASCII、排序（見 `schemas/examples/`）。

## Headless

`./scripts/smoke-linux.sh`（或 `./tests/run_smoke.sh`）含 M0／M2、每頁 9、以及夏／倉／我／時順位。GUI 視覺：`docs/desktop-verify.md`（**需顯示器**）。

M5（小寫英文 melt_eng）本版未入場。英文次翻譯器嘅 quality 係 `exp(weight) + initial_quality`，詞表權重未校准之前會打亂速成頭頁；留待下一版獨立做，中文頭頁優先。
