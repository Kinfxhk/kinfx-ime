# 中英混打（v0.5）

適用版本：v0.5.0。本文件說明細楷英文怎樣打，以及怎樣保證打中文的結果與 Windows 11 微軟速成（v0.4.1 行為）一樣。

## 用法

| 情況 | 打法 | 例子 |
| --- | --- | --- |
| 一般英文詞（3 個字母或以上） | 打完該詞，按空白 | `hello`␣ → `hello `、`startup`␣ → `startup ` |
| 英文詞後面跟標點 | 打完該詞，直接按標點 | `the`， → `the，` |
| 短詞（of、to、on、is…）或者空白不上屏的詞 | 打完該詞，按一下**左 Shift** | `of` 左 Shift → `of` |
| 中文後面接英文 | 照打 | `vd` `hello`␣ → `好hello ` |
| 大寫開頭、email、URL | 直接打 | `API`、`a@b.com`、`www.x.com` |

預編輯尾部有提示：`␣hello` 表示按空白會上屏英文；`⇧of` 表示要按左 Shift。`‹好›` 是已延遲、未上屏的中文頂字結果。

## 原理：延遲頂字

速成第 3 碼會頂字上屏。676 個兩字母組合之中有 658 個是速成碼，所以單靠字母分不出是中文還是英文。v0.5 的做法：

1. 打字母時，只要已輸入的字母仍是某個英文詞的開頭（SCOWL 詞表，用原生 `kinfx_en` 表查詢），Lua 就照 v0.4.1 的規則逐個字母處理，但頂字的中文先暫存，不立即上屏。輸入框、候選、詞語留鍵、翻頁全部與 v0.4.1 一樣。
2. 按空白或者標點，而字母是「空白安全」英文詞，又沒有中文詞語保留：上屏英文。
3. 按一下左 Shift：上屏已輸入的字母。
4. 其他任何鍵（數字、Enter、Esc、Backspace、第一個不再是英文開頭的字母）：先上屏暫存的中文，之後照 v0.4.1 處理，結果與 v0.4.1 逐字一樣。

中文詞語優先：例如 `abac` 保留「明顯」，按空白照樣翻頁，按逗號照樣出「明顯，」。英文在這個情況只可以用左 Shift 上屏。

## 空白安全詞表

`lexicon/en/kinfx_en_unsafe.txt` 由 `scripts/gen_english_space.py` 生成：按 essay-cantonese 字頻，估計用 Windows 方法打中文時，打出同一串字母再按空白的機會。超過每 1 萬字 0.01 次的詞列入不安全表（351 個，全部是 4 個字母或以下，例如 of、to、is、door、sure）。所有 2 個字母的詞都不安全，一律用左 Shift。

## 驗證

`tools/rimeh/compare.py` 用 rimeh（小狼毫的 rime.dll）逐鍵模擬 app 收到的文字，比較 smart 和 control（`english/mode: shift`，即 v0.4.1）：

- 全部 658 × 658 兩碼＋兩碼，加三段連打抽樣，每組帶結尾鍵（1、空白＋1、3、逗號、Enter、空白空白 2）。
- 只有一種差異算「設計內」：前面頂字照 Windows 上屏，後面 3 個字母或以上的空白安全英文詞遇空白／標點上屏成英文，而 v0.4.1 沒有用中文詞語保留這串字母。
- 其他差異和「中文改變」都必須為 0。數字見 `docs/eval/V05_COMPARE.md`。

## 開關（`kinfx_quick.custom.yaml`）

```yaml
patch:
  "english/mode": smart          # smart（v0.5）| shift（v0.4.1）| off（不處理英文）
  "english/space": safe          # safe（安全詞表）| long（只限 5 個字母或以上）| off
  "english/commit_key": Shift_L  # Linux 可改 Caps_Lock
```

## 已知限制

- 延遲頂字期間，中文會遲一兩個按鍵才上屏；有即時自動完成的輸入框（瀏覽器網址欄、終端機）會看到。
- Linux Fcitx5 預設用左 Shift 切換輸入法，左 Shift 單按可能送不到 librime；見 `docs/eval/LINUX_V05_CASES.md`。
- 英文詞表是 SCOWL；v0.5.4 加品牌／網站名表 `kinfx_names`（Wikidata）。兩個表都沒有的字，打到一半中斷後變成中文，用左 Shift 補救（下面）。

## 左 Shift 補救（v0.5.4）

打了 `english/rescue_min`（預設 2）個或以上字母仍是英文／品牌名開頭，之後那個字母使它不再是任何詞的開頭（`zd` → `zdr`）：

1. 照 v0.5.3 處理這個和之後的字母：頂字、詞語留鍵、新英文開頭全部一樣。
2. 這段期間要上屏的中文先暫存，不立即交給程式；字母另外記住（最多再 `rescue_extra` 個，預設 8）。
3. 按一下左 Shift：上屏記住的全部字母（`zdrav`）。如果 v0.5.3 那邊剛剛保留了一個完整英文詞（`vd` + `of` → 好of），就照 v0.5.3。
4. 按任何其他鍵（空白、數字、標點、Enter、Backspace、超過字母上限）：先將暫存的中文交給程式，之後照 v0.5.3。所以沒有按左 Shift 的話，最後打出來的字與 v0.5.3 逐字一樣，只是遲一兩個按鍵才出現。

`english/rescue_min: 0` 關（v0.5.3）。

## 設計研究

方案比較、Kaiboard 研究、觸發鍵選擇和模擬數據：`tools/design/V05_DESIGN_RESEARCH.md` 和 `tools/design/*.py`（研究用，需要 wordfreq，不隨產品發佈）。
