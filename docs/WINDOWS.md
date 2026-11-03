# KINFX 中英混打輸入法 — Windows 11

**v0.4.0**。`schema_id` 是 `kinfx_quick`／`kinfx_jyutping`。候選次序逐頁跟 Windows 11 微軟速成；每頁 9、直列、空白翻頁、1–9／Enter 選字、Tab 展開、零切換中英混打。

Windows 11 用 **Weasel（小狼毫）** 做 TSF 宿主。本 repo 只交 schema、詞庫、部署／卸載腳本和文件。不包含自寫 TSF DLL、純 MSIX TSF 註冊、DLL 注入，也不 fork Weasel。

English: On Windows 11, KINFX rides on [Weasel](https://github.com/rime/weasel) (Rime's TSF front-end). This repository deploys schemas into the per-user Rime directory. It does not ship a text service. The installer also merges a lightweight rounded light/dark candidate skin; the list stays vertical, nine per page, in Windows 11 Microsoft Quick order on every page (v0.4.0).

## 為什麼是 Weasel

Microsoft 對 IME 的要求（[Input Method Editor requirements](https://learn.microsoft.com/en-us/windows/apps/develop/input/input-method-editor-requirements)）：

- 必須是 **TSF**（Text Services Framework）text service。現代 Windows **擋 IMM32** IME。
- 安裝要執行 **`ITfInputProcessorProfileMgr::RegisterProfile`** 或 **`InstallLayoutOrTip`**。不要自己寫 CTF registry。
- 要上機的 IME 需要 **Authenticode 簽章**。HKLM 註冊要提升權限。

| 路徑 | 這次 |
| --- | --- |
| 自寫 TSF COM server | 不做。要簽章、COM、InstallLayoutOrTip，不是 MVP。 |
| **Weasel（rime/weasel）** | **MVP 宿主。** 官方 TSF 前端，winget／GitHub 有簽名安裝器，載入同一套 librime schema。 |
| 純 MSIX 註冊 TSF | 不做。[Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/5995922/native-tsf-ime-pure-msix-deployment)：HKLM CTF 要 elevation，純 MSIX 不可靠。 |
| Store | 日後原生 IME 通常經 Partner Center 交 **已簽章的 MSI／EXE**（可以彈出 UAC），不是純 MSIX TSF。這次不上架。 |

小狼毫是獨立 **GPL** 程式。本 repo **不嵌入、不 fork** 它的源碼；只是像 Linux 用 Fcitx 那樣，把 schema 放到用戶資料目錄。

## 前提

- Windows 11。
- Windows PowerShell 5.1 或 PowerShell 7。腳本是 UTF-8（帶 BOM），5.1 才讀得到中文。
- [Weasel／小狼毫](https://github.com/rime/weasel/releases) 官方安裝包（內建 Lua；KINFX 的選字和詞庫靠 Lua）。請用近期正式版。

裝小狼毫（安裝器會要求系統管理員；schema 部署不必）：

```powershell
winget install Rime.Weasel
```

或者到 https://github.com/rime/weasel/releases 執行官方安裝器。裝完工作列會有「小狼毫／中州韻」圖示。

## 安裝 KINFX schema

用**平常打字的那個 Windows 帳戶**執行，不要「以系統管理員身分執行」。提升之後 `%APPDATA%` 可能是管理員設定檔，schema 會放到錯誤的用戶。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

腳本會：

1. 把 schema／Lua／詞庫複製到 **`%APPDATA%\Rime`**（Weasel 用戶目錄）。可以用 `-RimeUserDir` 或環境變數 `RIME_USER_DIR` 改位置。
2. 合併 **`default.custom.yaml`** 的 `schema_list`，加入 `kinfx_quick` 和 `kinfx_jyutping`。已有的其他方案保留；再執行一次不會重複。
3. 如果找到 Weasel 的 shared `default.yaml`，會把那張方案表併入 `schema_list`（已有項目保留、不重複 id）。未裝小狼毫時可以先只有 KINFX 兩項；裝完再執行一次會補回拼音／注音／倉頡，不會清除用戶自己加入的方案。
4. 合併 **`weasel.custom.yaml`** 的輕量候選窗皮膚（圓角、淺陰影、淺色／深色，直列）。其他補丁保留。見下面「候選窗外觀」。
5. 印出下一步：重新部署。

**不會**把本 repo 的 `schemas/default.yaml` 複製到用戶目錄。librime 用用戶目錄的 `default.yaml` **整份覆蓋** shared data。Weasel 的鍵位和標點留在安裝目錄；我們只用 `default.custom.yaml` 做補丁。

每頁 9 和直列寫在 `kinfx_quick`／`kinfx_jyutping` 方案檔（`menu/page_size: 9`、`style/horizontal: false`）。安裝腳本**不**改全域 `menu/page_size`，免得小狼毫其他方案被改頁數。Weasel 讀 schema 的 `style/horizontal`，所以不必再寫 Fcitx 那個 `classicui.conf`。

複製的檔案（與 `scripts/install-linux.sh` 的 KINFX 檔案對齊，平鋪在用戶目錄）：

| 用戶目錄 | 來源 |
| --- | --- |
| `kinfx_quick.schema.yaml`／`kinfx_quick.dict.yaml` | `schemas/kinfx-quick/` |
| `kinfx_phrase.schema.yaml`／`kinfx_en.schema.yaml`（只用來編譯詞表，不必選） | `schemas/kinfx-quick/` |
| `kinfx_capture.txt`（詞語留鍵清單） | `lexicon/hk/` |
| `kinfx_jyutping.schema.yaml` | `schemas/kinfx-jyutping/` |
| `kinfx_quick_phrase.dict.yaml`、`kinfx_hk_words.dict.yaml`、`kinfx_hk_idioms.dict.yaml` | `lexicon/hk/` |
| `kinfx_en.dict.yaml` | `lexicon/en/` |
| `rime.lua`、`lua/win_quick.lua`、`lua/phrase_mix.lua` | `schemas/` |

v0.4 升級時，安裝腳本會刪除舊版的 `lua/melt_eng.lua`、`lua/lexicon_index.lua`。

詞庫授權見 `lexicon/NOTICE`，不是 MIT。

## 候選窗外觀

安裝會把一份**輕量**皮膚合併進 **`%APPDATA%\Rime\weasel.custom.yaml`**。例檔是 `schemas/examples/weasel.custom.yaml.example`（分享 zip 也有）。外觀近現代 macOS：圓角、淺陰影、淺色 `kinfx_modern`、深色 `kinfx_modern_dark`（跟 Windows 淺色／深色，用 `color_scheme`／`color_scheme_dark`）。候選仍然**直列**（`style/horizontal: false`、`style/layout/type: vertical`）。每頁 9 仍然寫在方案 `menu/page_size`。這份皮膚**不**改頁數、選字鍵、詞庫或排序。

### 低延遲／輕量皮膚

由按鍵到候選窗要保持快，所以這份皮膚只改配色和佈局數字：

- 沒有點陣圖／大圖皮膚，沒有動畫，沒有材質模糊，沒有逐鍵強制重繪的選項。
- 陰影半徑是 **8**（淺、靜態）。不開啟 hover 高亮，不開啟 `enhanced_position`，避免無謂的視窗搬移和重畫。Weasel 議題 [#1869](https://github.com/rime/weasel/issues/1869) 說明狀態沒有變化就不必再 `ShowWindow`／`SetWindowPos`；這份設定不會每按一鍵改狀態。
- 淺色／深色是兩套靜態配色。系統切換主題時才換方案，不是每按一鍵換一次。
- 字體用系統「Microsoft YaHei UI」，不打包外掛字檔。
- 圓角和陰影要 **Weasel 0.15** 或更新。更舊的版本會忽略未知鍵，直列和配色名仍然有效。

標記是 `# kinfx-ime:weasel-skin begin`／`end`。再執行 `install-windows.ps1` 會用 repo 的皮膚更新這段，並移除標記外同名的皮膚鍵（例如舊的 `style/color_scheme`）。`app_options` 等其他補丁保留。標記會放在 `patch:` 最末，所以同名項以皮膚為準。

套用：安裝寫入之後要**重新部署**（腳本找到 `WeaselDeployer.exe` 會自行執行 `/deploy`）。然後才看得到圓角和淺色／深色。

還原外觀、保留 KINFX 方案：打開 `%APPDATA%\Rime\weasel.custom.yaml`，刪除由 begin 到 end 的整段，再重新部署。下次再執行安裝會寫回皮膚。

`uninstall-windows.ps1` 會一併刪除這段。如果檔案內只有 KINFX 寫入的皮膚，會刪除整個 `weasel.custom.yaml`。有其他補丁就保留該檔案。

### 重新部署和選方案

1. 工作列小狼毫圖示 → 右鍵 → **重新部署**。
   或者（路徑依該電腦的版本號）：

   ```text
   "C:\Program Files\Rime\weasel-<version>\WeaselDeployer.exe" /deploy
   ```

   腳本如果找到 `WeaselDeployer.exe` 會自行執行 `/deploy`。不想執行就加 `-NoDeploy`。
2. **Win+Space** 切換到 **小狼毫／RIME**。
3. 方案選單選 **KINFX 中英混打輸入法 · 速成**（`schema_id`：`kinfx_quick`）。
   粵拼是 **KINFX 中英混打輸入法 · 粵拼**（`kinfx_jyutping`）。

選單未見 KINFX：再部署一次，或者切換離開小狼毫再切回。部署日誌如果顯示找不到 `lua_processor`，請改裝最新官方 Weasel（要有 librime-lua）。

### 粵拼要另加 rime-cantonese

速成用本 repo 的碼表，加 Weasel 自帶的 `luna_pinyin`（反查）和 prelude（標點、鍵位）。

粵拼字典是 **`jyut6ping3`**，官方 Weasel **不包含**。未見到 `jyut6ping3.dict.yaml` 時，腳本只警告，速成仍然可以部署。粵拼要自己把 [rime-cantonese](https://github.com/rime/rime-cantonese) 的 `jyut6ping3*.yaml` 和 `essay-cantonese.txt` 放到 `%APPDATA%\Rime`（或 Weasel 的 shared data），再重新部署。留意粵拼資料的 CC BY／ODbL 署名（見 `NOTICE`）。

## 驗收（手動，真機）

部署完成、選了速成之後：

| 輸入 | 預期 |
| --- | --- |
| `vd` 空白 1 | 嫻（第 2 頁，與 Windows 相同） |
| `vd` `of` 3 | 好係（Windows 頂字） |
| `ofc` 1／2 | 人類／無錯 |
| `ofca` 1 | 無錯 |
| `gmai` | Gmail |
| `me`／`or`／`of` | 中文首位，不輸出英詞 |
| 空白 | 有候選窗時翻頁 |
| Enter | 確認焦點候選 |
| 1–9 | 選當頁第 1–9 個 |
| Tab | 展開 |

直列、每頁 9。大寫拉丁、email、URL 直出，不必切換英文模式。頭頁對照見 `docs/WIN_QUICK_RANK.md`。Flex 見 `docs/CONFIG.md`（例檔在 `schemas/examples/`；分享 zip 未必包例檔）。

**真機驗收（2026-10-16，Windows 11 Pro + 小狼毫 0.17.4）：26／26 通過。**

## 卸載

只刪除這個用戶 Rime 目錄內 KINFX 擁有的檔案，以及 `default.custom.yaml` 內的 `kinfx_quick`／`kinfx_jyutping`。其他方案、Weasel 程式、其他 schema 保留。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall-windows.ps1
```

接著再 **重新部署** 一次，方案選單才會移除 KINFX。

會一併刪除 `kinfx_quick`／`kinfx_jyutping` 的編譯產物和學習詞庫（`*.userdb`）。`rime.lua` 如果已被改到 `require` 其他模組，腳本會保留並警告。

解除安裝 Weasel 本體（不是解除安裝 KINFX schema）：

- 設定 → 應用程式 → 小狼毫
- 或 `winget uninstall Rime.Weasel`

## 簽章、sideload、Store

- 現在是 **schema 包 + 用戶自己安裝的 Weasel**。Repo **沒有**憑證、私鑰、或 Store 上架檔案。
- 日後如果做 KINFX 自己的安裝器，該 MSI／EXE 要 **Authenticode 簽章**，註冊 TSF 要用 RegisterProfile／InstallLayoutOrTip，不要寫 registry，也不要依賴純 MSIX。
- Microsoft Store 交原生 IME，典型是 Partner Center 的 **已簽章 MSI／EXE**（可帶 UAC）。純 MSIX 註冊 TSF 不可靠，這次不做。
- Sideload 小狼毫請用上游官方安裝器或 `winget install Rime.Weasel`，不要散布改過的 Weasel DLL。

## 分享包

給朋友的 zip 要保留目錄，讓 `install-windows.ps1` 找到 `schemas/` 和 `lexicon/`。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\pack-windows-share.ps1
```

產出 `dist/kinfx-ime-windows-share.zip`（`dist/` 不納入 git）。清單：

- `WINDOWS-SHARE.txt`（短步驟）
- `docs/WINDOWS.md`
- `scripts/install-windows.ps1`、`scripts/uninstall-windows.ps1`、`scripts/windows-rime.ps1`
- `schemas/kinfx-quick/` 的 schema＋碼表、`schemas/kinfx-jyutping/kinfx_jyutping.schema.yaml`
- `schemas/examples/weasel.custom.yaml.example`（候選窗輕量皮膚）
- `schemas/rime.lua`、`schemas/lua/*.lua`
- `lexicon/` 詞庫和 `lexicon/NOTICE`
- `LICENSE`、`NOTICE`、`licenses/rime-quick-LGPL-3.0.txt`

朋友：裝 Weasel → 解壓 → 執行 `install-windows.ps1` → 重新部署 → Win+Space。不要把憑證或私鑰放進 zip。

## 故障

| 現象 | 處理 |
| --- | --- |
| 腳本提示缺少來源檔 | 在 repo 根目錄或解壓後的分享包內執行，不要只複製一個 `.ps1`。 |
| `default.custom.yaml` 是一行 `patch:` | 腳本會停止。改成 `patch:` 自己一行再執行，或者手動把兩個 `schema_id` 加進 `schema_list`。 |
| 方案選單沒有 KINFX | 重新部署。確認檔案在 `%APPDATA%\Rime`，而且是打字的那個用戶。 |
| 粵拼部署失敗 | 補 `jyut6ping3`（見上）。速成不依賴它。 |
| 反引號反查沒有拼音 | Weasel data 目錄要有 `luna_pinyin`。正常安裝已有。 |
| Lua 組件缺失 | 改裝最新官方 Weasel。 |
| 候選窗仍然是舊方框 | 重新部署。確認 `%APPDATA%\Rime\weasel.custom.yaml` 有 `kinfx-ime:weasel-skin`，而且是 Weasel 0.15 或更新。淺色／深色跟系統主題。 |
| 想拆皮膚但保留方案 | 刪除 `weasel.custom.yaml` 內的 begin／end 標記段，再重新部署。不要只靠解除安裝：`uninstall-windows.ps1` 會連 schema 一併移除。 |
