# 中英混打（v0.5）

適用版本：v0.5.0。本文件說明細楷英文點樣打，以及點樣保證打中文嘅結果同 Windows 11 微軟速成（v0.4.1 行為）一樣。

## 用法

| 情況 | 打法 | 例子 |
| --- | --- | --- |
| 一般英文詞（3 個字母或以上） | 打完個詞，撳空白 | `hello`␣ → `hello `、`startup`␣ → `startup ` |
| 英文詞後面跟標點 | 打完個詞，直接撳標點 | `the`， → `the，` |
| 短詞（of、to、on、is…）或者空白唔上屏嘅詞 | 打完個詞，單撳一下**左 Shift** | `of` 左 Shift → `of` |
| 中文後面接英文 | 照打 | `vd` `hello`␣ → `好hello ` |
| 大寫開頭、email、URL | 直接打 | `API`、`a@b.com`、`www.x.com` |

預編輯尾部有提示：`␣hello` 表示撳空白會上屏英文；`⇧of` 表示要撳左 Shift。`‹好›` 係延遲咗、未上屏嘅中文頂字結果。

## 原理：延遲頂字

速成第 3 碼會頂字上屏。676 個兩字母組合入面有 658 個係速成碼，所以單靠字母分唔到中定英。v0.5 嘅做法：

1. 打字母時，只要打過嘅字母仲係某個英文詞嘅開頭（SCOWL 詞表，用原生 `kinfx_en` 表查詢），Lua 就照 v0.4.1 嘅規則逐粒處理，但係頂字嘅中文先擺住，唔即刻上屏。輸入框、候選、詞語留鍵、翻頁全部同 v0.4.1 一樣。
2. 撳空白或者標點，而字母係「空白安全」英文詞，又冇中文詞語留住：上屏英文。
3. 單撳左 Shift：上屏打過嘅字母。
4. 其他任何鍵（數字、Enter、Esc、Backspace、第一個唔再係英文開頭嘅字母）：先上屏擺住嘅中文，之後照 v0.4.1 處理，結果同 v0.4.1 逐字一樣。

中文詞語優先：例如 `abac` 留住「明顯」，撳空白照樣翻頁，撳逗號照樣出「明顯，」。英文喺呢個情況只可以用左 Shift 上屏。

## 空白安全詞表

`lexicon/en/kinfx_en_unsafe.txt` 由 `scripts/gen_english_space.py` 生成：按 essay-cantonese 字頻，估計用 Windows 方法打中文時，打出同一串字母再撳空白嘅機會。超過每 1 萬字 0.01 次嘅詞列入不安全表（351 個，全部係 4 個字母或以下，例如 of、to、is、door、sure）。所有 2 個字母嘅詞都唔安全，一律用左 Shift。

## 驗證

`tools/rimeh/compare.py` 用 rimeh（小狼毫嘅 rime.dll）逐鍵模擬 app 收到嘅文字，比較 smart 同 control（`english/mode: shift`，即 v0.4.1）：

- 全部 658 × 658 兩碼＋兩碼，加三段連打抽樣，每組帶結尾鍵（1、空白＋1、3、逗號、Enter、空白空白 2）。
- 只有一種差異算「設計內」：前面頂字照 Windows 上屏，後面 3 個字母或以上嘅空白安全英文詞遇空白／標點上屏成英文，而 v0.4.1 冇用中文詞語留住呢串字母。
- 其他差異同「中文改變」都必須為 0。數字見 `docs/eval/V05_COMPARE.md`。

## 開關（`kinfx_quick.custom.yaml`）

```yaml
patch:
  "english/mode": smart          # smart（v0.5）| shift（v0.4.1）| off（唔處理英文）
  "english/space": safe          # safe（安全詞表）| long（只限 5 個字母或以上）| off
  "english/commit_key": Shift_L  # Linux 可改 Caps_Lock
```

## 已知限制

- 延遲頂字期間，中文會遲一兩粒鍵先上屏；有即時自動完成嘅輸入框（瀏覽器網址欄、終端機）會睇到。
- Linux Fcitx5 預設用左 Shift 切輸入法，左 Shift 單撳可能去唔到 librime；見 `docs/eval/LINUX_V05_CASES.md`。
- 英文詞表係 SCOWL；v0.5.4 加品牌／網站名表 `kinfx_names`（Wikidata）。兩個表都冇嘅字，打到一半斷咗做中文，用左 Shift 補救（下面）。

## 左 Shift 補救（v0.5.4）

打咗 `english/rescue_min`（預設 2）個或以上字母仲係英文／品牌名開頭，之後嗰粒字母令佢唔再係任何詞開頭（`zd` → `zdr`）：

1. 照 v0.5.3 處理呢粒同之後嘅字母：頂字、詞語留鍵、新英文開頭全部一樣。
2. 呢段期間要上屏嘅中文先擺住，唔即刻交俾程式；字母另外記住（最多再 `rescue_extra` 粒，預設 8）。
3. 撳一下左 Shift：上屏記住嘅全部字母（`zdrav`）。如果 v0.5.3 嗰邊啱啱留住一個完整英文詞（`vd` + `of` → 好of），就照 v0.5.3。
4. 撳任何其他鍵（空白、數字、標點、Enter、Backspace、超過字母上限）：先將擺住嘅中文交俾程式，之後照 v0.5.3。所以冇撳左 Shift 嘅話，最後打出嚟嘅字同 v0.5.3 逐字一樣，只係遲一兩粒鍵先出。

`english/rescue_min: 0` 關（v0.5.3）。

## 設計研究

方案比較、Kaiboard 研究、觸發鍵選擇同模擬數據：`tools/design/V05_DESIGN_RESEARCH.md` 同 `tools/design/*.py`（研究用，需要 wordfreq，唔隨產品發佈）。
