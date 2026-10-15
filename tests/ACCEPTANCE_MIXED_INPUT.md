# 驗收：中英混打（硬需求）

主測方案：**KINFX 速成**（`kinfx_quick`）。粵拼音複測。

| ID | 通過條件 | 最低棒 | 預設實作 |
| --- | --- | --- | --- |
| M1 | 中文狀態下一鍵進臨時／持久英文；半角字母數字可出 | 必須 | `Shift_L: inline_ascii`；`ascii_mode` |
| M2 | 組字緩衝未清時可插入英文片段（如選完「速」後打 `API` 再續中文），唔使切走成個輸入法 | 必須 | `inline_ascii` |
| M3 | 離開臨時英文後自動回速成／粵拼 | 必須 | RIME 預設行為 |
| M4 | Email／URL 唔被誤當形碼 | 應有 | `recognizer` patterns |
| M5 | 免切換自動判語 | 加分 | 後期自研 |

## 候選窗（並行 UX 硬偏好）

打字時候選窗 **唔遮 caret／當行**；預設 below + edge flip（見 ARCHITECTURE §4）。

## Headless

`./tests/run_smoke.sh` 驗證速成候選；混打 M1–M3 需有桌面 Fcitx5。
