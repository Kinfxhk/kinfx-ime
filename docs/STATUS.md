# KINFX IME — STATUS

**更新**：2026-10-15 18:15 HKT（Asia/Taipei）

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

## Next

1. 插螢幕 → 候選窗視覺驗收（desktop-verify）
2. GUI 設定面板（配置層已開）
3. macOS Squirrel
4. P2 倉頡／注音／拼音；M5 自動判語

## Blockers

- 候選窗視覺需顯示器
- 發佈前粵拼 CC BY／ODbL 署名包要齊

## How to test

```bash
./scripts/smoke-linux.sh
./scripts/install-linux.sh    # desktop
# docs/desktop-verify.md
```
