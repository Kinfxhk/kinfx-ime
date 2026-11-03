# KINFX 中英混打輸入法 — 設定（Flex）

預設行為跟 Windows 11 微軟速成；要偏離才改。全部設定用 RIME `*.custom.yaml` 寫。

## 預設

| 項目 | 預設 | 說明 |
| --- | --- | --- |
| 主方案 | `kinfx_quick` 速成 | `schema_list` 第一 |
| 排序 | **全表跟 Windows 11 微軟速成** | 見 `docs/WIN_QUICK_RANK.md`。不學字（`enable_user_dict: false`） |
| 每頁候選 | **9**，選字鍵 1–9 | `menu/page_size` |
| 選字 | 直列；空白翻頁；Enter／1–9 選字；Tab 展開 | 見 `docs/WIN_QUICK_SELECT.md` |
| 頂字 | 第 3 碼照 Windows 上屏 | 常用詞前綴例外，見 `docs/PHRASE_MIX.md` |
| 詞語 | 開（`phrase_mix/capture: hot`） | `ofc` → 人類／無錯、`ofca` → 無錯 |
| 英文詞 | 開（`english/mode: smart`） | 空白上屏安全詞（`hello`␣→ hello）、左 Shift 上屏短詞（`of` Shift→ of） |
| 聯想詞 | 開（`association/enable: true`） | 選完單字出跟尾詞，Shift+數字選 |
| 混打 | 零切換 | 大寫英文、email、URL 直出 |
| 常用熱門 | 開 | 第 1 頁按左 |
| 候選窗 | 正黑體、圓角、淺／深色跟系統 | `weasel.custom.yaml` 裡面的 `kinfx-ime:weasel-skin` 段 |

## 怎樣改

1. 複製 `schemas/examples/kinfx_quick.custom.yaml.example`：
   - Windows：放到 `%APPDATA%\Rime\kinfx_quick.custom.yaml`
   - Linux：放到 `~/.local/share/fcitx5/rime/kinfx_quick.custom.yaml`
2. 取消註解要改的項目。
3. 重新部署：
   - 小狼毫：右鍵 → 重新部署
   - Linux：`rime_deployer --build <user_dir> /usr/share/rime-data`

## 常用設定

| 想要 | patch |
| --- | --- |
| 純 Windows 頂字，不保留任何詞 | `"phrase_mix/capture": none` |
| 任何詞前綴都保留（較少頂字） | `"phrase_mix/capture": all` |
| 完全關掉詞語 | `"phrase_mix/enable": false` |
| 關掉英文詞 | `"english/enable": false` |
| 英文改回 v0.4.1（只限 extras.tsv 字） | `"english/mode": "shift"` |
| 不保留英文（純 Windows 頂字） | `"english/mode": "off"` |
| 空白只上屏 5 個字母或以上的英文 | `"english/space": "long"` |
| 空白不上屏英文（都要左 Shift） | `"english/space": "off"` |
| 關掉聯想詞 | `"association/enable": false` |
| 空白改回選焦點候選 | `"win_quick/space_pages": false` |
| 「.」翻頁，不上屏（v0.5.6 做法） | `"win_quick/period_pages": true` |
| 選字後 `Shift+9` 選第 9 個聯想詞（v0.5.6 做法） | `"association/paren_pick": true` |
| 關掉常用熱門 | `"win_quick/hot_page": false` |
| Tab 不展開 | `"win_quick/tab_expand": false` |
| 候選橫排 | `"style/horizontal": true` |
| 學字（會改 Windows 次序） | `"translator/enable_user_dict": true` |
| 每頁 5 個 | `"menu/page_size": 5` |

## 混打

| 模式 | 做法 |
| --- | --- |
| 零切換（預設） | 細楷英文詞直接打，空白上屏（`hello`␣→ hello）。安全詞表不允許上屏的（短詞、少見詞）就按一下左 Shift 上屏。大寫、email、URL 直出 |
| 短詞（`of`、`to`、`on`…） | 打到一半按一下左 Shift：已打字母變英文（`of` Shift → of）。Linux 要先解除 Fcitx5 左 Shift 熱鍵（見下） |
| 選字後的空白／標點 | `vd` 1 之後按空白＝打空格，按 `.`＝「。」（會關聯想詞）。想與 Windows 一樣（空白翻聯想頁）：`association/space: page` |
| 持久英文 | `Control+Shift+2` 切換 `ascii_mode` |
| 一定要切換才打英文 | 清空 `recognizer/patterns/uppercase` |

## v0.5.2 新開關

| 開關 | 預設 | 作用 |
| --- | --- | --- |
| `english/empty_shift` | `noop` | 沒有輸入時按左 Shift：`noop` 什麼都不做；`ascii` 照 librime 切臨時英文（v0.5.1） |
| `english/hold_min` | `4` | 英文開頭達到這個字母數之後，詞表沒有的詞也繼續保留；`0` 關 |
| `english/hold_extra` | `8` | 在上面的保留之上，最多再加多少個字母 |
| `english/unknown_space_min` | `7`（v0.5.3 開發版試過 `5`，撞中文，改回） | 詞表沒有的詞，多少個字母或以上才可以按空白上屏（較短的用左 Shift） |
| `punctuator/half_shape` `/`、`\` | `/`、「、」 | `/` 直出；「、」由 `\` 出 |
| Ctrl+. | — | 切中英文標點（`ascii_punct`），寫 code 用 |

## v0.5.3 新開關

| 開關 | 預設 | 作用 |
| --- | --- | --- |
| `english/preedit` | `letters` | 預編輯顯示已輸入的字母（`of`、`hello`）；`radicals` 顯示速成字根（`人火`，v0.5.2） |
| `english/hyphen` | `word` | 英文詞後面打 `-` 接駁（`tool-calling`）；`off` 交回標點（v0.5.2） |
| `english/clipboard` | `clear` | 正在輸入時按 Ctrl+V（macOS Cmd+V）：收起輸入，未上屏的字不會上屏，交回程式貼上（可以先用滑鼠點到第二個位置）；選字後聯想清單開啟時按 Ctrl+V：輸入法讀取剪貼簿直接上屏，清單保留，可以繼續選字；Ctrl+C／X：已頂字照上屏，收起輸入，快捷鍵交回程式；`keep` 照 v0.5.2 |

## v0.5.4 新開關

| 開關 | 預設 | 作用 |
| --- | --- | --- |
| `english/rescue_min` | `2` | 左 Shift 補救：開頭達到這個字母數是英文／品牌名開頭，之後中斷了也繼續保留，按左 Shift 照字母上屏（`adsense`、`zdrav`）；空白／數字照 Windows 出中文。`0` 關（v0.5.3） |
| `english/rescue_extra` | `8` | 上面最多再保留多少個字母 |

品牌／網站名表（v0.5.4）：`lexicon/en/kinfx_names.dict.yaml`，由 `scripts/gen_names.py` 在 Wikidata（CC0）生成，部署時編譯成原生表 `kinfx_names`（不進入 Lua heap）。手寫名表 `kinfx_en_names.txt` 優先。

公司名／產品名表：`lexicon/en/kinfx_en_names.txt`（「顯示字<Tab>細楷碼」）。安裝後在 Rime 用戶目錄，改完重新部署。

## 自動化測試注意

- **空白上屏英文會自帶一個空格**：`startup` 空白 → `startup `，那一下空白已經用了。測試計劃打完英文詞不要再加一個空白，否則會變雙空格。左 Shift 上屏（`of` 左 Shift → `of`）就沒有空格，要空格再按空白。
- **選字後第一次按空白是打空格**（`association/space: type`），不會翻聯想頁。
- **Fcitx5**：重啟或者開新視窗時，輸入法有時會回到 `keyboard-us`。自動化開始前先執行 `fcitx5-remote -s rime`。

### librime 按鍵序列（`simulate_key_sequence`／rimeh `keys`）常見寫錯

三平台（Windows Weasel、Linux Fcitx5、macOS Squirrel）用同一套檔案，候選次序一樣。以下寫法錯了會報出假差異：

| 想測 | ✅ 正確 | ❌ 錯誤 | 錯了會怎樣 |
| --- | --- | --- | --- |
| 選第 5 個 | `me5` → 夏 | `me 5` | 空白是翻頁，變成選第 2 頁第 5 個（璦） |
| 按一下左 Shift | `is{Shift_L}{Release+Shift_L}` → is | `is{Shift_L}` | 只有按下、沒有放開，不當作按一下，什麼都不輸出 |
| Shift 打符號 | `{Shift_L}{Shift+colon}{Shift+Release+Shift_L}` → ： | `{Shift+;}` | librime 不接受這個鍵名，整串序列失敗 |
| 用詞表的詞 | 先查看 `kinfx_en_names.txt` 有沒有（`grep -P "\tyolo$"`） | — | 版本尚未有那個詞，就會照速成出中文（v0.5.2 `/yolo` → /亥） |

另外：Ctrl+. 切英文標點會記在 `user.yaml`（`ascii_punct`）。一連串 case 之前先清除，否則之後所有符號 case 都受影響。

## Fcitx5 和左 Shift

Fcitx5 預設用左 Shift 切換輸入法，rime 收不到。大部分英文詞用空白上屏，不受影響；但短詞（`of`、`to`）要左 Shift，在預設 Fcitx5 上按下去會切換離開輸入法，`of` 變回中文（伙）。

**建議：解除 Fcitx5 左 Shift 熱鍵。**

```bash
./scripts/linux-free-left-shift.sh          # 由 TriggerKeys／AltTriggerKeys 移除 Shift_L（Ctrl+Space 保留），備份後重啟 Fcitx5
./scripts/linux-free-left-shift.sh --undo   # 還原
```

2026-10-17 Linux VM（Fcitx5 5.1.19）實測（那次兩組熱鍵全部清空）：`of` + 左 Shift → of，輸入法保持 rime。腳本只移除 Shift_L，切換輸入法仍可用 Ctrl+Space 或者托盤選單。

**不建議 `english/commit_key: Caps_Lock`（Linux）**：同一次實測，XKB 的 Caps Lock 切換攔不到，之後全部變大寫（hello → HELLO），`of` 也沒有上屏。
