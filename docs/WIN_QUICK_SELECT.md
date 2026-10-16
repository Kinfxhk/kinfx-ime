# Windows 速成選字（直列、翻頁、展開、常用熱門）

**產品預設**對齊 Windows 微軟速成（Win11 24H2 實測＋ Microsoft 繁體中文輸入法說明）。速成同粵拼同一套選字鍵。頭頁排序唔喺呢度改，見 `docs/WIN_QUICK_RANK.md`。

## 按鍵

| 鍵 | 有候選窗 | 無候選窗（例：混打 preedit「好API」） |
| --- | --- | --- |
| 空白 | **下一頁**（唔選第 1 個） | 確認上屏（`好API`） |
| Enter／數字 1–9 | **選焦點／對應位** | Enter 確認成文（唔會上屏原始 `vd`） |
| ← → | 上一頁／下一頁；Tab 展開後＝換欄 | 唔攔截 |
| Tab | 展開／收合多欄（當欄仍係 1–9） | 唔攔截 |

只有一頁嘅碼（例 `ix`）空白停喺嗰頁，唔會彈常用熱門，亦唔會把字打上去。

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

`has_menu` 先至把空白改成 `Page_Down`。無候選窗時空白落到 `express_editor` 嘅確認，所以 M0 混打唔使改鍵。

## 邊層做邊樣

| 行為 | 層 |
| --- | --- |
| 空白翻頁、左右換頁、Enter 確認 | schema `key_binder` + `editor`（無 Lua 都成立） |
| 直列 | **前端**。Fcitx5 classicui：`Vertical Candidate List=True`（`install-linux.sh` 寫入）。Squirrel／Weasel／ibus-rime：schema `style/horizontal: false`。librime 嘅 `_vertical` 係直書文字，**唔好**開，否則左右頁向會反。 |
| Tab 展開 4×9 | Lua。`page_size` 維持 9，數字鍵仍然只標當欄。其餘欄寫喺候選註釋：`【係】 伱 僬 儵`（【】＝而家呢欄）。左右換欄＝翻一頁，註釋跟住移。真正四欄格仔係前端畫；而家 Fcitx5 直列加註釋係最小可用。 |
| 常用熱門環頁 | Lua filter。正常頁**原序通過**（碼表每頁都係 Windows 次序）。 |

依賴：`librime-plugin-lua`（`rime.lua` + `lua/win_quick.lua`）。插件未裝時，空白／Enter 兩行仍然生效；Tab 同熱門頁唔會。

## 常用熱門

多過一頁先至有呢頁（`of` 一類）。唔係硬編碼「第 9 頁」：有幾多頁正常候選，熱門頁就貼喺最後一頁後面，永遠剛好一頁（預設 9 格）。

循環：`… → 最後一頁正常候選 → 常用熱門 → 第 1 頁 → …`

- 第 1 頁按 **左** → 熱門頁
- 熱門頁再下一頁 → 第 1 頁
- 熱門頁按 **左** → 最後一頁正常候選

九格點填（先見先得，重複字去掉）：

1. librime user dict（讀到先用；權重高嘅優先）
2. 今次選過嘅字（`kinfx_win_history.tsv`，選字當下寫低，避免同 table translator 搶開 userdb）
3. 唔夠就用正常候選由頭填（♥熱）。未選過字時呢幾格同 Win 頭頁一樣，靠 ♥ 同提示分辨；呢個填補唔會改寫正常第 1 頁

註釋：`♥常` 歷史，`♥熱` 填補。Preedit 尾加 `〔♥常用熱門〕`。未選過字時，熱門頁頭幾個會同第 1 頁一樣，靠 ♥ 同提示分辨；選過第 2 頁嘅字之後，嗰個字會排到熱門頁第 1 格。

`menu/page_down_cycle` 保持 `false`。開咗會喺最後一頁直接跳返第 1 頁，跳過熱門頁。

## 唔做呢輪

- 上屏之後嘅 Windows「關聯詞」窗（Shift+數字揀熟／雅）
- M5 小寫英文而家喺詞庫通道做（`docs/PHRASE_MIX.md`）；選字鍵唔改

## Headless

`./scripts/smoke-linux.sh` 斷言：`vd`+空白唔上屏「好」、空白再 Enter 上屏第 2 頁第 1 個（本碼表係「樂」，唔係原始 `vd`）、Enter 上屏「好」、`of` 第 1 頁係「伙」、左右同空白環到熱門頁再返第 1 頁、Tab 後註釋有【】而且 `page_size` 仍係 9、`ix` 唔開熱門頁、選過嘅字以 ♥常 佔熱門頁第 1 格、`vdAPI` 空白同 Enter 都上屏「好API」。
