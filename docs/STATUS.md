# KINFX IME — STATUS

**更新**：2026-10-15（Windows 選字：空白翻頁、Enter 確認、直列、Tab 展開、常用熱門環頁）

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

建議標籤 **v0.2.0**（空白同 Enter 嘅預設相對 v0.1.1 係破壞性變更，再加展開同熱門頁）。未打 tag。

## Next

1. 插螢幕 → 候選窗視覺驗收（desktop-verify）；核對每頁 9 粒
2. GUI 設定面板（配置層已開）
3. macOS Squirrel
4. P2 倉頡／注音／拼音
5. **M5 小寫混打（延後）**：路線 A melt_eng 次翻譯器。未入場原因：librime 候選 quality = `exp(weight) + initial_quality`，英文詞表未同速成權重量度過之前會搶 `me`／`or` 頭頁。下一版先做獨立詞表目錄＋原授權 NOTICE（唔併 GPL-3 rime-ice）、中文默認首位、唔開 `en_spacer`。
6. **關聯詞**（上屏後 Windows 嗰個 Shift+數字詞窗）未做。

## Blockers

- 候選窗視覺需顯示器
- 發佈前粵拼 CC BY／ODbL 署名包要齊

## How to test

```bash
./scripts/smoke-linux.sh
./scripts/install-linux.sh    # desktop
# docs/desktop-verify.md
```
