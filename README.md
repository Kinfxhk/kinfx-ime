# KINFX 中英混打輸入法

香港繁體速成輸入法，中英混打唔使切換模式。速成候選次序**逐頁跟 Windows 11 微軟速成**，另外補齊港字、常用詞、英文詞同聯想詞。引擎用 [librime](https://github.com/rime/librime)：Windows 11 由 [小狼毫（Weasel）](https://github.com/rime/weasel) 載入，Linux 用 Fcitx5，macOS 用 [鼠鬚管（Squirrel）](https://github.com/rime/squirrel)。

**最新版本：v0.5.8**（2026-10-18）· [所有版本同更新紀錄](https://github.com/Kinfxhk/kinfx-ime/releases)

## 實測

| 項目 | 結果 | 版本／日期／環境 |
| --- | --- | --- |
| 速成候選次序 | 658 個兩碼，每頁每格同 Windows 一致：**658／658** | 2026-10-15～16 喺 Windows 11 Pro 26H2（build 26300）微軟速成用 `tools/mscapture` 讀出全表；每次發佈用 `fullorder.sh` 再對 |
| Windows 實機打字 | 自動化驗收 **66／66**（逐粒鍵打入真視窗，包括 `https://x.com`、`tool-calling`、`好：`、`adsense`、`zdrav` 左 Shift、`vd.`→好。、`vd` 1 `Shift+9`→好（、右箭咀翻頁） | v0.5.7 Lua，2026-10-18，KinTest VM（Windows 11）、小狼毫 0.17.4 |
| Windows 實機打文章 | HKEPC 十篇 76 段 9,307 字（22,171 粒鍵，模擬照 Windows 習慣打字）：錯字 v0.5.6 **514** → v0.5.7 **213**，冇一段變差；VM 真按鍵每段同離線一致 | v0.5.7 Lua，2026-10-18，KinTest VM、小狼毫 0.17.4；錯字大部分係詞語暫留同聯想（設計行為），見「已知限制」 |
| Linux 實機打字 | 505 字中英混合文章：全形標點全部一致（，17　、2　。9　：2　「1　」1），去掉空格後 **453／453** 字一致，**30 個英文詞全部正確** | v0.5.1，2026-10-17，Ubuntu 26.04、Fcitx5 5.1.19、fcitx5-rime（librime 1.16.1）、gedit，kernel-level 按鍵重播 |
| Linux 實機打字（舊版） | 同一篇文章 **byte-exact 505／505** | v0.4.0，2026-10-16，同上環境 |
| 英文功能有冇改到中文 | 209 萬組按鍵（全部兩碼＋兩碼、三段連打抽樣），同冇英文功能嘅 v0.4.1 比：**中文改變 0**；文章重打 2 萬字中文錯 0、英文 741／741。**意外差異 972**（見「已知限制」） | v0.5.7（2026-10-18），`tools/rimeh/compare.py`，離線 |
| 每粒鍵用時（Windows） | 約 **0.1 ms**：`vd`（2 粒鍵）0.20 ms；16 粒鍵 2.1 ms；`thequickbrownfox`＋空白（17 粒鍵）2.1 ms（中位數） | v0.5.1，2026-10-17，`tools/rimeh` 離線，用小狼毫 0.17.4 嘅 rime.dll。舊版 v0.3 約 70 ms |
| 每粒鍵用時（Linux） | 未有量度數字；實機打 505 字文章冇掉鍵 | — |
| 英文字打唔打得出（空白或左 Shift） | 最多人去嘅網站名頭 5,000 個：打唔出 **16.2%**（v0.5.3：40.0%）；最常用英文詞頭 9,868 個：打唔出 **0.4%**（v0.5.3：1.6%） | v0.5.4（799d7fc），2026-10-18，`tools/rimeh/english_reach.py` 離線；網站名嚟自 Tranco 排名 |

Linux v0.5.1 嗰次唔係 byte-exact，原因係測試計劃喺英文詞後面多加咗一個空白。v0.5.1 用空白上屏英文已經自帶空格（見下面「打英文」），所以變咗雙空格，唔係輸入法打錯字。

## 打法速查

| 輸入 | 結果 |
| --- | --- |
| `vd` 1 | 好 |
| `vd` 空白 1 | 嫻（第 2 頁第 1 個，同 Windows） |
| `vd` `of` 3 | 好係（第 3 碼照 Windows 頂字） |
| `ofc` 1 | 人類 |
| `ofca` 1 | 無錯 |
| `hioa` 1 | 我會 |
| `vd` 1 `.` | 好。 |
| `startup` 空白 | `startup `（英文＋一個空格） |
| `of` 左 Shift | `of`（冇空格） |
| `vd` `API` | 好API（大寫直出） |
| `wondershare` 空白 | `Wondershare `（公司名） |
| `adsense` 空白 | `AdSense `（品牌名表，v0.5.4） |
| `zdrav` 左 Shift | `zdrav`（詞表冇、打到一半變咗中文嘅字，v0.5.4） |
| `/` | /（直出，唔使揀） |
| `\` | 、 |
| `hi` 7 `Shift+2` | 我講（聯想詞） |
| `nei5`（粵拼方案） | 你 |

## 特點

- **候選次序同 Windows 一樣**：658 個兩碼逐格對過（見 `docs/WIN_QUICK_RANK.md`）。
- **港字齊**：㗎、嘅、𠻹、𨋢 等 Windows 冇嘅字，排喺 Windows 候選之後，唔會郁到 Windows 原本嘅位置。
- **連打順**：第 3 碼照 Windows 頂字上屏。只有打出嚟係常用詞先會留住等你揀，例如 `ofc` → 人類、無錯；`lwm` → 中國。冇詞接得落去就照 Windows 上屏。
- **細楷英文直接打**：見下面「打英文」。英文唔會佔速成嗰 1–9 格。
- **聯想詞**：揀完單字出跟尾詞，見下面「聯想詞」。
- **選字同 Windows**：每頁 9 個、直列；空白翻頁；1–9／Enter 選字；Tab 展開；第 1 頁按左開「常用熱門」。
- **候選窗**：正黑體、圓角、淺陰影，淺色／深色跟系統。
- **粵拼**：有聲調（`nei5` → 你）。

## 打英文

速成碼同英文字母重疊（676 個兩字母組合入面 658 個係速成碼），所以輸入法要分辨你打緊中文定英文。做法：打字母時，如果仲有可能係英文詞，就先擺住中文頂字嘅結果，等下一粒鍵決定。

| 情況 | 做法 | 結果 |
| --- | --- | --- |
| 一般細楷英文詞 | 打完撳空白 | `startup`␣ → `startup `、`the`␣ → `the ` |
| 英文詞後面跟標點 | 打完撳標點 | `the` `,` → `the，` |
| 2 字母短詞（of、to、on、or…） | 打完撳一下**左 Shift** | `of` 左 Shift → `of` |
| 空白唔上屏嘅詞（容易同中文撞嘅短詞、少見詞，例如 door） | 打完撳一下左 Shift | `door` 左 Shift → `door` |
| 公司名、產品名、網站名（Wondershare、GitLab、AdSense、GoDaddy…） | 打完撳空白或者左 Shift | `openai`␣ → `OpenAI `、`adsense`␣ → `AdSense ` |
| 打到一半變咗中文嘅英文字（`zdrav`、`etsy`） | 打完撳一下左 Shift（v0.5.4 補救） | `zdrav` 左 Shift → `zdrav` |
| 英文詞開頭（const、async） | 5 個字母或以上撳空白（6 個字母除外，空白係速成翻頁）；短啲撳左 Shift | `const`␣ → `const ` |
| 詞表冇嘅英文字 | 7 個字母或以上撳空白；短啲撳左 Shift | `wonderxyz`␣ → `wonderxyz ` |
| 連字號英文（tool-calling） | 直接打 `-` | `tool-calling`␣ → `tool-calling ` |
| 打錯字 | Backspace 退一個字母，再打 | `hellp` ⌫ `o`␣ → `hello ` |
| 大寫開頭、email、URL | 直接打 | `Startup`、`a@b.com`、`www.x.com`、`https://x.com` |
| 打長段英文 | `Ctrl+Shift+2` 切英文模式，再撳一次返中文 | — |

- **v0.5.1 起，用空白上屏英文會自帶一個空格**：`startup` 空白 → `startup `，嗰下空白已經用咗，唔使再撳。用左 Shift 上屏就冇空格。
- 邊啲詞可以用空白上屏，由「安全詞表」決定：用 SCOWL 詞表，逐個詞計佢同速成中文撞車嘅機會，撞得多嘅（約 350 個，主要係 2–4 字母詞）就唔畀空白上屏。詳情見 `docs/ENGLISH_MIX.md`。
- 公司名同產品名喺 `lexicon/en/kinfx_en_names.txt`（格式「顯示字<Tab>細楷碼」，可以自己加，呢個表優先）。
- v0.5.4 加咗品牌／網站名表 `lexicon/en/kinfx_names.dict.yaml`：由 Wikidata（CC0）抽出軟件、網站、網上服務、公司、品牌名，約 5 千個（`scripts/gen_names.py`）。部署時編譯成原生表，唔會令打字變慢。
- **左 Shift 補救（v0.5.4）**：英文字打到一半，詞表再冇字咁樣開頭，輸入法照 Windows 頂字出中文，但會先擺住，等你下一粒鍵。撳一下左 Shift，就將成串字母照打出嚟（`zdrav`）；撳空白、數字或者其他鍵，結果同 v0.5.3 一樣係中文。代價：呢種情況下中文會遲一兩粒鍵先上屏。`"english/rescue_min": 0` 關。
- 唔喺詞表嘅英文字：英文開頭夠 4 個字母之後，輸入法會繼續留住（最多再多 8 個字母），等你撳空白或者左 Shift（`english/hold_min`）。
- 冇打字時撳左 Shift 唔會再入英文模式（v0.5.1 會入一個有底線、好難離開嘅模式）。
- 如果撳嘅係英文以外嘅鍵，擺住嘅中文照 Windows 上屏，結果同冇英文功能時一樣（見上面「實測」）。

## 打 code／符號

| 想要 | 做法 |
| --- | --- |
| `/` | 直接撳，出半形 /（v0.5.2 起唔使揀） |
| 「、」 | 撳 `\` |
| 全部符號半形（寫 code：`( ) ; : ' " , .` 等） | 撳 **Ctrl+.** 切英文標點，再撳一次返中文標點（同 Windows 微軟速成一樣）。狀態會記住 |
| `'` `"` `_` | 直接出半形（v0.5.3 起，同 Windows 微軟速成實測一樣） |
| `:` `^` 等 Shift 符號 | 照平時撳住 Shift 打；撳住 Shift 打符號唔會當英文上屏（v0.5.3 修正） |
| 打緊字撳 Ctrl+V（macOS Cmd+V） | 收起輸入（未上屏嘅字唔上屏），交返程式貼上，貼去游標位置 |
| 打緊字撳 Ctrl+C／X | 收起輸入，快捷鍵交返程式（`english/clipboard: keep` 還原 v0.5.2） |

## 聯想詞

揀完一個單字（用數字或者 Enter）之後，會出跟尾詞。

| 輸入 | 結果 |
| --- | --- |
| `hi` 7 | 我，同時出聯想：同 講 望 見… |
| `hi` 7 `Shift+1` | 我同 |
| `hi` 7 `Shift+2` | 我講 |
| `hi` 7 1 | 我1（普通數字照打數字，關聯想） |
| `hi` 7 空白 | `我 `（預設：空白關聯想，再打一個空格） |
| `hi` 7 `.` | 我。（標點關聯想，照打） |
| `vd` 1 `Shift+9` | 好（（揀字後 `Shift+9` 打括號，唔揀第 9 個聯想詞；第 1–8 個照用 `Shift+1`–`Shift+8`） |
| `hi` 7 再打字母 | 關聯想，開始打新字 |
| `ofc` 1 | 人類（揀詞語唔出聯想） |

- 想同 Windows 一樣，揀字後撳空白係翻聯想頁：設 `"association/space": page`。
- 想用 `Shift+9` 揀第 9 個聯想詞（v0.5.6 做法）：設 `"association/paren_pick": true`。
- 聯想詞次序跟粵語語料（essay-cantonese）字頻，唔係 Windows 聯想詞次序。

## Windows 11 安裝

```powershell
# 1. 安裝小狼毫
winget install Rime.Weasel

# 2. 粵拼資料（可選）：將 rime-cantonese 嘅 jyut6ping3*.yaml 同 essay-cantonese.txt 放入 %APPDATA%\Rime

# 3. 安裝 KINFX（用平時打字嗰個帳戶，唔好用系統管理員）
git clone https://github.com/Kinfxhk/kinfx-ime.git
cd kinfx-ime
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

安裝完會自動重新部署。按 **Win+Space** 揀小狼毫，再喺方案選單（Ctrl+` 或 F4）揀「**KINFX 中英混打輸入法 · 速成**」。

卸載：`scripts\uninstall-windows.ps1`。詳細步驟：`docs/WINDOWS.md`。

## Linux（Fcitx5）安裝

### 首次安裝 checklist

1. 裝套件：

   ```bash
   sudo apt install fcitx5 fcitx5-rime librime-bin librime-plugin-lua \
     rime-data-cangjie5 rime-data-jyut6ping3 rime-essay rime-prelude rime-data-luna-pinyin
   ```

2. 裝 KINFX：`./scripts/install-linux.sh`（複製方案、部署、設定直列候選）。
3. Fcitx5 設定 → 加入「中州韻」→ 揀「KINFX 中英混打輸入法 · 速成」。
4. 解放左 Shift：`./scripts/linux-free-left-shift.sh`（見下面）。
5. 試打：`of` 左 Shift → `of`；`startup` 空白 → `startup `；`vd` 1 `.` → 好。

### 左 Shift（短英文詞要用）

Fcitx5 預設用左 Shift 切輸入法，librime 收唔到嗰下 Shift，所以 `of` 撳左 Shift 會切走輸入法，結果變咗中文「伙」。

`./scripts/linux-free-left-shift.sh` 會：

- 喺 `~/.config/fcitx5/config` 嘅 TriggerKeys／AltTriggerKeys **只移除 `Shift_L`**，其他切換鍵（例如 Ctrl+Space）保留。
- 改之前備份做 `config.kinfx-backup`，改完重啟 Fcitx5。
- 之後左 Shift 就用嚟上屏英文；切輸入法用 Ctrl+Space 或者托盤選單。
- 還原：`./scripts/linux-free-left-shift.sh --undo`。

2026-10-17 Linux VM 實測：執行之後 `of` 左 Shift → `of`，輸入法保持喺 rime。

## macOS（鼠鬚管）安裝

```bash
# 1. 安裝鼠鬚管
brew install --cask squirrel-app

# 2. 安裝 KINFX（會先備份 ~/Library/Rime，再部署並重新載入鼠鬚管）
git clone https://github.com/Kinfxhk/kinfx-ime.git
cd kinfx-ime
./scripts/install-macos.sh
```

3. 系統設定 → 鍵盤 → 輸入方式 → 加入「鼠鬚管」。
4. 按 Ctrl+` 開方案選單，揀「KINFX 中英混打輸入法 · 速成」。
5. 試打：`vd` 1 → 好；`vd.` → 好。；`of` 左 Shift → `of`。

- 腳本只會喺 `default.custom.yaml` 嘅方案清單加入 `kinfx_quick`，唔會刪除你原有嘅方案。原檔案會另存一份 `default.custom.yaml.bak-*`。
- macOS 冇 Fcitx5 嗰種左 Shift 切換問題，唔使執行 `linux-free-left-shift.sh`。
- 打緊字撳 Cmd+V 會交返程式貼上。
- 實測：2026-10-18 喺 Mac Studio（macOS 27.0.1、Squirrel 1.1.2、librime 1.16）用臨時目錄跑安裝腳本測試，`tests/test_install_macos.sh` 7／7 通過。v0.5.7 嘅句號、翻頁、括號同英文，用 librime 直接送按鍵（headless）測試，結果同 Windows 一致。未做過 macOS 介面上嘅逐鍵實打測試。

## 已知限制

- **v0.5.4：5 個字母嘅英文詞開頭撳空白會上屏英文**（例如 `fogge` 空白 → `fogge `），v0.4.1 會翻中文頁。離線比對 209 萬組按鍵入面有 972 組係咁（約每 1 萬組 4.6 組），中文字本身冇改。v0.5.3 已經係咁，v0.5.4 嘅比對先量到。想避開：`"english/space": long` 或者 `off`。
- **v0.5.4 左 Shift 補救會令部分中文遲一兩粒鍵先上屏**（例如 `zdr` 打到一半，「。」要等下一粒鍵）。有即時顯示嘅程式（網址欄、終端機）會睇到。`"english/rescue_min": 0` 關。
- **2026-10-18 用戶回報：Windows 實機用 v0.5.4 開發版時「突然打唔到速成」**，退返 v0.5.3 後正常。原因未查明，正喺 VM 重現。遇到嘅話：撳 Ctrl+Shift+2 或右下角切返「中」；未解決可以退返 v0.5.3。
- **詞語暫留時撳數字鍵，揀嘅係詞語候選**：照 Windows 習慣唔睇候選直接撳數字，會出多咗字（`成功將` → `成功率將`、`同時插` → `同時又插`）。呢個係詞語功能本身，HKEPC 十篇模擬打字入面佔餘下錯字大部分。唔想要：`"phrase_mix/capture": none`（同 Windows 一樣三碼頂字）。
- **有候選時「.」會上屏第一個候選**（v0.5.7，同微軟速成一樣），所以 `.` 唔再翻頁；翻頁用空白或右箭咀。`llama.cpp` 呢類細楷英文中間嘅「.」仍然會變「。」；`!!` 會變「！！」。
- **Linux 唔好用 Caps Lock 做上屏鍵**（`english/commit_key: Caps_Lock`）：XKB 照樣會切大寫鎖定，之後全部變大寫（hello → HELLO），而且 `of` 冇上屏（2026-10-17 Linux VM 實測）。請用左 Shift 加 `linux-free-left-shift.sh`。
- **Fcitx5 開新視窗有時會返去英文鍵盤（keyboard-us）**：平時睇托盤圖示就知道；做自動化測試之前，先執行 `fcitx5-remote -s rime`。
- **Tab 展開**：v0.5.1 及之前，撳錯 Tab 之後「〔展開·欄1〕」會出現喺預編輯，部分程式會連埋寫入文件，而且 Esc 關唔到。v0.5.2 已修正：提示唔再放喺預編輯，Esc、上屏或者清空之後自動返普通候選。
- **揀字後撳標點或者空白，會先關聯想詞**：v0.5.0 時「。」會被聯想選單當成翻頁鍵食咗，v0.5.1 已修正。而家聯想詞開住時撳標點或者空白，會先關聯想再打出嚟。
- **聯想詞次序唔係 Windows 次序**：見上面「聯想詞」。
- **2 字母短英文詞一定要撳左 Shift**：佢哋本身係速成碼（`of`＝伙），而空白要留嚟翻頁。

## 設定

全部跟 Windows 預設，要改先改，見 `docs/CONFIG.md` 同 `schemas/examples/kinfx_quick.custom.yaml.example`。

| 想要 | 設定 |
| --- | --- |
| 純 Windows 頂字，唔出詞 | `"phrase_mix/capture": none` |
| 關掉英文詞 | `"english/enable": false` |
| 英文改返 v0.4.1（只限 extras.tsv 字） | `"english/mode": "shift"` |
| 空白只上屏 5 個字母或以上嘅英文詞 | `"english/space": long` |
| 關掉聯想詞 | `"association/enable": false` |
| 揀字後空白翻聯想頁（Windows） | `"association/space": page` |
| 空白揀字而唔係翻頁 | `"win_quick/space_pages": false` |
| 「.」翻頁（v0.5.6 做法，唔出「好。」） | `"win_quick/period_pages": true` |
| 揀字後 `Shift+9` 揀第 9 個聯想詞 | `"association/paren_pick": true` |
| 冇打字撳左 Shift 切臨時英文（v0.5.1 行為） | `"english/empty_shift": ascii` |
| 唔留住詞表冇嘅英文字 | `"english/hold_min": 0` |
| 關左 Shift 補救（中文即刻上屏，v0.5.3 行為） | `"english/rescue_min": 0` |
| 預編輯顯示速成字根（人火）而唔係字母（of） | `"english/preedit": radicals` |
| `/` 返做選單（、 / ／ ÷） | custom 入面刪走 `punctuator/half_shape` 嗰兩行 |

## 方案

| 選單名 | schema_id |
| --- | --- |
| KINFX 中英混打輸入法 · 速成 | `kinfx_quick` |
| KINFX 中英混打輸入法 · 粵拼 | `kinfx_jyutping` |

## 測試

| 指令 | 內容 | v0.5.7 結果 |
| --- | --- | --- |
| `bash tools/rimeh/accept.sh` | Windows 離線（用已安裝小狼毫嘅 rime.dll）：選字、頂字、詞語、英文、品牌名、左 Shift 補救、聯想、貼上、句號、效能 | 191／191 |
| `bash tools/rimeh/fullorder.sh` | 658 個碼逐格同 Windows 比對 | 658／658 |
| `bash tools/rimeh/flex.sh` | 設定開關（英文 mode／space、聯想、詞語、補救、句號翻頁、括號揀字） | 33／33 |
| `python tools/rimeh/compare.py --assoc` | 209 萬組按鍵，同 v0.4.1 比中文結果 | 中文改變 0；意外差異 972（已知限制） |
| `./scripts/smoke-linux.sh` | Linux／CI headless（Debian librime）：候選次序、頂字、英文、聯想、揀字後標點、`passion` | GitHub Actions 通過 |
| `pwsh -File scripts/test-windows-rime.ps1` | 安裝／卸載腳本 | 0 failure |
| `python tests/test_gen_quick_dict.py`<br>`python tests/test_gen_quick_phrases.py`<br>`python tests/test_gen_assoc.py`<br>`python tests/test_gen_english_space.py`<br>`python tests/test_gen_names.py` | 碼表／詞語／聯想／英文詞表／品牌名表生成器 | 5／5 |

Windows 實機自動化驗收（61 項）、Linux VM 同 macOS 外部驗收嘅結果，見上面「實測」。

## 版本

[GitHub Releases](https://github.com/Kinfxhk/kinfx-ime/releases) 有每個版本嘅更新紀錄同 Windows 安裝包。

**v0.5.8（2026-10-18）**：揀字後 `Shift+9` 唔理前端送咩鍵碼（`(`、`9`、小鍵盤 `9` 加 Shift）都出「（」同收起聯想詞。v0.5.7 只認 `(`，直接送 `9`＋Shift 會揀第 9 個聯想詞。

**v0.5.7（2026-10-18）**：用 HKEPC 文章實打之後嘅修正。
- 有候選時打「.」：上屏第一個候選再出「。」（`vd.` → 好。），同微軟速成一樣；唔再用「.」翻頁。空白同右箭咀照舊翻頁（`"win_quick/period_pages": true` 還原）。
- 揀字後打「（」（`Shift+9`）：出括號同收起聯想詞，唔再揀第 9 個聯想詞（`遊戲越獄（` 唔再變 `越獄訟`）。第 1–8 個照用 `Shift+1`–`Shift+8`（`"association/paren_pick": true` 還原）。
- 大楷字或縮寫後面撳空白會打埋空格（`Sony PS5 遊戲` 唔再變 `SonyPS5遊戲`）（`"english/space": off` 還原）。
- `ctrl` `esc` `ime` `utf` `del` `cfg` `pid` 撳空白出英文（v0.5.6）；揀字後撳 Ctrl+V 保留聯想詞（v0.5.6）。

**v0.5.4（2026-10-18）**：品牌名同左 Shift 補救。
- 新增品牌／網站名表（Wikidata，約 5 千個）：`adsense` 空白 → `AdSense `、`godaddy` → `GoDaddy`、`zendesk` → `Zendesk`。
- 英文字打到一半變咗中文（詞表冇嗰個字），撳一下左 Shift 就照字母打出（`zdrav`）。冇撳左 Shift，結果同 v0.5.3 一樣（`"english/rescue_min": 0` 關）。
- 速成候選唔再混入拼音反查字（`j` 只出「十」，同 Windows 一樣）；拼音反查照用 ` 開頭。
- 撳空白：6 個字母嘅英文詞開頭唔再上屏英文（三對速成碼，空白係翻頁）；詞表冇嘅字返返要 7 個字母。

**v0.5.3（2026-10-18）**：打 code／網址修正。
- 撳住 Shift 打 `:` `_` `^` `!` 等符號唔再被當成「左 Shift 上屏英文」吞咗；`https://x.com` 可以直接打。
- `www.`、`https:`、`ftp:`、`mailto:` 開頭會保留做網址。
- 英文詞開頭（const、async、function）5 個字母起撳空白上屏（6 個字母除外；v0.5.2 要 7 個）。詞表冇嘅字照舊 7 個。
- 英文詞後面打 `-` 接駁（tool-calling、JSON-schema），中文照 Windows（`english/hyphen: off` 還原）。
- 打緊字撳 Ctrl+C／V／X 收起輸入，快捷鍵交返程式。
- 預編輯改為顯示打咗嘅字母（`of`，唔再係字根 `人火`）；英文詞顯示成個（`hello`）。要字根：`"english/preedit": radicals`。
- `;`、`'` 照 Windows 頂字再出標點（`vd;` → 好；）。
- `'`、`"`、`_` 出半形（Windows 11 微軟速成實測一樣），其他中文標點照舊全形。
- 名表加 140 個科技詞同縮寫（JSON、API、Linux…）；同時修正一個 v0.5.3 開發中出現、令名表大寫失效嘅次序錯誤。

**v0.5.2（2026-10-17）**：用戶親測回報。
- `/` 直出；`\` 出「、」；Ctrl+. 切中英文標點。
- Tab 展開唔再寫入文件，Esc 會關。
- 英文詞中間撳 Backspace 只退一個字母。
- 冇打字撳左 Shift 唔再入英文模式。
- 公司名、產品名同詞表冇嘅長英文字唔再被拆做中文。

**v0.5.1（2026-10-17）**：跟進 Linux VM 實測嘅修正。
- 揀字後打「.」會出「。」（之前被聯想選單食咗）；`-`、`?`、`:` 等同樣。
- 揀字後撳空白會打空格，英文詞前面唔再冇空格。
- `passion` 唔再被拆做中文。
- 新增 `scripts/linux-free-left-shift.sh`。

**v0.5.0（2026-10-17）**：細楷英文直接打（空白／左 Shift）、聯想詞。

## 目錄

| 路徑 | 內容 |
| --- | --- |
| `schemas/kinfx-quick/` | 速成方案、碼表、Windows 實測次序 `ms_quick_order.tsv` |
| `schemas/kinfx-jyutping/` | 粵拼方案 |
| `schemas/lua/` | 選字（`win_quick.lua`）、詞語留鍵（`phrase_mix.lua`）、英文混打（`english_mix.lua`）、聯想（`assoc.lua`） |
| `lexicon/` | 港詞、四字詞、聯想詞、英文詞（各自授權） |
| `scripts/` | 安裝、卸載、生成碼表、Linux 左 Shift |
| `tools/mscapture/` | 讀取 Windows 微軟速成候選次序 |
| `tools/rimeh/` | 離線測試同效能量度 |
| `docs/` | 詳細文件 |

## 維護者

KinFx。Prop Firm 規則研究、比較表、工具連結同推薦碼：**<https://linktr.ee/kinfx>**

呢頁部分係**聯盟（affiliate）／推薦連結**，例如考核優惠碼同夥伴註冊；你用咗嘅話，維護者可能會收到佣金。呢啲連結同本輸入法無關：程式碼用 MIT 授權，冇任何推薦或者追蹤功能，輸入法亦唔會連網。本專案同該頁列出嘅公司冇關係。

## 授權

- 本專案程式同文件：MIT（`LICENSE`）
- 詞庫同上游資料：見 `NOTICE` 同 `lexicon/NOTICE`（LGPL-3.0、CC BY 4.0、SCOWL）。`lexicon/` 唔係 MIT。
- `ms_quick_order.tsv` 只記錄候選次序作為參考，唔包含微軟程式或者字庫檔。

## English

KINFX is a Hong Kong Traditional Chinese Sucheng (Quick) IME on librime. It runs inside Weasel on Windows 11, Fcitx5 on Linux and Squirrel on macOS. Latest: **v0.5.8** (2026-10-18); see [Releases](https://github.com/Kinfxhk/kinfx-ime/releases).

**What it does**
- Candidate order matches Windows 11 Microsoft Quick on every page: all 658 two-letter codes were captured on Windows 11 Pro 26H2 (build 26300) and match 658/658.
- The third key tops out like Windows; only common phrases are held (`ofc` → 人類).
- Lowercase English without switching modes: Space commits a word on the safe list **and adds the trailing space** (`startup`␣ → `startup `); a Left Shift tap commits short words with no space (`of` Left Shift → `of`). English never takes candidate slots 1–9.
- Association words after a single-character pick: Shift+digit picks (`hi7` Shift+2 → 我講); a plain digit types the digit; Space and punctuation close the list and type (v0.5.1).

**Measured**
- Windows: real-machine acceptance 41/41 (v0.5.1, Weasel 0.17.4). About 0.1 ms per key offline (`vd` 0.20 ms, 16 keys 2.1 ms, median, `tools/rimeh` on Weasel's rime.dll); v0.3 took about 70 ms.
- Linux (2026-10-17, Ubuntu 26.04, Fcitx5 5.1.19, librime 1.16.1, gedit, kernel-level key replay): a 505-character mixed article came out with every full-width punctuation mark identical, 453/453 characters identical after removing spaces, and all 30 English words correct. The remaining difference was an extra space in the test plan, not the IME. v0.4.0 typed the same article byte-exact.
- The English feature does not change Chinese output: 0 changes over 1.9 million key sequences compared with v0.4.1 (offline).
- No Linux latency number has been measured yet.

**v0.5.4** adds a brand / website names table (`kinfx_names`, about 5,000 names from Wikidata, CC0, compiled natively): `adsense`␣ → `AdSense `, `godaddy` → `GoDaddy`. It also adds the Left Shift rescue: when an English word breaks into Chinese halfway (the word is in no list, e.g. `zdrav`), a Left Shift tap types the letters; any other key gives the v0.5.3 Chinese, only later by a key or two (`english/rescue_min: 0` turns it off).

**v0.5.3 fixes** (coding / URLs): a Shift held for a symbol (`:` `_` `^` `!`) is no longer read as the Left Shift English commit, so `https://x.com` types as is; `www.` `https:` `ftp:` `mailto:` starts stay a URL; English word starts and unknown words commit on Space from 5 letters (not 6: three Sucheng pairs, Space pages); a hyphen after an English word joins (`tool-calling`, `english/hyphen: off` restores v0.5.2); Ctrl+C / V / X while composing close the composition and reach the app (`english/clipboard: keep`); the preedit shows the typed letters (`of`, the whole `hello`) instead of Sucheng radicals (`english/preedit: radicals` restores them); `;` and `'` top out like Windows (`vd;` → 好；); `'` `"` `_` type half-width as measured on Windows 11 Microsoft Quick, other Chinese punctuation stays full-width; 141 tech terms and acronyms added to the names list. Windows real-machine acceptance 54/54.

**v0.5.2 fixes** (user report): `/` types `/` directly and `\` types 、; Ctrl+. toggles ASCII punctuation for code; the Tab expand label no longer sits in the preedit (it leaked into documents) and Esc ends it; Backspace inside an English word removes one letter instead of committing the held Chinese; a Left Shift tap with nothing typed no longer enters inline English; company / product names (`lexicon/en/kinfx_en_names.txt`, 333 entries) and unknown long words are held instead of being split into Chinese.

**v0.5.1 fixes**: a full stop after a pick (it was swallowed as paging); the space before an English word after a pick; `passion` no longer split into Chinese; new `scripts/linux-free-left-shift.sh` (removes only Shift_L from the Fcitx5 trigger keys, keeps Ctrl+Space, `--undo` restores).

**Known limits**: on Linux do not use Caps Lock as the commit key (XKB still toggles caps); a new Fcitx5 input context can fall back to keyboard-us, so run `fcitx5-remote -s rime` before automated tests; association order follows Cantonese corpus frequency, not Windows.

Install with `scripts/install-windows.ps1`, `scripts/install-linux.sh` or, on macOS after `brew install --cask squirrel-app`, `scripts/install-macos.sh`. Code is MIT; dictionaries keep their upstream licenses.

Maintainer: KinFx. Prop-firm research, comparison tables, tool links and referral codes: <https://linktr.ee/kinfx>. Some of those are affiliate / referral links and the maintainer may earn a commission. They have nothing to do with this IME: the code is MIT and contains no referral, tracking or network code.
