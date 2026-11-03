# 詞語、成語、英文詞（phrase-mix）

選字方式不變：每頁 9、直列、空白翻頁、Enter／1–9 選字。

## 原則：Windows 速成優先

Windows 微軟速成打第 3 個字母時，會將頭兩碼的第 1 個字上屏（頂字），再開始新碼。KINFX 預設照做，只有以下情況會**保留**該字母不上屏，讓你選詞：

| 鍵 | 何時保留 | 例 |
| --- | --- | --- |
| 第 3 碼 | 打出來是常用詞的頭 3 碼（詞頻 ≥ 19000），或者剛剛打完一個 3 碼詞（詞頻 ≥ 3000） | `ofc` → 人類、無錯…；`lwm` → 中國 |
| 第 4 碼 | 仍然是常用詞前綴，或者剛剛打完一個 4 碼詞（詞頻 ≥ 3000） | `ofca` → 無錯、`ofch` → 無錫 |
| 第 5 碼起 | 詞庫還有詞可以接下去 | 四字詞、成語 |
| 英文詞 | 輸入是 `lexicon/en/extras.tsv` 內的字的前綴 | `gmai` → Gmail |

詞庫沒有詞可以接下去，就照 Windows 做：每兩碼上屏第 1 個字，剩下的碼做新碼。例如 `ofcx` 會上屏「伙」，剩 `cx`；`vd` `of` `3` 會上屏「好係」，與 Windows 一樣。

規則清單在 `lexicon/hk/kinfx_capture.txt`，由 `scripts/gen_quick_phrases.py` 生成。

## 為什麼門檻是 19000／3000

`tools/rimeh/hold_harm_top.py` 計算全部 658 × 658 個「兩碼 + 兩碼」組合，假設用戶靠 Windows 頂字連打，統計有多少組會因為保留而改變結果：

| 方案 | 有變化的組合 | 按字頻加權 |
| --- | --- | --- |
| 第 4 碼都要過門檻（v0.4 採用） | 0.31% | 0.61% |
| 第 4 碼只要詞庫有就保留 | 1.71% | 5.6%（例：好同 → 好貼） |

有變化的組合，大部分是變好了，例如 上而 → **上面**、出而 → **出面**、左方 → **左邊**。

如果某個碼 Windows 頂字的結果本身就是一個詞，那個詞會排第 1。例如 `vdvd` 第 1 個是 **好好**，不是字頻較高的妹妹。

## 3 碼詞

v0.4 開始收錄 3 碼詞（1 碼字加 2 碼字），例如：

| 詞 | 碼 |
| --- | --- |
| 人類 | `o`+`fc` = `ofc` |
| 中國 | `l`+`wm` = `lwm` |
| 一個 | `m`+`or` = `mor` |
| 大家 | `k`+`jo` = `kjo` |

2 碼詞不收，因為會與 Windows 單字頁撞碼。

## 實作

詞庫是 librime 原生表，部署時編譯成 `.table.bin`：

- `table_translator@phrase`（`kinfx_quick_phrase`）
- `table_translator@english`（`kinfx_en`）

Lua（`schemas/lua/phrase_mix.lua`）只負責：

- 判斷是否保留按鍵
- 用 `Memory:dict_lookup` 查詞庫前綴
- 加 segment tag

所以兩碼的頭頁不會出詞。v0.3 在 Lua heap 載入大約 24 萬行詞庫，每個按鍵約 70 ms；v0.4 約 0.03–0.06 ms（rimeh 量度）。

## 詞庫和授權

`lexicon/` **不是 MIT**，見 `lexicon/NOTICE`。

| 檔 | 內容 | 授權 |
| --- | --- | --- |
| `lexicon/hk/kinfx_hk_words.dict.yaml` | essay-cantonese 2／3／5 字詞 | 詞條 CC BY 4.0；速成碼 LGPL-3.0 |
| `lexicon/hk/kinfx_hk_idioms.dict.yaml` | 四字詞 | 同上 |
| `lexicon/en/kinfx_en.dict.yaml` | SCOWL + `extras.tsv`（Gmail、scriptwriting、voiceover） | SCOWL 許可 |

## 重新生成

```bash
python3 scripts/gen_quick_phrases.py --essay-cantonese <essay-cantonese.txt>
```

生成器會檢查：

- `無錯` 的碼是 `ofca`
- `ofc`、`ofca`、`ofch` 都在保留清單內
