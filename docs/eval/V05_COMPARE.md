# v0.5 離線比對（tools/rimeh/compare.py）

日期：2026-10-19。對照組 control＝`english/mode: shift`（v0.4.1 行為）；實驗組 smart＝預設值；兩組都關閉聯想同常用熱門頁。

- 兩碼碼數：658；英文詞：78013；空白不安全詞：362
- 比對序列：2090260（全部兩碼＋兩碼，加三段連打抽樣，每組帶結尾鍵）

## smart 對 control（嚴格分類）

「設計內」只限：前面已頂字嘅兩碼照 Windows 上屏，之後 3 個字母或以上嘅空白安全英文詞，遇空白或標點上屏成英文，而對照組冇用中文詞語留住呢串字母。

- 差異總數：30059
- 設計內：29087（每 1 萬組序列 139.15 組）
- 意外差異：972（必須為 0）
- 中文改變：0（必須為 0）

## 文章重打（smart）

- 中文字數：20000；英文詞：741，正確 741
- 空白規則撞中文（設計內，逐個列出）：1（每 1 萬中文字 0.50；模型估計見 kinfx_en_unsafe.txt 檔頭）
- 其他中文改變：0（必須為 0）

  - `gddwgo2pk3og5le5yr{space}3flyr{space}{space}{space}7bqyshe4j…` smart=[地東走快坐複高Flyr   7用方後臷咦接妥科於之電番步主真、慶下類河疑噉並係喺突] control=[地東走快坐複高鄰調用方後臷咦接妥科於之電番步主真、慶下類河疑噉並係喺突]

- 聯想（assoc 對 smart）差異：0

### 意外差異

- `fogge{space}1` smart=[fogge 1] control=[炊圭水]
- `fogge{comma}` smart=[fogge，] control=[炊圭水，]
- `fogge{space}{space}2` smart=[fogge  2] control=[炊圭]
- `parqu{space}1` smart=[parqu 1] control=[旨咩山]
- `parqu{comma}` smart=[parqu，] control=[旨咩山，]
- `parqu{space}{space}2` smart=[parqu  2] control=[旨咩]
- `nanch{space}1` smart=[nanch 1] control=[陌小鳳]
- `nanch{comma}` smart=[nanch，] control=[陌小白，]
- `nanch{space}{space}2` smart=[nanch  2] control=[陌小艇]
- `inche{space}1` smart=[inche 1] control=[划分水]
- `inche{comma}` smart=[inche，] control=[划分水，]
- `inche{space}{space}2` smart=[inche  2] control=[划分]
- `stoki{space}1` smart=[stoki 1] control=[屏仗戈]
- `stoki{comma}` smart=[stoki，] control=[屏仗戈，]
- `stoki{space}{space}2` smart=[stoki  2] control=[屏仗丶]
- `slimm{space}1` smart=[slimm 1] control=[匠式一]
- `slimm{comma}` smart=[slimm，] control=[匠式一，]
- `slimm{space}{space}2` smart=[slimm  2] control=[匠式]
- `fanci{space}1` smart=[fanci 1] control=[粕小戈]
- `fanci{comma}` smart=[fanci，] control=[粕小戈，]
- `fanci{space}{space}2` smart=[fanci  2] control=[粕小丶]
- `nonte{space}1` smart=[nonte 1] control=[久阱水]
- `nonte{comma}` smart=[nonte，] control=[久阱水，]
- `nonte{space}{space}2` smart=[nonte  2] control=[久阱]
- `delma{space}1` smart=[delma 1] control=[皮虹日]
- `delma{comma}` smart=[delma，] control=[皮虹日，]
- `delma{space}{space}2` smart=[delma  2] control=[皮虹曰]
- `riddi{space}1` smart=[riddi 1] control=[吋李戈]
- `riddi{comma}` smart=[riddi，] control=[吋李戈，]
- `riddi{space}{space}2` smart=[riddi  2] control=[吋李丶]
- `navra{space}1` smart=[navra 1] control=[陌如日]
- `navra{comma}` smart=[navra，] control=[陌如日，]
- `navra{space}{space}2` smart=[navra  2] control=[陌如曰]
- `carme{space}1` smart=[carme 1] control=[曾叼水]
- `carme{comma}` smart=[carme，] control=[曾叼水，]
- `carme{space}{space}2` smart=[carme  2] control=[曾叼]
- `asbes{space}1` smart=[asbes 1] control=[昨受尸]
- `asbes{comma}` smart=[asbes，] control=[昨受尸，]
- `asbes{space}{space}2` smart=[asbes  2] control=[昨受]
- `caloo{space}1` smart=[caloo 1] control=[曾兆人]
- `caloo{comma}` smart=[caloo，] control=[曾兆人，]
- `caloo{space}{space}2` smart=[caloo  2] control=[曾兆]
- `rilke{space}1` smart=[rilke 1] control=[吋史水]
- `rilke{comma}` smart=[rilke，] control=[吋史水，]
- `rilke{space}{space}2` smart=[rilke  2] control=[吋史]
- `encyc{space}1` smart=[encyc 1] control=[汀釙金]
- `encyc{comma}` smart=[encyc，] control=[汀釙金，]
- `encyc{space}{space}2` smart=[encyc  2] control=[汀釙]
- `fujiw{space}1` smart=[fujiw 1] control=[光守田]
- `fujiw{comma}` smart=[fujiw，] control=[光守田，]

### 設計內差異（前 40 個）

- `aaos{space}1` smart=[AAOS 1] control=[昌佢]
- `aaos{comma}` smart=[AAOS，] control=[昌仍，]
- `aaos{space}{space}2` smart=[AAOS  2] control=[昌隽]
- `aarp{space}1` smart=[AARP 1] control=[昌嚨]
- `aarp{comma}` smart=[AARP，] control=[昌叱，]
- `aarp{space}{space}2` smart=[AARP  2] control=[昌踗]
- `abap{space}1` smart=[ABAP 1] control=[明昽]
- `abap{comma}` smart=[ABAP，] control=[明昆，]
- `abap{space}{space}2` smart=[ABAP  2] control=[明𨳍]
- `abbr{space}1` smart=[abbr 1] control=[明賂]
- `abbr{comma}` smart=[abbr，] control=[明同，]
- `abbr{space}{space}2` smart=[abbr  2] control=[明贍]
- `abcd{space}1` smart=[ABCD 1] control=[明銇]
- `abcd{comma}` smart=[ABCD，] control=[明銖，]
- `abcd{space}{space}2` smart=[ABCD  2] control=[明鏿]
- `abet{space}1` smart=[abet 1] control=[明濫]
- `abet{comma}` smart=[abet，] control=[明泣，]
- `abet{space}{space}2` smart=[abet  2] control=[明湓]
- `abit{space}1` smart=[ABIT 1] control=[明廅]
- `abit{comma}` smart=[ABIT，] control=[明弁，]
- `abit{space}{space}2` smart=[ABIT  2] control=[明扁]
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
- `acer{comma}` smart=[Acer，] control=[暝河，]
- `acer{space}1` smart=[Acer 1] control=[暝洛]
- `acer{space}{space}2` smart=[Acer  2] control=[暝漪]
- `aces{space}1` smart=[aces 1] control=[暝泑]

