# KINFX IME — STATUS

**更新**：2026-10-15（英詞 extras：scriptwriting／voiceover；選字鍵仍係 v0.2.0）

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
- [x] Windows 頭頁體驗對齊：`夏@me` 第 5、`倉@or` 留喺第一頁；`我`／`時`／`好` 仍第 1。見 `docs/WIN_QUICK_RANK.md`
- [x] **選字對齊 Windows**：直列；空白翻頁；1–9／Enter 選焦點；Tab 展開（當欄 1–9，註釋顯示其餘欄）；多頁碼「常用熱門」環頁。見 `docs/WIN_QUICK_SELECT.md`
- [x] `install-linux.sh`：`rime_deployer --build USER SHARED` 兩個參數；classicui 直列
- [x] Headless：K1–K4（空白／Enter／混打／熱門頁／Tab）同 v0.1.1 頭頁順位一齊跑
- [x] **詞庫驅動前綴**：`ofc`→無錯、`ofca`→無錯（全碼排名不高過前綴）。`gen_quick_phrases.py` 每字只取一個速成碼，唔笛卡爾爆。見 `docs/PHRASE_MIX.md`
- [x] **HK 詞／四字帶** 獨立 `lexicon/hk/`（essay-cantonese CC BY 4.0 + 速成碼 LGPL-3.0）
- [x] **英詞 M5**：`lexicon/en`（SCOWL，唔係 rime-ice）。`gmai`→Gmail；`scriptwriti`→scriptwriting、`voiceove`→voiceover（extras，權重跟 Gmail）；`len≥4` 或長度 3 全中先抬；`me`／`or`／`of` 唔出英詞
- [x] 選字鍵維持 v0.2.0：每頁 9、直列、空白翻頁、Enter 確認

v0.2.0 已標（空白翻頁／Enter 確認）。v0.3.0 係詞庫前綴。本分支建議標籤 **v0.3.1**（英詞 extras：scriptwriting／voiceover）。

## Next

1. 插螢幕 → 候選窗視覺驗收（desktop-verify）；核對每頁 9 粒
2. GUI 設定面板（配置層已開）
3. macOS Squirrel
4. P2 倉頡／注音／拼音
5. **關聯詞**（上屏後 Windows 嗰個 Shift+數字詞窗）未做。
6. 真四欄候選格（而家仍然係 Tab 註釋）未做。

## Blockers

- 候選窗視覺需顯示器
- 發佈前粵拼 CC BY／ODbL 署名包要齊

## How to test

```bash
./scripts/smoke-linux.sh
./scripts/install-linux.sh    # desktop
# docs/desktop-verify.md
```
