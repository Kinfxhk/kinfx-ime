# KINFX IME — STATUS

**更新**：2026-10-15 17:12 HKT（Asia/Taipei）

## Done

- [x] 可行性對齊（librime + Fcitx5；速成→粵拼；見 open-source-ime-feasibility.md）
- [x] Repo：`/workspace/oss/kinfx-ime/`（MIT + NOTICE）
- [x] `docs/ARCHITECTURE.md` — 混打硬驗收 + **候選窗唔擋游標**（below／flip／follow-caret）
- [x] `docs/LAYOUTS.md` — `win_quick`（預設）／`classic_common` 字根表
- [x] P0 `kinfx_quick`：schema + 生成碼表（~77k；夏=me／好=vd／倉=or）
- [x] P1 `kinfx_jyutping` overlay（系統 jyutping 詞典）
- [x] `third_party/rime-quick/`（LGPL-3 上游參考）
- [x] `scripts/install-linux.sh`、`scripts/gen_quick_dict.py`
- [x] **Headless smoke PASS**：`./tests/run_smoke.sh` → me→夏、vd→好、or→倉
- [x] 混打驗收清單：`tests/ACCEPTANCE_MIXED_INPUT.md`

## Working on this box

| 項目 | 結果 |
| --- | --- |
| librime／碼表套件 | 已裝 |
| Headless 速成候選 | **PASS** |
| GUI Fcitx5 實打 | 無顯示會話 — 未做 |
| 候選窗視覺驗收 | 未做（已寫入架構預設） |
| 混打 M1–M3 實機 | 未做（schema 已設 `inline_ascii`） |

## Next

1. 桌面：`fcitx5-rime` + install script；速成實打 + 混打 M1–M3 + 候選窗 below／flip  
2. 速成候選排序／常用字打磨（對齊 Windows 體驗，非 1:1 演算法）  
3. 粵拼實測；可選升級 rime-cantonese  
4. macOS Squirrel 載入同 schema  
5. P2 倉頡／注音／拼音；按鍵聲；聯想；M5 自動判語  
6. Win／Android／iOS

## Blockers

- Headless VM 無 Fcitx5 GUI  
- 發佈前粵拼 CC BY／ODbL 署名包要齊  
- MS 候選排序無法開源複製

## How to test

```bash
cd /workspace/oss/kinfx-ime
./tests/run_smoke.sh          # headless PASS expected
./scripts/install-linux.sh    # desktop user dir
# then Fcitx5 → 中州韻 → KINFX 速成
```
