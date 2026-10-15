# KINFX 中英混打輸入法 — 設定（Flex）

產品目標：**夠 flex**。預設行為固定清楚；唔同模式全部可改。本輪用 **RIME `*.custom.yaml`**（完整 GUI 面板可後續）。

## 預設（開箱）

| 項目 | 預設 | 說明 |
| --- | --- | --- |
| 主方案 | `kinfx_quick` 速成 | `default.yaml` schema_list 第一 |
| 混打 | **零切換** | 打「今日用 **API** 測試」：大寫拉丁／email／URL 直出，`ascii_mode=0` |
| Shift_L | `inline_ascii` | 可選臨時西文；**Fcitx5 常搶 LShift**（見下） |
| 持久西文 | `ascii_mode` 開關 | 預設鍵 `Control+Shift+2`；或 Fcitx5 切 keyboard-us |
| 排序 | 碼表權重把 Windows 頭 9 釘喺第 1 頁 | 見 `docs/WIN_QUICK_RANK.md`。`enable_user_dict` 預設關，免得學頻蓋過頭頁；常用熱門係左鍵環頁 |
| 候選每頁 | **9**（選字鍵 **1–9**） | 同 Windows 官方速成。`menu/page_size` 寫喺 schema。Flex 可改，產品預設係 9 |
| 選字 | **直列**；空白翻頁；Enter／1–9 選字；Tab 展開 | 見 `docs/WIN_QUICK_SELECT.md`。無候選窗時空白仍然上屏 |
| 常用熱門 | **開** | 多頁碼先至有，環頁一頁 9 格。`win_quick/hot_page: false` 可關 |
| 粵拼 | `jyut6ping3` 有聲調 | 例 `nei5`、`ngo5`、`jyut6`；亦可唔打調。每頁同樣 9 |
| 詞前綴 | 開，長度 ≥ 3 | `ofc`→無錯。兩碼唔出詞。見 `docs/PHRASE_MIX.md` |
| 英詞 | 開，前綴長度 ≥ 4 | `gmai`→Gmail。`me`／`or`／`of` 唔出英詞 |

## 點改（配置層）

1. 複製例檔：
   - `schemas/examples/kinfx_quick.custom.yaml.example`
     → `~/.local/share/fcitx5/rime/kinfx_quick.custom.yaml`
   - 粵拼同上（`kinfx_jyutping.custom.yaml`）
2. 改 `patch:` 底下鍵（見例檔註解）
3. 重新部署：候選列 **F4**，或
   `rime_deployer --build ~/.local/share/fcitx5/rime /usr/share/rime-data`
   （兩個路徑。只傳 user dir 時 Linux 會把 user dir 當成 shared，部署靜默失敗。）

可改項目（本輪已開）：

- 混打策略：`recognizer/patterns/uppercase|email|url`
- Shift／ASCII：`ascii_composer/switch_key/*`、`good_old_caps_lock`
- 中西文 toggle：`key_binder/bindings`（`toggle: ascii_mode`）
- 排序／學習：`translator/enable_user_dict`（預設關，見 `docs/WIN_QUICK_RANK.md`）、completion、sentence
- 每頁候選數：`menu/page_size`（**產品預設 9**；例檔把 `5` 註解住，取消註解先至生效）
- 選字：`win_quick/space_pages`、`hot_page`、`tab_expand`、`style/horizontal`（見下）
- 粵拼提示／字母表：`translator/spelling_hints`、`speller/alphabet`
- 詞前綴／英詞：`phrase_mix/enable`、`phrase_mix/min_length`、`melt_eng/enable`、`melt_eng/prefix_length`（見 `docs/PHRASE_MIX.md`）

## 候選每頁 9（硬需求）

Windows 微軟速成預設每頁 **9** 個候選，用數字鍵 **1–9** 選字。速成（`kinfx_quick`）同粵拼（`kinfx_jyutping`）schema 都寫 `menu/page_size: 9`。librime 讀呢個鍵做分頁；`1` 選第一個、`9` 選第九個。

Fcitx5 classicui、Squirrel、Weasel 顯示 librime 交嚟嘅一頁，classicui 冇 page size 設定。`scripts/install-linux.sh` 把用戶目錄 `default.yaml` 嘅 `menu/page_size` 設成 9。方案檔本身寫 9：就算 `default.custom.yaml` 把全域頁數設成 5，速成／粵拼（`kinfx_quick`／`kinfx_jyutping`）編譯結果仍然係 9。

要改 KINFX 頁數：複製 `schemas/examples/kinfx_quick.custom.yaml.example` 做 `kinfx_quick.custom.yaml`，取消 `"menu/page_size": 5` 嘅註解再部署。呢個先至覆蓋方案。例檔預設註解住，複製過去唔會改走產品預設。

## 選字 Flex（偏離 Windows 先至改）

預設見 `docs/WIN_QUICK_SELECT.md`。例檔入面對應鍵都註解住。

| 想改 | custom patch |
| --- | --- |
| 空白改回「選焦點」（v0.1.1 習慣，通常即係第 1 個） | `"win_quick/space_pages": false` |
| 關掉常用熱門環頁 | `"win_quick/hot_page": false` |
| Tab 唔再展開 | `"win_quick/tab_expand": false` |
| 候選改打橫 | `"style/horizontal": true`，再將 Fcitx5 `~/.config/fcitx5/conf/classicui.conf` 嘅 `Vertical Candidate List` 設 `False` |

`space_pages: false` 由 Lua 喺有候選窗時直接確認焦點，唔使改 `key_binder` 索引。無候選窗（`好API`）空白仍然上屏。若連 Enter 都要還原「原樣上屏 `vd`」：`"editor/bindings/Return": commit_raw_input`。產品預設唔係咁。

## Fcitx5 與 LShift

Fcitx5 預設常用 **左 Shift** 做「切輸入法／鍵盤」。此時 rime 嘅 `Shift_L: inline_ascii` **唔會觸發**；零切換混打請用**大寫拉丁**路徑（預設）。若要 rime 食到 LShift：用 `fcitx5-configtool` 解除該熱鍵，或將 schema 嘅 `Shift_L` 設 `noop`（見例檔 Mode B）。

## 模式速查

| 模式 | 做法 |
| --- | --- |
| 零切換夾英文（預設） | 英詞用大寫；唔切 `ascii_mode` |
| 臨時西文（可選） | `Shift_L: inline_ascii`（需 Fcitx5 唔搶鍵） |
| 必須切英文先打 | custom 清空 `uppercase` pattern；用 `ascii_mode`／Fcitx5 |
| 學頻（會改頭頁） | `translator/enable_user_dict: true`。預設關；開咗之後常用字可以爬返正常第 1 頁 |
| 空白選焦點（舊習慣） | `win_quick/space_pages: false` |
