# Windows 速成頭 9 對照

**產品預設**：每頁 **9** 個候選，選字鍵 **1–9**。速成（`kinfx_quick`）同粵拼（`kinfx_jyutping`）都寫 `menu/page_size: 9`。Fcitx5 classicui、Squirrel、Weasel 顯示 librime 交嚟嘅一頁，前端冇 page size 可以改成 5。`scripts/install-linux.sh` 亦把用戶 `default.yaml` 設成 9。

要改頁數先用 `schemas/examples/*.custom.yaml.example` 入面註解住嘅 `"menu/page_size": 5`。呢個係 Flex，產品預設仍然係 9。

## 兩頁分工

正常第 1 頁同「常用熱門」分開。常用字**唔再**硬抬去蓋過微軟頭頁。

| 頁 | 點入 | 次序 |
| --- | --- | --- |
| 第 1 頁 | 打完碼 | **Microsoft 速成頭 9**。碼表權重釘死，運行時唔加逐鍵 filter |
| 常用熱門 | 第 1 頁按 **左** | 現有 `schemas/lua/win_quick.lua` 環頁，剛好 9 格 |

左鍵環頁先見選過嘅字（♥常），再係 user dict（而家 schema 預設關），唔夠先用正常候選由頭填（♥熱）。未選過字時，熱門頁會暫時同 Win 頭 9 一樣，靠 ♥ 同 `〔♥常用熱門〕` 分辨；呢個填補**唔改**正常第 1 頁。選過第 2 頁嘅字之後，嗰個字先至排到熱門頁第 1 格。

`translator/enable_user_dict` 預設 **關**。開返學頻會把常用字插返正常頭頁，同呢個分工衝突。要熟字就用左鍵嗰頁。

頁面大小、空白翻頁、Enter 確認、Tab 展開、混打／英詞都唔改。

## 排序

`scripts/gen_quick_dict.py` 底權重仍然係 `essay.txt + 5× essay-cantonese.txt`。有 Windows 頭頁嘅碼，再把 `schemas/kinfx-quick/win_quick_top9.tsv` 嗰幾個字（最多 9 個）按表嘅次序放喺第 1 頁前面；其餘字跟字頻排後面。權重只喺生成碼表時改，打字時 `win_quick.lua` 正常頁原序通過。

頭頁次序唔喺每次按鍵計。冇新 filter、冇掃成張碼表、冇逐鍵重排 Lua。`win_quick.lua` 仍然只喺左鍵環頁同 Tab 展開先改顯示；歷史只喺選字鍵（1–9／Enter）記一格，字母鍵唔入呢條路。

唔再做舊規則：近頻 1.15、冷門字下限、以及硬抬 `我@hi`／`係@of`／`唔@rr`／`時@ai` 去第 1。Windows 排第幾就第幾。

`vd` 跟 Win11 24H2 實測（2026-10-15），尾二係 **網綜**，唔係較早公開重構嘅 **綑綵**。TSV 同碼表用同一行。

`夏@me` 喺 Windows 第 5 位，所以頭頁第 5 仍然係夏。`倉@or` **唔喺** Windows 頭 9（傳統序約第 22）。頭頁跟 Win，倉唔留第 9 格；字仍然喺碼表後面，選過之後可以出現喺左鍵常用熱門。

## 頭 9 對照

kinfx 頭頁同 Windows 欄一樣。`an` 表入面得 8 個字，頭 8 位跟表。第 9 位唔係 Windows 頭頁字。

| 碼 | 頭 9（Windows = kinfx） |
| --- | --- |
| `vd` | 好她妹紆巢媒彙網綜 |
| `hi` | 凡么丟夙舟卵我私的 |
| `me` | 汞歿泵玻夏破球豉瑕 |
| `or` | 合何估佑伽伺佔佝含 |
| `ai` | 昤時閎閩閥曇旳昡戥 |
| `mk` | 天攻更玟玫政殃致敔 |
| `of` | 伙你係偽氮焦無絛僚 |
| `rr` | 呂呵咖咕品哈咯唁唔 |
| `yr` | 占吝言迦迢迥迨站迴 |
| `go` | 坎走垓堤款塚壕垗欯 |
| `an` | 門剔旯昑昲閌閅闁 |
| `ni` | 夕弘多兔弦虱附強蛋 |
| `wm` | 國置疊畇罡罝罭黚翾 |

## 關鍵字

| 字 | 碼 | 頭頁 | 說明 |
| --- | --- | --- | --- |
| 好 | `vd` | 1 | 同 Windows。第 2 頁第 1 個係「樂」 |
| 凡 | `hi` | 1 | 「我」喺第 7，唔再硬抬 |
| 我 | `hi` | 7 | |
| 昤 | `ai` | 1 | 「時」喺第 2 |
| 時 | `ai` | 2 | |
| 夏 | `me` | 5 | 跟 Windows 第 5 |
| 倉 | `or` | 唔喺頭 9 | 跟 Win，唔留第 9 格 |
| 天 | `mk` | 1 | Microsoft Learn 例子 `MK` 再按 1 |
| 伙 | `of` | 1 | 「係」喺第 3 |
| 係 | `of` | 3 | |
| 呂 | `rr` | 1 | 「唔」喺第 9 |
| 唔 | `rr` | 9 | |
| 網／綜 | `vd` | 8／9 | Win11 24H2。綜亦有 `vf` 讀音 |

## 重新生成

```bash
python3 scripts/gen_quick_dict.py
```

需要系統有 `cangjie5.dict.yaml`、`essay.txt`、`essay-cantonese.txt`（Debian：`rime-data-cangjie5`、`rime-essay`、`rime-data-jyut6ping3`）。腳本會檢查每個有 Windows 頭頁嘅碼，頭幾個字同表不一致就退出。

Headless：`./scripts/smoke-linux.sh` 斷言 `page_size=9`、上表頭頁次序、選字鍵 `1` 上屏「好」、`倉` 唔喺 `or` 頭頁，以及第 1 頁按左仍然開 9 格常用熱門。
