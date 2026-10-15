# 桌面驗證（desktop-verify）

實際腳本路徑（以 repo 為準）：

| 用途 | 路徑 |
| --- | --- |
| Headless smoke | `scripts/smoke-linux.sh` → `tests/run_smoke.sh` |
| 安裝 schema | `scripts/install-linux.sh` |
| GUI／混打 checklist | `scripts/verify-gui-mixed.sh` |
| 設定 flex | `docs/CONFIG.md`、`schemas/examples/*.custom.yaml.example` |

## Headless（無芒亦可）

```bash
./scripts/smoke-linux.sh
```

預期：速成 `me→夏`（第 5 位以內）、`vd→好`（第 1）、`or→倉`（第 9 以內）；`hi` 第一頁 **9** 個候選；選字鍵 `1` 上屏「好」；零切換混打 `vd`+`API`→`好API`（`ascii_mode=0`）；粵拼有聲調而且每頁同樣 9（若系統有 `rime-data-jyut6ping3`）。

## GUI（需顯示器）

部機若 **冇接螢幕**，候選窗位置／「唔遮游標」**無法目測**——標為 **需顯示器**。插芒後：

```bash
./scripts/install-linux.sh
./scripts/verify-gui-mixed.sh
```

Checklist：

- [ ] Fcitx5 → 中州韻 → **KINFX 速成**
- [ ] **零切換**：同一輸入流「今日用 API 測試」（大寫 API；唔按切英文）
- [ ] 可選：Shift inline_ascii（若 Fcitx5 未搶 LShift）
- [ ] 粵拼：`nei5`／`ngo5`／`jyut6`
- [ ] **候選每頁 9**、選字鍵 1–9（`me` 見「夏」、`or` 見「倉」，唔使翻頁）
- [ ] **候選窗視覺**（需顯示器）：編輯器頂／中／底行各打兩碼，核對 below＋edge flip

## Fcitx5 LShift

見 `docs/CONFIG.md`：預設混打**唔依賴** LShift；系統搶鍵時改用大寫拉丁或改綁定。
