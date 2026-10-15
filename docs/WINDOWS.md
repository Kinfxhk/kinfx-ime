# KINFX 中英混打輸入法 — Windows 11

**建議標籤 v0.3.2**（文件同 Windows 安裝腳本一齊出）。呢個 PR **唔打 git tag**；Boss merge 之後先標。`schema_id` 仍然係 `kinfx_quick`／`kinfx_jyutping`。UX 仍然係 v0.3.1：每頁 9、直列、空白翻頁、1–9／Enter 選字、Tab 展開、零切換中英混打。

Windows 11 用 **Weasel（小狼毫）** 做 TSF 宿主。本 repo 只交 schema、詞庫、部署／卸載腳本同文件。唔包含自寫 TSF DLL、純 MSIX TSF 註冊、DLL 注入，亦唔 fork Weasel。

English: On Windows 11, KINFX rides on [Weasel](https://github.com/rime/weasel) (Rime's TSF front-end). This repository deploys schemas into the per-user Rime directory. It does not ship a text service. The installer also merges a lightweight rounded light/dark candidate skin; the list stays vertical, nine per page. Suggested tag **v0.3.2**; the tag is not created here.

## 點解係 Weasel

Microsoft 對 IME 嘅要求（[Input Method Editor requirements](https://learn.microsoft.com/en-us/windows/apps/develop/input/input-method-editor-requirements)）：

- 必須係 **TSF**（Text Services Framework）text service。現代 Windows **擋 IMM32** IME。
- 安裝要行 **`ITfInputProcessorProfileMgr::RegisterProfile`** 或 **`InstallLayoutOrTip`**。唔好自己寫 CTF registry。
- 要上機嘅 IME 需要 **Authenticode 簽章**。HKLM 註冊要提升權限。

| 路徑 | 呢次 |
| --- | --- |
| 自寫 TSF COM server | 唔做。要簽章、COM、InstallLayoutOrTip，唔係 MVP。 |
| **Weasel（rime/weasel）** | **MVP 宿主。** 官方 TSF 前端，winget／GitHub 有簽名安裝器，載入同一套 librime schema。 |
| 純 MSIX 註冊 TSF | 唔做。[Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/5995922/native-tsf-ime-pure-msix-deployment)：HKLM CTF 要 elevation，純 MSIX 唔可靠。 |
| Store | 日後原生 IME 通常經 Partner Center 交 **已簽章嘅 MSI／EXE**（可以彈 UAC），唔係純 MSIX TSF。呢次不上架。 |

小狼毫係獨立 **GPL** 程式。本 repo **唔嵌入、唔 fork** 佢嘅源碼；只係好似 Linux 用 Fcitx 咁，把 schema 放到用戶資料目錄。

## 前提

- Windows 11。
- Windows PowerShell 5.1 或 PowerShell 7。腳本係 UTF-8（帶 BOM），5.1 先讀到中文。
- [Weasel／小狼毫](https://github.com/rime/weasel/releases) 官方安裝包（內建 Lua；KINFX 嘅選字同詞庫靠 Lua）。請用近期正式版。

裝小狼毫（安裝器會要求系統管理員；schema 部署唔使）：

```powershell
winget install Rime.Weasel
```

或者去 https://github.com/rime/weasel/releases 行官方安裝器。裝完工作列會有「小狼毫／中州韻」圖示。

## 安裝 KINFX schema

用**平常打字嗰個 Windows 帳戶**跑，唔好「以系統管理員身分執行」。提升之後 `%APPDATA%` 可能係管理員設定檔，schema 會去錯用戶。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

腳本會：

1. 把 schema／Lua／詞庫複製到 **`%APPDATA%\Rime`**（Weasel 用戶目錄）。可以用 `-RimeUserDir` 或環境變數 `RIME_USER_DIR` 改位置。
2. 合併 **`default.custom.yaml`** 嘅 `schema_list`，加入 `kinfx_quick` 同 `kinfx_jyutping`。已有嘅其他方案保留；再跑一次唔會重複。
3. 如果搵到 Weasel 嘅 shared `default.yaml`，會把嗰張方案表併入 `schema_list`（已有項目留低、唔重複 id）。未裝小狼毫時可以先得 KINFX 兩項；裝完再跑一次會補回拼音／注音／倉頡，唔會清走用戶自己加嘅方案。
4. 合併 **`weasel.custom.yaml`** 嘅輕量候選窗皮膚（圓角、淺陰影、淺色／深色，直列）。其他補丁留低。見下面「候選窗外觀」。
5. 印下一步：重新部署。

**唔會**把本 repo 嘅 `schemas/default.yaml` 複製去用戶目錄。librime 用用戶目錄嘅 `default.yaml` **成個覆蓋** shared data。Weasel 嘅鍵位同標點留喺安裝目錄；我哋只用 `default.custom.yaml` 做補丁。

每頁 9 同直列寫喺 `kinfx_quick`／`kinfx_jyutping` 方案檔（`menu/page_size: 9`、`style/horizontal: false`）。安裝腳本**唔**改全域 `menu/page_size`，免得小狼毫其他方案被改頁數。Weasel 讀 schema 嘅 `style/horizontal`，所以唔使再寫 Fcitx 嗰個 `classicui.conf`。

複製嘅檔（同 `scripts/install-linux.sh` 嘅 KINFX 檔對齊，平鋪喺用戶目錄）：

| 用戶目錄 | 來源 |
| --- | --- |
| `kinfx_quick.schema.yaml`／`kinfx_quick.dict.yaml` | `schemas/kinfx-quick/` |
| `kinfx_jyutping.schema.yaml` | `schemas/kinfx-jyutping/` |
| `kinfx_quick_phrase.dict.yaml`、`kinfx_hk_words.dict.yaml`、`kinfx_hk_idioms.dict.yaml` | `lexicon/hk/` |
| `kinfx_en.dict.yaml` | `lexicon/en/` |
| `rime.lua`、`lua/*.lua` | `schemas/` |

詞庫授權見 `lexicon/NOTICE`，唔係 MIT。

## 候選窗外觀

安裝會把一份**輕量**皮膚合併進 **`%APPDATA%\Rime\weasel.custom.yaml`**。例檔係 `schemas/examples/weasel.custom.yaml.example`（分享 zip 都有）。外觀近現代 macOS：圓角、淺陰影、淺色 `kinfx_modern`、深色 `kinfx_modern_dark`（跟 Windows 淺色／深色，用 `color_scheme`／`color_scheme_dark`）。候選仍然**直列**（`style/horizontal: false`、`style/layout/type: vertical`）。每頁 9 仍然寫喺方案 `menu/page_size`。呢份皮膚**唔**改頁數、選字鍵、詞庫或排序。

### 低延遲／輕量皮膚

鍵入到候選窗要保持快，所以呢份皮膚只改配色同佈局數字：

- 冇點陣圖／大圖皮膚，冇動畫，冇材質模糊，冇逐鍵強制重繪嘅選項。
- 陰影半徑係 **8**（淺、靜態）。唔開 hover 高亮，唔開 `enhanced_position`，避免無謂嘅視窗搬移同重畫。Weasel 議題 [#1869](https://github.com/rime/weasel/issues/1869) 講狀態冇變就唔使再 `ShowWindow`／`SetWindowPos`；呢份設定唔會每按一鍵改狀態。
- 淺色／深色係兩套靜態配色。系統切換主題先換方案，唔係每按一鍵換一次。
- 字體用系統「Microsoft YaHei UI」，唔打包外掛字檔。
- 圓角同陰影要 **Weasel 0.15** 或更新。更舊嘅版本會忽略未知鍵，直列同配色名仍然有效。

標記係 `# kinfx-ime:weasel-skin begin`／`end`。再跑 `install-windows.ps1` 會用 repo 嘅皮膚更新呢段，並收走標記外同名嘅皮膚鍵（例如舊嘅 `style/color_scheme`）。`app_options` 等其他補丁留低。標記會放在 `patch:` 最尾，所以同名項以皮膚為準。

套用：安裝寫入之後要**重新部署**（腳本搵到 `WeaselDeployer.exe` 會自己跑 `/deploy`）。跟住先見到圓角同淺色／深色。

還原外觀、保留 KINFX 方案：打開 `%APPDATA%\Rime\weasel.custom.yaml`，刪由 begin 到 end 嘅整段，再重新部署。下次再跑安裝會寫返皮膚。

`uninstall-windows.ps1` 會一併刪呢段。如果檔入面淨係 KINFX 寫入嘅皮膚，會刪成個 `weasel.custom.yaml`。有其他補丁就留低個檔。

### 重新部署同揀方案

1. 工作列小狼毫圖示 → 右鍵 → **重新部署**。
   或者（路徑跟你部機嘅版本號）：

   ```text
   "C:\Program Files\Rime\weasel-<version>\WeaselDeployer.exe" /deploy
   ```

   腳本如果搵到 `WeaselDeployer.exe` 會自己跑 `/deploy`。唔想跑就加 `-NoDeploy`。
2. **Win+Space** 切到 **小狼毫／RIME**。
3. 方案選單揀 **KINFX 中英混打輸入法 · 速成**（`schema_id`：`kinfx_quick`）。
   粵拼係 **KINFX 中英混打輸入法 · 粵拼**（`kinfx_jyutping`）。

選單未見 KINFX：再部署一次，或者切走小狼毫再切返。部署日誌如果話搵唔到 `lua_processor`，請改裝最新官方 Weasel（要有 librime-lua）。

### 粵拼要另加 rime-cantonese

速成用本 repo 嘅碼表，加 Weasel 自帶嘅 `luna_pinyin`（反查）同 prelude（標點、鍵位）。

粵拼字典係 **`jyut6ping3`**，官方 Weasel **唔包**。未見到 `jyut6ping3.dict.yaml` 時，腳本只警告，速成仍然可以部署。粵拼要自己把 [rime-cantonese](https://github.com/rime/rime-cantonese) 嘅 `jyut6ping3*.yaml` 同 `essay-cantonese.txt` 放到 `%APPDATA%\Rime`（或 Weasel 嘅 shared data），再重新部署。留意粵拼資料嘅 CC BY／ODbL 署名（見 `NOTICE`）。

## 驗收（手動，真機）

部署完成、選咗速成之後：

| 輸入 | 預期 |
| --- | --- |
| `ofc` | 無錯（詞前綴） |
| `gmai` | Gmail |
| `me`／`or`／`of` | 中文首位，唔出英詞 |
| 空白 | 有候選窗時翻頁 |
| Enter | 確認焦點候選 |
| 1–9 | 選當頁第 1–9 個 |
| Tab | 展開 |

直列、每頁 9。大寫拉丁、email、URL 直出，唔使切英文模式。頭頁對照見 `docs/WIN_QUICK_RANK.md`。Flex 見 `docs/CONFIG.md`（例檔喺 `schemas/examples/`；分享 zip 未必包例檔）。

**真機驗收未做。** 呢份文件同腳本可以 review；Win11 上嘅目測要喺有小狼毫嘅機器跑。

## 卸載

只刪呢個用戶 Rime 目錄入面 KINFX 擁有嘅檔，同 `default.custom.yaml` 入面嘅 `kinfx_quick`／`kinfx_jyutping`。其他方案、Weasel 程式、其他 schema 留低。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall-windows.ps1
```

跟住再 **重新部署** 一次，方案選單先至會收走 KINFX。

會一併刪 `kinfx_quick`／`kinfx_jyutping` 嘅編譯產物同學習詞庫（`*.userdb`）。`rime.lua` 如果已被改到 `require` 其他模組，腳本會留低並警告。

卸 Weasel 本體（唔係卸 KINFX schema）：

- 設定 → 應用程式 → 小狼毫
- 或 `winget uninstall Rime.Weasel`

## 簽章、sideload、Store

- 而家係 **schema 包 + 用戶自己裝嘅 Weasel**。Repo **冇**憑證、私鑰、或 Store 上架檔。
- 日後如果做 KINFX 自己個安裝器，個 MSI／EXE 要 **Authenticode 簽章**，註冊 TSF 要用 RegisterProfile／InstallLayoutOrTip，唔好寫 registry，亦唔好靠純 MSIX。
- Microsoft Store 交原生 IME，典型係 Partner Center 嘅 **已簽章 MSI／EXE**（可帶 UAC）。純 MSIX 註冊 TSF 唔可靠，呢次唔做。
- Sideload 小狼毫請用上游官方安裝器或 `winget install Rime.Weasel`，唔好散佈改過嘅 Weasel DLL。

## 分享包

俾朋友嘅 zip 要保留目錄，等 `install-windows.ps1` 搵到 `schemas/` 同 `lexicon/`。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\pack-windows-share.ps1
```

產出 `dist/kinfx-ime-windows-share.zip`（`dist/` 唔入 git）。清單：

- `WINDOWS-SHARE.txt`（短步驟）
- `docs/WINDOWS.md`
- `scripts/install-windows.ps1`、`scripts/uninstall-windows.ps1`、`scripts/windows-rime.ps1`
- `schemas/kinfx-quick/` 嘅 schema＋碼表、`schemas/kinfx-jyutping/kinfx_jyutping.schema.yaml`
- `schemas/examples/weasel.custom.yaml.example`（候選窗輕量皮膚）
- `schemas/rime.lua`、`schemas/lua/*.lua`
- `lexicon/` 詞庫同 `lexicon/NOTICE`
- `LICENSE`、`NOTICE`、`licenses/rime-quick-LGPL-3.0.txt`

朋友：裝 Weasel → 解壓 → 跑 `install-windows.ps1` → 重新部署 → Win+Space。唔好把憑證或私鑰放進 zip。

## 故障

| 現象 | 處理 |
| --- | --- |
| 腳本話缺來源檔 | 喺 repo 根或解壓後嘅分享包入面跑，唔好淨係抄走一個 `.ps1`。 |
| `default.custom.yaml` 係一行 `patch:` | 腳本會停低。改成 `patch:` 自己一行再跑，或者手動把兩個 `schema_id` 加進 `schema_list`。 |
| 方案選單冇 KINFX | 重新部署。確認檔喺 `%APPDATA%\Rime`，而且係打字嗰個用戶。 |
| 粵拼部署失敗 | 補 `jyut6ping3`（見上）。速成唔依賴佢。 |
| 反引號反查冇拼音 | Weasel data 目錄要有 `luna_pinyin`。正常安裝已有。 |
| Lua 組件缺失 | 改裝最新官方 Weasel。 |
| 候選窗仍然係舊方框 | 重新部署。確認 `%APPDATA%\Rime\weasel.custom.yaml` 有 `kinfx-ime:weasel-skin`，而且係 Weasel 0.15 或更新。淺色／深色跟系統主題。 |
| 想拆皮膚但保留方案 | 刪 `weasel.custom.yaml` 入面嘅 begin／end 標記段，再重新部署。唔好淨係靠卸載：`uninstall-windows.ps1` 會連 schema 一齊收走。 |
