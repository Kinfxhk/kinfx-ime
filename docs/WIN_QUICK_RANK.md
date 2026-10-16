# Windows 速成排序（全表）

**產品預設**：每頁 **9** 個候選，選字鍵 **1–9**。速成（`kinfx_quick`）同粵拼（`kinfx_jyutping`）都寫 `menu/page_size: 9`。Weasel、Fcitx5、Squirrel 顯示 librime 交嚟嘅一頁。

## v0.4：每一頁都跟 Windows 11

v0.3 只係把頭 9 個字釘死，第 2 頁之後按字頻排，所以同 Windows 唔一樣。v0.4 改為**全表跟 Windows 11 Pro 微軟速成**。

| 項目 | 數字 |
| --- | --- |
| 實測碼數 | 664（658 個兩碼 + 6 個單碼） |
| 實測候選 | 24,073 個字 |
| 兩碼逐格比對 | 658／658 一致（`tools/rimeh/fullorder.sh`） |

來源：`schemas/kinfx-quick/ms_quick_order.tsv`。用 `tools/mscapture/ms_uiless.ps1` 喺 Windows 11 微軟速成（zh-TW）透過 TSF UILess 介面逐個碼讀出完整候選表。每個碼讀完按 Esc，冇上屏，所以微軟輸入法唔會因此學字。讀取時嘅設定係「固定候選字順序」關、Ext-A／B／HKSCS 關，即係 Windows 預設。

碼表 `kinfx_quick.dict.yaml` 用 `sort: original`，行序就係顯示次序：

1. 每個碼先放 Windows 嘅完整清單，原樣保留，連 丂／丄 呢類罕用部件都留。
2. 之後補 Windows 冇、但倉頡 5／rime-quick 補充表有嘅字（例如 㗎、𠻹、𨋢 等港字同 Ext-A／B），按 `essay.txt + 5× essay-cantonese.txt` 字頻排。Windows 唔顯示呢啲字，所以唔會郁到任何 Windows 格位。

單碼（`a`、`h`、`k`…）喺 Windows 要按空白先見到，所以用 `win_quick_top9.tsv` 補返。Windows 速成冇補全、冇造句，所以 v0.4 關咗 `enable_completion`／`enable_sentence`。打 `h` 只出「竹丿」，同 Windows 一樣。

## 對照（Windows 11 實測 = kinfx）

| 碼 | 第 1 頁 | 第 2 頁 |
| --- | --- | --- |
| `vd` | 好她妹紆巢媒彙綑綵 | 嫻槳樂繅孿姀孥姝婐 |
| `hi` | 凡么丟夙舟卵我私的 | 待禹風射特鬼得符舷 |
| `of` | 伙你係偽氮焦無絛僚 | 鴒繁鴿黛鯈鶴儻尒伓 |
| `me` | 汞歿泵玻夏破球豉瑕 | 碌酸憂豭璦霞覆瓊醱 |
| `or` | 合何估佑伽伺佔佝含 | 知舍信侶俗侷倌倍倚 |

v0.3 文件寫 `vd` 尾二係「網綜」，係錯嘅。全表實測係 **綑綵**。

## 權重

字頻權重只用嚟揀每個字嘅主碼（詞語編碼用）。Windows 喺某個碼顯示、但倉頡冇呢個碼嘅字（例如 網@vd），權重係 0，所以詞語仍然用真主碼（網 = `vv`）。

## 常用熱門頁

正常頁唔受學字影響（`translator/enable_user_dict: false`）。第 1 頁按 **左** 會開「♥常用熱門」環頁，揀過嘅字（♥常）排先，唔夠就用正常候選補（♥熱）。

## 重新生成

```bash
python3 tools/mscapture/merge_capture.py tools/mscapture/raw/*.tsv   # 重新合併實測
python3 scripts/gen_quick_dict.py --cangjie <cangjie5.dict.yaml> --essay <essay.txt> --essay-cantonese <essay-cantonese.txt>
```

腳本會逐個碼檢查 Windows 次序；有一格唔對就退出。
