# Windows 速成頭 9 對照

**產品預設**：每頁 **9** 個候選，選字鍵 **1–9**。速成（`kinfx_quick`）同粵拼（`kinfx_jyutping`）都寫 `menu/page_size: 9`。Fcitx5 classicui、Squirrel、Weasel 顯示 librime 交嚟嘅一頁，前端冇 page size 可以改成 5。`scripts/install-linux.sh` 亦把用戶 `default.yaml` 設成 9。

要改頁數先用 `schemas/examples/*.custom.yaml.example` 入面註解住嘅 `"menu/page_size": 5`。呢個係 Flex，產品預設仍然係 9。

## 排序點對齊

Windows 10「傳統速成」係一張固定序（公開重構見 `schemas/kinfx-quick/win_quick_top9.tsv`，只保留每碼頭 9 個字，唔係詞庫）。呢張表好多時把罕用字排頭（`hi` 第一係「凡」，「我」第 7；`me` 頭兩個係「汞」「歿」）。v0.1 GUI 驗收已經鎖定常用字頭位：`我@hi`、`時@ai`、`好@vd` 第 1。

所以 kinfx **唔複製**成張傳統序。權重仍然係 `essay.txt + 5× essay-cantonese.txt`，再加兩條規則（`scripts/gen_quick_dict.py`）：

1. **近頻**：兩個字都喺 Windows 頭 9，而且較重嗰個唔超過較輕嗰個嘅 1.15 倍，就跟 Windows 次序。重量級常用字（我、時、好、個、更）唔會被罕用字爬頭。
2. **指定頭頁**：`夏@me` 最高第 5（同傳統序第 5）；`倉@or` 最高第 9。傳統序把「倉」排第 22，第一頁睇唔到；v0.1 字頻又把它推到第 11。產品要求係第一頁有它。

低過權重 8000 嘅 Windows 頭頁字（例如「汞」「昤」）唔參與近頻，避免冷門字上第一頁。

Win11 24H2 微軟速成實測（2026-10-15）：`vd` 頭 9 尾二係 **網綜**，唔係較早公開重構入面嘅 **綑綵**。下表 `vd` 一行跟呢次實測。`schemas/kinfx-quick/win_quick_top9.tsv` 仍然係舊重構（近頻對齊用），**唔**因為呢個觀察重生成碼表，kinfx 頭頁維持字頻＋近頻（好她妹樂牀…）。「網」「綜」唔會因為更正對照表而爬上 kinfx 第一頁。

## 頭 9 對照

Windows 欄：`vd` 跟 Win11 24H2 實測（尾二網綜）；其餘碼仍係 `win_quick_top9.tsv` 嘅較早重構。kinfx 欄係本 repo 碼表第一頁（權重由高至低）。

| 碼 | Windows 頭 9 | kinfx 頭 9 |
| --- | --- | --- |
| `vd` | 好她妹紆巢媒彙網綜 | 好她妹樂牀巢欒姝孿 |
| `hi` | 凡么丟夙舟卵我私的 | 我的得等鬼射風凡簿 |
| `me` | 汞歿泵玻夏破球豉瑕 | 覆碌破球夏憂酸霞瓊 |
| `or` | 合何估佑伽伺佔佝含 | 個知估信含合佔何倉 |
| `ai` | 昤時閎閩閥曇旳昡戥 | 時閥閩旳戥曇閎闘昡 |
| `mk` | 天攻更玟玫政殃致敔 | 更敢天政硬攻雯爾致 |
| `of` | 伙你係偽氮焦無絛僚 | 係你無煲僞焦黛鴿尓 |
| `rr` | 呂呵咖咕品哈咯唁唔 | 唔嗰喎啊啱喊喀哈路 |
| `yr` | 占吝言迦迢迥迨站迴 | 話過高這站追言語調 |
| `go` | 坎走垓堤款塚壕垗欯 | 走款赱壕垓堟坎垗歖 |
| `an` | 門剔旯昑昲閌閅闁 | 門剔閌閅旯闁昑昲 |
| `ni` | 夕弘多兔弦虱附強蛋 | 多蛋強陰弦蟹觸兔夕 |
| `wm` | 國置疊畇罡罝罭黚翾 | 國疊置罡翾囸罝畳疂 |

## 關鍵字

| 字 | 碼 | Windows 傳統序 | kinfx | 說明 |
| --- | --- | --- | --- | --- |
| 好 | `vd` | 1 | 1 | 頭三位好她妹同 Windows 一致 |
| 我 | `hi` | 7 | 1 | 保留 v0.1 常用字頭位；「凡」仍喺第一頁（第 8） |
| 時 | `ai` | 2 | 1 | 傳統序第 1 係「昤」（權重低，唔上頁） |
| 夏 | `me` | 5 | 5 | v0.1 字頻係第 9；而家同 Windows 同位，第一頁選字鍵 5 |
| 倉 | `or` | 22 | 9 | 傳統序喺第三頁；產品把它留喺第一頁最後一格（「倍」順延到第 10） |
| 天 | `mk` | 1 | 3 | Microsoft Learn 例子用 `MK` 再按 1 選「天」。kinfx 第 1、2 係更重嘅「更」「敢」，「天」仍係選字鍵 3 |
| 係 | `of` | 3 | 1 | 粵語字頻頭位；「你」第 2，同 Windows 第 2 一致 |
| 唔 | `rr` | 9 | 1 | 粵語字頻；「路」仍喺第一頁第 9 |

## 重新生成

```bash
python3 scripts/gen_quick_dict.py
```

需要系統有 `cangjie5.dict.yaml`、`essay.txt`、`essay-cantonese.txt`（Debian：`rime-data-cangjie5`、`rime-essay`、`rime-data-jyut6ping3`）。腳本會檢查夏／倉／我／時／好嘅順位，唔達標就退出。

Headless：`./scripts/smoke-linux.sh` 斷言 `page_size=9`、`hi` 第一頁 9 個、選字鍵 `1` 上屏「好」，以及上表嘅順位上限。
