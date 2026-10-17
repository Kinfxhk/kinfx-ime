# Linux VM v0.5 實測清單（交 Mac 側 Hermes）

對象：v0.5（`feat/v0.5-english` 最新 commit）。部署 `scripts/install-linux.sh`，
乾淨 userdb，fcitx5 + gedit，kernel-level replay（ydotool），byte-exact 對比。
聯想詞測速成單字；英文詞測 smart mode 預設。

## L1 — Fcitx5 預設左 Shift（短詞）

- `of` 撳左 Shift → 結果？（fcitx5-rime 收到左 Shift 定係切走輸入法；切走時會唔會上屏字母）
- 記錄：最終文字、切換次數。

## L2 — 空白上屏安全詞

- `the` 空白 → `the `
- `startup` 空白 → `startup `
- `hello` 空白 → `hello `

## L3 — 空白唔上屏（unsafe／2 碼）

- `door` 空白 → 翻頁，唔上屏英文
- `of` 空白 → 翻頁，唔上屏英文

## L4 — 解除 Fcitx5 左 Shift 熱鍵後重測 L1

- 喺 `fcitx5-configtool` 解除左 Shift 嘅切換熱鍵，重測 L1。

## L5 — `english/commit_key: Caps_Lock`

- patch `english/commit_key: Caps_Lock`，`of` 撳 Caps Lock → `of`（重測 L1）。

## L6 — 505 字文章重打

- 用 v0.4.0 嗰篇 505 字文章（`LINUX-VM-EVAL-final4.txt`）重打，v0.5 smart mode，
  byte-exact（唯一容許差異＝gedit 檔尾換行）。

## L7 — 聯想詞

- `hi7` 揀「我」→ 出跟尾詞（同講望見…）
- `hi7` Shift+2 → 我講（Shift+數字揀）
- `hi7` 1 → 我1（普通數字直打，唔揀）
- `hi7` 空白 空白 → 我（空白翻頁，吞咗，冇空格）
- `ofc1` → 人類（詞語上屏，唔出聯想）
- `vd1` 空白 空白 Shift+1 → 好＋第 2 頁第 1 個聯想（如 Windows `vd1␣␣Shift+1` → 好過）

## v0.5.1 重測重點（2026-10-17 報告跟進）

- 先執行 `scripts/linux-free-left-shift.sh`（只移除 Shift_L 熱鍵，Ctrl+Space 保留），再測 L1／L4。
- R1：`vd` 1 `.` → 好。；`hi` 7 `.` → 我。；`ofc` 1 `.` → 人類。
- R2：`vd` 1 空白 `startup` 空白 → `好 startup `（英詞前後空格各一）
- R3：`passion` 空白 → `passion `；`rr` 1 `passion` 空白 → `呂passion `
- R4：`ni` 3 → 多（Windows `ni` 第 3 個）；`vdni` 3 → 好多人。如果仍然出「夀」，請記低嗰一刻實際按鍵（夀＝`gi` 第 33 個）
- R5：預設 `association/space: type`：`vd` 1 空白 空白 → `好  `。`association/space: page` 時 `vd` 1 空白 空白 Shift+1 → 好笑（KINFX 聯想表用 essay-cantonese 頻率，唔係 Windows 聯想次序）
- L6：505 字文章重打，期望 byte-exact
- 唔使再測 L5（Caps Lock 已改為唔建議）

## 自動化提示（2026-10-17 VM 驗收）

- 空白上屏英文已帶尾隨空格；計劃檔英文詞後唔好再加空白 token。
- 開始前執行 `fcitx5-remote -s rime`（新 input context 有時係 keyboard-us）。
- v0.5.1 驗收結果：「。」9/9、passion、短詞左 Shift、505 字文章全形標點一致、去空格後 453/453、30 個英詞全中。

## 交回格式

每項寫：實際結果、同期望差幾多、Fcitx5 左 Shift 有冇切走輸入法。報告放 repo root
`LINUX-VM-EVAL-<date>.md`（唔好 commit）。
