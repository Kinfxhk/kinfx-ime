# 桌面驗證（desktop-verify）

實際腳本路徑（以 repo 為準）：

| 用途 | 路徑 |
| --- | --- |
| Headless smoke | `scripts/smoke-linux.sh` → `tests/run_smoke.sh` |
| 安裝 schema | `scripts/install-linux.sh` |
| GUI／混打 checklist | `scripts/verify-gui-mixed.sh` |
| 設定 flex | `docs/CONFIG.md`、`schemas/examples/*.custom.yaml.example` |

## Headless（沒有顯示器亦可）

```bash
./scripts/smoke-linux.sh
```

預期：速成頭頁跟 Windows（`vd→好` 第 1、`hi→凡` 第 1、`我` 第 7、`me→夏` 第 5、`of→伙` 第 1、`係` 第 3；`or` 頭頁沒有「倉」）；`hi` 第一頁 **9** 個候選；選字鍵 `1` 上屏「好」；`vd`+空白不上屏「好」、再 Enter 上屏第 2 頁第 1 個（「樂」）；`vd`+Enter 上屏「好」；零切換混打 `vd`+`API`→`好API`（空白和 Enter，`ascii_mode=0`）；`of` 第 1 頁按左入常用熱門，再按空白回到第 1 頁「伙」；`ofc`／`ofca`→無錯、`gmai`→Gmail，而 `me`／`or`／`of` 頭頁仍然是中文；粵拼有聲調而且每頁同樣 9（若系統有 `rime-data-jyut6ping3`）。

## GUI（需顯示器）

若電腦 **沒有接上螢幕**，候選窗位置／「不遮游標」**無法目測**——標為 **需顯示器**。接上顯示器後：

```bash
./scripts/install-linux.sh
./scripts/verify-gui-mixed.sh
```

Checklist：

- [ ] Fcitx5 → 中州韻 → **KINFX 中英混打輸入法 · 速成**（`kinfx_quick`）
- [ ] **零切換**：同一輸入流「今日用 API 測試」（大寫 API；不切換英文）
- [ ] **細楷英文詞**：左 Shift → `startup` → 左 Shift → `vd` 1，結果「startup好」（Windows：rime inline_ascii；Linux：Fcitx5 切換輸入法，每詞 2 下）
- [ ] Windows：打到一半按 Shift：`st` 左 Shift `artup` Enter → startup
- [ ] 粵拼：`nei5`／`ngo5`／`jyut6`
- [ ] **候選每頁 9**、選字鍵 1–9（`hi` 第 1 是「凡」、`me` 第 5 是「夏」；「倉」不在 `or` 頭頁）
- [ ] **候選窗視覺**（需顯示器）：編輯器頂／中／底行各打兩碼，核對 below＋edge flip
- [ ] **直列**（需顯示器）：9 個候選直排。Fcitx5 `Vertical Candidate List=True`
- [ ] **空白翻頁**、**Enter／1–9 選字**（`vd`：空白不上屏「好」；Enter 上屏「好」）
- [ ] **Tab 展開**（需顯示器看版面）：註釋出現一行四格，【】是當欄；左右換欄。Headless 已查註釋和 `page_size=9`
- [ ] **常用熱門**（`of` 第 1 頁按左）：preedit 有「常用熱門」，9 格，♥常／♥熱；再翻頁回到第 1 頁

## Fcitx5 LShift

Fcitx5 預設左 Shift 切換輸入法，短詞英文（`of` + 左 Shift）會失效。執行 `scripts/linux-free-left-shift.sh` 後重測：`of` + 左 Shift → of，輸入法不切換離開。不要用 Caps Lock 代替（XKB 會切換大寫）。
