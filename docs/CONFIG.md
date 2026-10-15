# KINFX IME — 設定（Flex）

產品目標：**夠 flex**。預設行為固定清楚；唔同模式全部可改。本輪用 **RIME `*.custom.yaml`**（完整 GUI 面板可後續）。

## 預設（開箱）

| 項目 | 預設 | 說明 |
| --- | --- | --- |
| 主方案 | `kinfx_quick` 速成 | `default.yaml` schema_list 第一 |
| 混打 | **零切換** | 打「今日用 **API** 測試」：大寫拉丁／email／URL 直出，`ascii_mode=0` |
| Shift_L | `inline_ascii` | 可選臨時西文；**Fcitx5 常搶 LShift**（見下） |
| 持久西文 | `ascii_mode` 開關 | 預設鍵 `Control+Shift+2`；或 Fcitx5 切 keyboard-us |
| 排序 | 碼表權重（essay + 粵語 essay×5） | `enable_user_dict: true` 會再學頻 |
| 粵拼 | `jyut6ping3` 有聲調 | 例 `nei5`、`ngo5`、`jyut6`；亦可唔打調 |

## 點改（配置層）

1. 複製例檔：
   - `schemas/examples/kinfx_quick.custom.yaml.example`
     → `~/.local/share/fcitx5/rime/kinfx_quick.custom.yaml`
   - 粵拼同上（`kinfx_jyutping.custom.yaml`）
2. 改 `patch:` 底下鍵（見例檔註解）
3. 重新部署：候選列 **F4** 或 `rime_deployer --build ~/.local/share/fcitx5/rime`

可改項目（本輪已開）：

- 混打策略：`recognizer/patterns/uppercase|email|url`
- Shift／ASCII：`ascii_composer/switch_key/*`、`good_old_caps_lock`
- 中西文 toggle：`key_binder/bindings`（`toggle: ascii_mode`）
- 排序／學習：`translator/enable_user_dict`、completion、sentence
- 粵拼提示／字母表：`translator/spelling_hints`、`speller/alphabet`

## Fcitx5 與 LShift

Fcitx5 預設常用 **左 Shift** 做「切輸入法／鍵盤」。此時 rime 嘅 `Shift_L: inline_ascii` **唔會觸發**；零切換混打請用**大寫拉丁**路徑（預設）。若要 rime 食到 LShift：用 `fcitx5-configtool` 解除該熱鍵，或將 schema 嘅 `Shift_L` 設 `noop`（見例檔 Mode B）。

## 模式速查

| 模式 | 做法 |
| --- | --- |
| 零切換夾英文（預設） | 英詞用大寫；唔切 `ascii_mode` |
| 臨時西文（可選） | `Shift_L: inline_ascii`（需 Fcitx5 唔搶鍵） |
| 必須切英文先打 | custom 清空 `uppercase` pattern；用 `ascii_mode`／Fcitx5 |
| 穩定候選序（測試） | `translator/enable_user_dict: false` + 乾淨 user dir |
