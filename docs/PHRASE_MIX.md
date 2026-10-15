# 詞／成語／英詞聯想（phrase-mix）

**基礎**：v0.2.0 選字（每頁 9、直列、空白翻頁、Enter 確認）唔改。  
**建議標籤**：v0.3.0（本分支未打 tag）。

## 三條通道

同一段小寫拉丁，候選按 quality 合併：

| 順序 | 通道 | 幾時出 |
| --- | --- | --- |
| 1 | 中文詞，全碼 | 輸入等於詞庫連碼（`ofca`→無錯） |
| 2 | 中文詞，末碼前綴 | 輸入係連碼前綴而且長度 ≥ 3（`ofc`→無錯，註釋 `of+ca`） |
| 3 | 單字 | 現行速成碼表（`me`／`or`／`of` 頭頁） |
| 4 | 英詞 | 長度 ≥ 4 嘅前綴，或長度 3 嘅詞典全中 |

英詞 quality 低過中文詞。`me`／`or`／`of`（以及所有 1–2 碼）**唔出英詞**。

## 點解唔爆

`scripts/gen_quick_phrases.py` 掃 `kinfx_quick.dict.yaml`，每個字只取**最高權重嗰一個**速成碼，再把詞庫入面嘅詞串起來。唔會對 `of` × `c*` 做笛卡爾積。字唔喺碼表就丟棄。連碼短過 4 嘅詞唔收，避免兩碼短碼被詞條精确命中。

運行時 Lua 讀詞表（按碼二分），最多 `phrase_mix/top_k`（預設 12）條。`of`／`me`／`or` 長度係 2，翻譯器直接返回，頭頁排序同 v0.2.0 一樣。

`max_code_length: 2` 原本會喺第三個字母**頂字**（`of`+`c` 會先確認「係」）。`phrase_mix_keys` 喺呢個字母仍然續到詞庫碼或者英詞時，把字母拼入同一段，先至查得到 `ofc`→無錯。續唔到詞庫嘅第三個字母（例如 `vdz`）仍然頂字，上屏係「好」。拼埋之後預編輯顯示拉丁碼（`ofc`），因為字表嘅字根 `xlit` 只改寫有單字命中嘅兩碼。

## 詞庫同授權

獨立目錄 `lexicon/`，**唔係 MIT**。見 `lexicon/NOTICE`。

| 檔 | 內容 | 授權 |
| --- | --- | --- |
| `lexicon/hk/kinfx_hk_words.dict.yaml` | essay-cantonese 2／3／5 字 | 詞條 CC BY 4.0；速成碼 LGPL-3.0 |
| `lexicon/hk/kinfx_hk_idioms.dict.yaml` | 四字帶（成語同其他四字詞） | 同上 |
| `lexicon/en/kinfx_en.dict.yaml` | SCOWL（Debian `wamerican`）+ `extras.tsv` 嘅 Gmail／GMAIL | SCOWL 許可（Kevin Atkinson）；見 NOTICE |

冇打入 GPL-3 rime-ice。`en_spacer` 唔開。大寫拉丁仍然走 recognizer 零切換（M0），`GMAI` 唔會變候選。

## 英詞

`schemas/lua/melt_eng.lua`。`gmai` 係 `gmail` 嘅前綴（長度 4），所以抬 `Gmail`／`GMAIL`。長度 3 只抬詞典全中，唔做前綴。

## 重新生成

```bash
python3 scripts/gen_quick_phrases.py
```

需要系統有 `essay-cantonese.txt`（`rime-data-jyut6ping3`）同 `/usr/share/dict/words`（`wamerican`）。生成器會檢查 `無錯` 碼係 `ofca`，而且 `ofc`／`ofca` 都排到。

## 驗收

`./scripts/smoke-linux.sh`：`ofc`→無錯、`ofca`→無錯且排名不高過 `ofc`、數字鍵上屏係個詞而唔係原碼；`gmai` 第一頁有 Gmail 或 GMAIL；`me`／`or`／`of` 見唔到對應英詞，`of` 第 1 仍係「係」。空白翻頁／Enter 確認／每頁 9 同 v0.2.0 一齊跑。
