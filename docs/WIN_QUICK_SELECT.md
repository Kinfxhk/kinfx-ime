# Windows 速成選字（直列、翻頁、展開、常用熱門）

**產品預設**對齊 Windows 微軟速成（Win11 24H2 實測＋ Microsoft 繁體中文輸入法說明）。速成和粵拼同一套選字鍵。頭頁排序不在這裡改，見 `docs/WIN_QUICK_RANK.md`。

## 按鍵

| 鍵 | 有候選窗 | 無候選窗（例：混打 preedit「好API」） |
| --- | --- | --- |
| 空白 | **下一頁**（不選第 1 個） | 確認上屏（`好API`） |
| Enter／數字 1–9 | **選焦點／對應位** | Enter 確認組字結果（不會上屏原始 `vd`） |
| ← → | 上一頁／下一頁；Tab 展開後＝換欄 | 不攔截 |
| Tab | 展開／收合多欄（當欄仍是 1–9） | 不攔截 |

只有一頁的碼（例 `ix`）空白停在該頁，不會彈出常用熱門，也不會把字打上去。

Schema 兩行（lab 已對過 Windows；librime 預設相反：空白確認、Enter 原樣上屏）：

```yaml
key_binder:
  bindings:
    - { when: has_menu, accept: space, send: Page_Down }
    - { when: has_menu, accept: Right, send: Page_Down }
    - { when: has_menu, accept: Left, send: Page_Up }
editor:
  bindings:
    Return: confirm
```

`has_menu` 才把空白改成 `Page_Down`。無候選窗時空白落到 `express_editor` 的確認，所以 M0 混打不必改鍵。

## 哪一層做什麼

| 行為 | 層 |
| --- | --- |
| 空白翻頁、左右換頁、Enter 確認 | schema `key_binder` + `editor`（沒有 Lua 也成立） |
| 直列 | **前端**。Fcitx5 classicui：`Vertical Candidate List=True`（`install-linux.sh` 寫入）。Squirrel／Weasel／ibus-rime：schema `style/horizontal: false`。librime 的 `_vertical` 是直書文字，**不要**開，否則左右頁向會反。 |
| Tab 展開 4×9 | Lua。`page_size` 維持 9，數字鍵仍然只標當欄。其餘欄寫在候選註釋：`【係】 伱 僬 儵`（【】＝現在這一欄）。左右換欄＝翻一頁，註釋跟著移。真正的四欄格子由前端繪製；現在 Fcitx5 直列加註釋是最小可用。 |
| 常用熱門環頁 | Lua filter。正常頁**原序通過**（碼表每頁都是 Windows 次序）。 |

依賴：`librime-plugin-lua`（`rime.lua` + `lua/win_quick.lua`）。插件未裝時，空白／Enter 兩行仍然生效；Tab 和熱門頁不會。

## 常用熱門

超過一頁才有這一頁（`of` 一類）。不是硬編碼「第 9 頁」：有多少頁正常候選，熱門頁就貼在最後一頁後面，永遠剛好一頁（預設 9 格）。

循環：`… → 最後一頁正常候選 → 常用熱門 → 第 1 頁 → …`

- 第 1 頁按 **左** → 熱門頁
- 熱門頁再下一頁 → 第 1 頁
- 熱門頁按 **左** → 最後一頁正常候選

九格怎樣填（依出現次序，重複的字去掉）：

1. librime user dict（讀到才用；權重高的優先）
2. 這次選過的字（`kinfx_win_history.tsv`，選字當下寫下，避免與 table translator 搶開 userdb）
3. 不夠就用正常候選從頭填（♥熱）。未選過字時這幾格與 Win 頭頁一樣，靠 ♥ 和提示分辨；這個填補不會改寫正常第 1 頁

註釋：`♥常` 歷史，`♥熱` 填補。Preedit 尾加 `〔♥常用熱門〕`。未選過字時，熱門頁頭幾個會與第 1 頁一樣，靠 ♥ 和提示分辨；選過第 2 頁的字之後，那個字會排到熱門頁第 1 格。

`menu/page_down_cycle` 保持 `false`。開啟後會在最後一頁直接跳回第 1 頁，跳過熱門頁。

## 這一輪不做

- 上屏之後的 Windows「關聯詞」窗（Shift+數字選熟／雅）
- M5 小寫英文現在在詞庫通道處理（`docs/PHRASE_MIX.md`）；選字鍵不改

## Headless

`./scripts/smoke-linux.sh` 斷言：`vd`+空白不上屏「好」、空白再 Enter 上屏第 2 頁第 1 個（本碼表是「樂」，不是原始 `vd`）、Enter 上屏「好」、`of` 第 1 頁是「伙」、左右和空白環到熱門頁再回到第 1 頁、Tab 後註釋有【】而且 `page_size` 仍是 9、`ix` 不開熱門頁、選過的字以 ♥常 佔熱門頁第 1 格、`vdAPI` 空白和 Enter 都上屏「好API」。
