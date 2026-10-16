# v0.5 離線比對（tools/rimeh/compare.py）

日期：2026-10-17。對照組 control＝`english/mode: shift`（v0.4.1 行為）；實驗組 smart＝預設值；兩組都關閉聯想同常用熱門頁。

- 兩碼碼數：658；英文詞：73323；空白不安全詞：351
- 比對序列：1904967（全部兩碼＋兩碼，加三段連打抽樣，每組帶結尾鍵）

## smart 對 control（嚴格分類）

「設計內」只限：前面已頂字嘅兩碼照 Windows 上屏，之後 3 個字母或以上嘅空白安全英文詞，遇空白或標點上屏成英文，而對照組冇用中文詞語留住呢串字母。

- 差異總數：22036
- 設計內：22036（每 1 萬組序列 115.68 組）
- 意外差異：0（必須為 0）
- 中文改變：0（必須為 0）

## 文章重打（smart）

- 中文字數：20000；英文詞：735，正確 735
- 空白規則撞中文（設計內，逐個列出）：1（每 1 萬中文字 0.50；模型估計見 kinfx_en_unsafe.txt 檔頭）
- 其他中文改變：0（必須為 0）

  - `jl3furs{space}7kyor{space}{space}2rh5rr9mv3mrbrip7yq3obwcmfm…` smart=[都furs 7疼個呀唔要可同鹿達內四不不速長學寬人] control=[都光嘞疼個呀唔要可同鹿達內四不不速長學寬人]

- 聯想（assoc 對 smart）差異：0

### 設計內差異（前 40 個）

- `abbr{space}1` smart=[abbr 1] control=[明賂]
- `abbr{comma}` smart=[abbr，] control=[明同，]
- `abbr{space}{space}2` smart=[abbr  2] control=[明贍]
- `abet{space}1` smart=[abet 1] control=[明濫]
- `abet{comma}` smart=[abet，] control=[明泣，]
- `abet{space}{space}2` smart=[abet  2] control=[明湓]
- `able{comma}` smart=[able，] control=[明版，]
- `able{space}1` smart=[able 1] control=[明衼]
- `able{space}{space}2` smart=[able  2] control=[明蝮]
- `ably{space}{space}2` smart=[ably  2] control=[明补]
- `ably{space}1` smart=[ably 1] control=[明袇]
- `ably{comma}` smart=[ably，] control=[明非，]
- `abut{space}1` smart=[abut 1] control=[明豓]
- `abut{comma}` smart=[abut，] control=[明豈，]
- `abut{space}{space}2` smart=[abut  2] control=[明峅]
- `acct{space}1` smart=[acct 1] control=[暝錛]
- `acct{comma}` smart=[acct，] control=[暝盆，]
- `acct{space}{space}2` smart=[acct  2] control=[暝鐦]
- `aced{space}1` smart=[aced 1] control=[暝淳]
- `aced{comma}` smart=[aced，] control=[暝汙，]
- `aced{space}{space}2` smart=[aced  2] control=[暝澡]
- `aces{space}1` smart=[aces 1] control=[暝泑]
- `aces{comma}` smart=[aces，] control=[暝污，]
- `aces{space}{space}2` smart=[aces  2] control=[暝泎]
- `ache{space}1` smart=[ache 1] control=[暝舨]
- `ache{comma}` smart=[ache，] control=[暝反，]
- `ache{space}{space}2` smart=[ache  2] control=[暝馥]
- `achy{space}1` smart=[achy 1] control=[暝毴]
- `achy{comma}` smart=[achy，] control=[暝冬，]
- `achy{space}{space}2` smart=[achy  2] control=[暝忄]
- `acid{comma}` smart=[acid，] control=[暝床，]
- `acid{space}1` smart=[acid 1] control=[暝栥]
- `acid{space}{space}2` smart=[acid  2] control=[暝麜]
- `acme{space}1` smart=[acme 1] control=[暝碌]
- `acme{comma}` smart=[acme，] control=[暝汞，]
- `acme{space}{space}2` smart=[acme  2] control=[暝砐]
- `acne{space}1` smart=[acne 1] control=[暝鰻]
- `acne{comma}` smart=[acne，] control=[暝及，]
- `acne{space}{space}2` smart=[acne  2] control=[暝鯄]
- `acre{space}1` smart=[acre 1] control=[暝啵]

