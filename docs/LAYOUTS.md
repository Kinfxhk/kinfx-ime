# KINFX IME — 鍵盤排列（LAYOUTS）

**日期**：2026-10-15（Asia/Taipei）

## 1. 速成／倉頡字根鍵盤（Windows 慣用 = 預設）

微軟速成（Microsoft Quick）與倉頡共用同一套字根→美式 QWERTY 鍵位。  
來源：[Microsoft Learn — Traditional Chinese IME](https://learn.microsoft.com/en-us/globalization/input/traditional-chinese-ime)、速成字典公開字根表。

### 1.1 `win_quick`（預設／Windows 慣用）

```
Q手  W田  E水  R口  T廿  Y卜  U山  I戈  O人  P心
 A日  S尸  D木  F火  G土  H竹  J十  K大  L中
  Z重  X難  C金  V女  B月  N弓  M一
```

字母對照（A–Z）：

| 鍵 | 字根 | 鍵 | 字根 | 鍵 | 字根 | 鍵 | 字根 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A | 日 | B | 月 | C | 金 | D | 木 |
| E | 水 | F | 火 | G | 土 | H | 竹 |
| I | 戈 | J | 十 | K | 大 | L | 中 |
| M | 一 | N | 弓 | O | 人 | P | 心 |
| Q | 手 | R | 口 | S | 尸 | T | 廿 |
| U | 山 | V | 女 | W | 田 | X | 難 |
| Y | 卜 | Z | 重 |  |  |  |  |

**速成取碼**：倉頡全碼嘅**首碼 + 尾碼**（最多兩鍵）。例：

| 字 | 倉頡 | 速成 | 鍵 |
| --- | --- | --- | --- |
| 夏 | 一山竹水（MUHE） | 一水 | `ME` |
| 天 | 一大（MK） | 一大 | `MK` |
| 好 | 女弓木（VND） | 女木 | `VD` |
| 倉 | 人戈日口（OIAR） | 人口 | `OR` |
| 日 | 日（A） | 日 | `A` |

本 repo `kinfx_quick` **預設即 `win_quick`**（與 MS Quick 字根一致）。  
候選排序無法 1:1 複製微軟專有演算法——只做**體驗對齊**。

### 1.2 `classic_common`（常用／教材常見）

與 `win_quick` **同一字根鍵位**（華語區教材、五色倉頡／速成字典、RIME cangjie5／quick 皆此圖）。  
產品用兩個 **layout id** 方便設定 UI 同測試矩陣；目前 keymap **相同**，差異預留：

| layout id | 用途 | 現況 |
| --- | --- | --- |
| `win_quick` | 對齊 Windows 微軟速成／倉頡 | 預設；碼表已生成 |
| `classic_common` | 「常用排列」文案／說明圖 | 同鍵位；可掛不同說明／練習 |
| `mac_sucheng`（後期） | 對照 macOS「速成 - 繁體」 | 字根通常同；系統捷徑不同 |

若日後發現某發行版「倚天倉頡」等變體鍵位，另開 `eten_cangjie` 表，**唔好暗改** `win_quick`。

### 1.3 倉頡（P2）

全碼最多五碼；字根表同上。Schema 將用 `cangjie5` 系，layout 選項繼承 `win_quick`／`classic_common`。

## 2. 注音（P2）— Windows／常用 layout 名

對齊 Microsoft Bopomofo 與 McBopomofo 公開選項：

| layout id | 名稱 | 備註 |
| --- | --- | --- |
| `bopomofo_standard` | 標準 | 必須 |
| `bopomofo_eten` | 倚天 | 必須 |
| `bopomofo_hanyu` | 漢語拼音鍵位 | 應有 |
| `bopomofo_eten26` 等 | 倚天26／許氏／IBM | 後期 |

## 3. 粵拼／拼音

粵拼、普通話拼音用標準字母鍵；無獨立「Windows 形碼排列」。混打行為見 ARCHITECTURE §3。

## 4. 候選窗位置（與排列無關嘅硬 UX）

詳見 `ARCHITECTURE.md` §4。摘要：

- **Follow caret**；預設 **below**；螢幕邊緣 **flip above/below**。  
- 垂直 gap，避免遮 preedit／當行。  
- Linux Fcitx5／後期 macOS 殼皆列為驗收。  
- Wayland：依賴 text-input／kimpanel／client popup；文件警告已知錯位應用（Snap 瀏覽器等）。

## 5. 設定鍵（產品）

```yaml
# 概念配置（前端／custom patch）
kinfx:
  layout: win_quick          # win_quick | classic_common | …
  candidate:
    placement: below_caret   # below_caret | above_caret | auto_flip
    gap_px: 4
    follow_cursor: true
  mixed_input:
    shift_l: inline_ascii    # 見 ascii_composer
```

## English

Default **Windows Quick** radical map (A=日 … M=一). Sucheng = first+last Cangjie codes. Candidate UI: **never cover the caret**; below-first with edge flip.
