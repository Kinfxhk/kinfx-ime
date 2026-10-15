# KINFX 中英混打輸入法 — STATUS

**顯示名**：KINFX 中英混打輸入法（repo slug 仍係 `kinfx-ime`）  
**更新**：2026-10-15（頭頁改跟 Win 頭 9；呢次唔打 git tag）  
**版本**：**v0.3.1 已出**（Windows 選字 UX、詞／成語前綴、英詞 extras：scriptwriting／voiceover）。選字鍵仍係 v0.2.0 嗰套。  
**建議標籤 v0.3.2**：Windows 11 Weasel schema 部署（`docs/WINDOWS.md`、`scripts/install-windows.ps1`、`scripts/uninstall-windows.ps1`）同文件一齊出。呢次變更 **唔打 git tag**；Boss merge 之後先標。Win11 真機驗收未做。

Fcitx 選單：速成「KINFX 中英混打輸入法 · 速成」（`kinfx_quick`）、粵拼「KINFX 中英混打輸入法 · 粵拼」（`kinfx_jyutping`）。`schema_id` 冇改。

## Done

- [x] 可行性對齊（librime + Fcitx5；速成→粵拼）
- [x] Repo MIT + NOTICE
- [x] `docs/ARCHITECTURE.md`／`LAYOUTS.md`／**CONFIG.md**／**desktop-verify.md**
- [x] P0 `kinfx_quick`：HK 字頻權重、罕用字過濾（丂等）、z-code 剔除
- [x] P1 `kinfx_jyutping`：`jyut6ping3` 有聲調（`nei5`／`jyut6`）
- [x] **混打預設零切換**（uppercase／email／url）；Shift／ascii_mode 可選可改
- [x] Flex：`schemas/examples/*.custom.yaml.example`
- [x] `scripts/install-linux.sh`、`gen_quick_dict.py`、`smoke-linux.sh`、`verify-gui-mixed.sh`
- [x] Headless smoke：速成＋混打 M0＋排序＋過濾＋粵拼聲調
- [x] 候選預設 **每頁 9**、選字鍵 1–9（速成＋粵拼；install 亦改 `default.yaml`）
- [x] **頭頁跟 Microsoft 速成頭 9**（full-win-top9）：`hi` 第 1 係「凡」（「我」第 7）、`of` 第 1 係「伙」（「係」第 3）、`rr`「唔」第 9、`vd` 尾二「網綜」。唔再把常用字硬抬去第 1。`倉@or` 跟 Win，唔留頭頁。常用熱門只喺第 1 頁按左嘅環頁。見 `docs/WIN_QUICK_RANK.md`
- [x] **選字對齊 Windows**：直列；空白翻頁；1–9／Enter 選焦點；Tab 展開（當欄 1–9，註釋顯示其餘欄）；多頁碼「常用熱門」環頁。見 `docs/WIN_QUICK_SELECT.md`
- [x] `install-linux.sh`：`rime_deployer --build USER SHARED` 兩個參數；classicui 直列
- [x] Headless：K1–K4（空白／Enter／混打／熱門頁／Tab）同 v0.1.1 頭頁順位一齊跑
- [x] **詞庫驅動前綴**：`ofc`→無錯、`ofca`→無錯（全碼排名不高過前綴）。`gen_quick_phrases.py` 每字只取一個速成碼，唔笛卡爾爆。見 `docs/PHRASE_MIX.md`
- [x] **HK 詞／四字帶** 獨立 `lexicon/hk/`（essay-cantonese CC BY 4.0 + 速成碼 LGPL-3.0）
- [x] **英詞 M5**：`lexicon/en`（SCOWL，唔係 rime-ice）。`gmai`→Gmail；`scriptwriti`→scriptwriting、`voiceove`→voiceover（extras，權重跟 Gmail）；`len≥4` 或長度 3 全中先抬；`me`／`or`／`of` 唔出英詞
- [x] 選字鍵維持 v0.2.0：每頁 9、直列、空白翻頁、Enter 確認
- [x] **Windows 11 MVP（建議標籤 v0.3.2）**：Weasel（小狼毫）做 TSF 宿主；本 repo 交 schema 部署包（`docs/WINDOWS.md`、`scripts/install-windows.ps1`、`scripts/uninstall-windows.ps1`、`scripts/pack-windows-share.ps1`）。`schema_id` 仍然係 `kinfx_quick`／`kinfx_jyutping`。唔包含自寫 TSF DLL、純 MSIX TSF 註冊、DLL 注入、Weasel fork。**真機驗收未做。** 本 PR 唔打 tag。

v0.2.0 已標（空白翻頁／Enter 確認）。v0.3.0 已標（詞庫前綴）。**v0.3.1 已出**（英詞 extras：scriptwriting／voiceover；已併入 main）。**v0.3.2 建議標**（文件＋Windows 安裝腳本；等 Boss merge 後先打 tag）。

## Next

1. **Windows 11 真機驗收**（Weasel 重新部署後）：`ofc`→無錯、`gmai`→Gmail、`me`／`or`／`of` 中文首位、空白翻頁、Enter 確認。見 `docs/WINDOWS.md` 驗收表。腳本同文件已出；未喺 Win11 跑過。
2. 插螢幕 → 候選窗視覺驗收（desktop-verify）；核對每頁 9 粒
3. GUI 設定面板（配置層已開）
4. macOS Squirrel
5. P2 倉頡／注音／拼音
6. **關聯詞**（上屏後 Windows 嗰個 Shift+數字詞窗）未做。
7. 真四欄候選格（而家仍然係 Tab 註釋）未做。

## Blockers

- 候選窗視覺需顯示器
- Windows 11 真機驗收未做（Weasel + schema 包已寫；要 Win11 手動對 `docs/WINDOWS.md`）
- 發佈前粵拼 CC BY／ODbL 署名包要齊

## How to test

```bash
./scripts/smoke-linux.sh
./scripts/install-linux.sh    # desktop
# docs/desktop-verify.md
pwsh -NoProfile -File scripts/test-windows-rime.ps1   # schema-list merge; no Weasel binary
```

Windows 11 手動：`docs/WINDOWS.md`（`install-windows.ps1` → 重新部署 → Win+Space）。
