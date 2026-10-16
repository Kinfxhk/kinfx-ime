# KINFX 中英混打輸入法 — 設定（Flex）

預設行為跟 Windows 11 微軟速成；要偏離先改。全部設定用 RIME `*.custom.yaml` 寫。

## 預設

| 項目 | 預設 | 說明 |
| --- | --- | --- |
| 主方案 | `kinfx_quick` 速成 | `schema_list` 第一 |
| 排序 | **全表跟 Windows 11 微軟速成** | 見 `docs/WIN_QUICK_RANK.md`。唔學字（`enable_user_dict: false`） |
| 每頁候選 | **9**，選字鍵 1–9 | `menu/page_size` |
| 選字 | 直列；空白翻頁；Enter／1–9 選字；Tab 展開 | 見 `docs/WIN_QUICK_SELECT.md` |
| 頂字 | 第 3 碼照 Windows 上屏 | 常用詞前綴例外，見 `docs/PHRASE_MIX.md` |
| 詞語 | 開（`phrase_mix/capture: hot`） | `ofc` → 人類／無錯、`ofca` → 無錯 |
| 英文詞 | 開（只限 `extras.tsv` 嘅字） | `gmai` → Gmail |
| 混打 | 零切換 | 大寫英文、email、URL 直出 |
| 常用熱門 | 開 | 第 1 頁按左 |
| 候選窗 | 正黑體、圓角、淺／深色跟系統 | `weasel.custom.yaml` 入面嘅 `kinfx-ime:weasel-skin` 段 |

## 點改

1. 複製 `schemas/examples/kinfx_quick.custom.yaml.example`：
   - Windows：放去 `%APPDATA%\Rime\kinfx_quick.custom.yaml`
   - Linux：放去 `~/.local/share/fcitx5/rime/kinfx_quick.custom.yaml`
2. 取消註解要改嘅項目。
3. 重新部署：
   - 小狼毫：右鍵 → 重新部署
   - Linux：`rime_deployer --build <user_dir> /usr/share/rime-data`

## 常用設定

| 想要 | patch |
| --- | --- |
| 純 Windows 頂字，唔留住任何詞 | `"phrase_mix/capture": none` |
| 任何詞前綴都留住（較少頂字） | `"phrase_mix/capture": all` |
| 完全關掉詞語 | `"phrase_mix/enable": false` |
| 關掉英文詞 | `"english/enable": false` |
| 空白改回揀焦點候選 | `"win_quick/space_pages": false` |
| 關掉常用熱門 | `"win_quick/hot_page": false` |
| Tab 唔展開 | `"win_quick/tab_expand": false` |
| 候選打橫 | `"style/horizontal": true` |
| 學字（會改 Windows 次序） | `"translator/enable_user_dict": true` |
| 每頁 5 個 | `"menu/page_size": 5` |

## 混打

| 模式 | 做法 |
| --- | --- |
| 零切換（預設） | 英文用大寫開頭，或者打 email／URL |
| 臨時英文 | `Shift_L: inline_ascii`（Fcitx5 可能搶咗左 Shift） |
| 持久英文 | `Control+Shift+2` 切換 `ascii_mode` |
| 一定要切先打英文 | 清空 `recognizer/patterns/uppercase` |

## Fcitx5 同左 Shift

Fcitx5 預設用左 Shift 切輸入法，所以 rime 收唔到。用大寫英文就唔使 Shift。要用 Shift 嘅話，喺 `fcitx5-configtool` 解除嗰個熱鍵。
