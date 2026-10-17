#Requires -Version 5.1
# Exercises the Weasel schema-list merge and the install/uninstall scripts.
# No Windows install and no Weasel binary required. Run:
#   pwsh -NoProfile -File scripts/test-windows-rime.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows-rime.ps1')

$script:failures = 0

function Assert-True {
  param([string]$Name, [bool]$Condition)
  if (-not $Condition) {
    Write-Host ("FAIL {0}" -f $Name)
    $script:failures++
  } else {
    Write-Host ("OK   {0}" -f $Name)
  }
}

function Assert-Seq {
  param([string]$Name, $Actual, [string[]]$Expected)
  $same = Test-SameSchemaSequence $Actual $Expected
  if (-not $same) {
    $shown = ''
    if ($null -ne $Actual) { $shown = $Actual -join ', ' }
    Write-Host ("FAIL {0}" -f $Name)
    Write-Host ("  actual:   {0}" -f $shown)
    Write-Host ("  expected: {0}" -f ($Expected -join ', '))
    $script:failures++
  } else {
    Write-Host ("OK   {0}" -f $Name)
  }
}

function Ids-OfText {
  param([string]$Text)
  $ids = Get-SchemaIdSequence (Get-AllSchemaEntries $Text)
  Write-Output -NoEnumerate $ids
}

$seed = @('luna_pinyin', 'bopomofo')
$created = New-KinfxDefaultCustomText $seed
Assert-Seq 'new file prepends kinfx and keeps weasel seed' (Ids-OfText $created) @('kinfx_quick', 'kinfx_jyutping', 'luna_pinyin', 'bopomofo')
Assert-True 'new file has marker' ($created -match 'kinfx-ime:schema_list begin')
Assert-True 'new file does not set global page_size' ($created -notmatch 'page_size')

$fromEmpty = Update-KinfxSchemaListText "patch:`n" @('luna_pinyin', 'bopomofo', 'cangjie5')
Assert-Seq 'empty schema_list unions weasel seed' (Ids-OfText $fromEmpty) @('kinfx_quick', 'kinfx_jyutping', 'luna_pinyin', 'bopomofo', 'cangjie5')

$kinfxOnly = @"
patch:
  schema_list:
    - schema: kinfx_quick
    - schema: kinfx_jyutping
"@
$fromKinfxOnly = Update-KinfxSchemaListText $kinfxOnly @('luna_pinyin', 'bopomofo', 'cangjie5')
Assert-Seq 'kinfx-only schema_list still merges weasel seed' (Ids-OfText $fromKinfxOnly) @('kinfx_quick', 'kinfx_jyutping', 'luna_pinyin', 'bopomofo', 'cangjie5')

$again = Update-KinfxSchemaListText $created @('luna_pinyin', 'cangjie5')
Assert-Seq 'rerun unions new seed ids without dupes or reorder' (Ids-OfText $again) @('kinfx_quick', 'kinfx_jyutping', 'luna_pinyin', 'bopomofo', 'cangjie5')
Assert-True 'rerun keeps a single schema_list marker' (([regex]::Matches($again, 'kinfx-ime:schema_list begin')).Count -eq 1)

$withReset = @"
patch:
  schema_list:
    - schema: terra_pinyin
    - schema: luna_pinyin_fluency
      reset: 1
  # keep me
  "menu/page_size": 5
"@
$merged = Update-KinfxSchemaListText $withReset $seed
Assert-Seq 'prepends kinfx when absent and unions weasel seed without wiping user schemas' (Ids-OfText $merged) @('kinfx_quick', 'kinfx_jyutping', 'terra_pinyin', 'luna_pinyin_fluency', 'luna_pinyin', 'bopomofo')
Assert-True 'keeps reset tail' ($merged -match '(?m)^      reset: 1\s*$')
Assert-True 'keeps user comment' ($merged -match '# keep me')
Assert-True 'keeps user page_size' ($merged -match '"menu/page_size": 5')

$quickMiddle = @"
patch:
  schema_list:
    - schema: terra_pinyin
    - schema: kinfx_quick
"@
$middle = Update-KinfxSchemaListText $quickMiddle @()
Assert-Seq 'jyutping is inserted after existing kinfx_quick' (Ids-OfText $middle) @('terra_pinyin', 'kinfx_quick', 'kinfx_jyutping')

$switcher = @"
# user header
patch:
  "switcher/hotkeys":
    - "Control+grave"
  schema_list:
    - schema: luna_pinyin
"@
$sw = Update-KinfxSchemaListText $switcher @()
Assert-Seq 'switcher file gains kinfx ids' (Ids-OfText $sw) @('kinfx_quick', 'kinfx_jyutping', 'luna_pinyin')
Assert-True 'switcher hotkey survives' ($sw -match 'Control\+grave')
Assert-True 'user header survives' ($sw -match '# user header')

$onlyKinfx = Remove-KinfxSchemaListText $created @('luna_pinyin', 'bopomofo')
Assert-True 'uninstall deletes file when remaining list equals weasel default' ([bool]$onlyKinfx.Delete)

$keepComment = Remove-KinfxSchemaListText $merged @()
Assert-True 'uninstall keeps file when user keys remain' (-not $keepComment.Delete)
Assert-Seq 'uninstall drops only kinfx ids' (Ids-OfText $keepComment.Text) @('terra_pinyin', 'luna_pinyin_fluency', 'luna_pinyin', 'bopomofo')
Assert-True 'uninstall keeps reset and page_size' (($keepComment.Text -match 'reset: 1') -and ($keepComment.Text -match 'menu/page_size'))

$emptyAfter = Remove-KinfxSchemaListText (New-KinfxDefaultCustomText @()) @()
Assert-True 'uninstall deletes a file that only listed kinfx' ([bool]$emptyAfter.Delete)

$crlf = "patch:`r`n  schema_list:`r`n    - schema: luna_pinyin`r`n"
$fromCrlf = Update-KinfxSchemaListText $crlf @()
Assert-Seq 'CRLF input merges' (Ids-OfText $fromCrlf) @('kinfx_quick', 'kinfx_jyutping', 'luna_pinyin')

$oneLine = 'patch: { schema_list: [] }'
$threw = $false
try { Update-KinfxSchemaListText $oneLine @() | Out-Null } catch { $threw = $true }
Assert-True 'one-line patch fails clearly' $threw

$repo = Split-Path -Parent $PSScriptRoot
$missingSources = Get-MissingKinfxSources $repo
Assert-True 'repo sources exist' ($missingSources.Count -eq 0)

$skinBlock = Get-KinfxWeaselSkinBlockLines $repo
$freshSkin = New-KinfxWeaselCustomText $skinBlock
Assert-True 'skin names light scheme' ($freshSkin -match '"style/color_scheme": kinfx_modern')
Assert-True 'skin names dark scheme' ($freshSkin -match 'kinfx_modern_dark')
Assert-True 'skin keeps vertical' (($freshSkin -match '"style/horizontal": false') -and ($freshSkin -match '"style/layout/type": vertical'))
Assert-True 'skin has corner and small shadow' (($freshSkin -match '"style/layout/corner_radius": 12') -and ($freshSkin -match '"style/layout/shadow_radius": 8'))
Assert-True 'skin does not set page_size' ($freshSkin -notmatch 'page_size')
Assert-True 'skin has no horizontal true' ($freshSkin -notmatch 'horizontal:\s*true')
Assert-True 'skin has no bitmap or redraw keys' (($freshSkin -notmatch '(?i)\.(png|bmp|jpg|gif|webp)') -and ($freshSkin -notmatch '"style/(hover_type|enhanced_position)"'))
Assert-True 'skin has one begin marker' (([regex]::Matches($freshSkin, 'kinfx-ime:weasel-skin begin')).Count -eq 1)
$skinAgain = Update-KinfxWeaselSkinText $freshSkin $skinBlock
Assert-True 'skin rerun idempotent' ($skinAgain -eq $freshSkin)

$userSkin = @"
# my weasel notes
patch:
  "style/color_scheme": aqua
  "style/font_point": 22
  "preset_color_schemes/aqua":
    name: Aqua
    text_color: 0x112233
  app_options:
    notepad.exe:
      ascii_mode: true
  "switcher/hotkeys":
    - "Control+grave"
"@
$mergedSkin = Update-KinfxWeaselSkinText $userSkin $skinBlock
Assert-True 'skin keeps app_options' ($mergedSkin -match 'notepad.exe')
Assert-True 'skin keeps hotkey' ($mergedSkin -match 'Control\+grave')
Assert-True 'skin keeps user note' ($mergedSkin -match 'my weasel notes')
Assert-True 'skin keeps foreign color scheme body' (($mergedSkin -match 'name: Aqua') -and ($mergedSkin -match '0x112233'))
Assert-True 'skin drops replaced aqua selection' ($mergedSkin -notmatch '"style/color_scheme": aqua')
Assert-True 'one light scheme key' (([regex]::Matches($mergedSkin, '"style/color_scheme":')).Count -eq 1)
Assert-True 'one dark scheme key' (([regex]::Matches($mergedSkin, '"style/color_scheme_dark":')).Count -eq 1)
Assert-True 'font_point is skin value once' (([regex]::Matches($mergedSkin, '"style/font_point":')).Count -eq 1)
Assert-True 'font_point not 22' ($mergedSkin -notmatch 'font_point": 22')
$idxPlusPrep = $mergedSkin.IndexOf('app_options:')
$idxSkin = $mergedSkin.LastIndexOf('kinfx-ime:weasel-skin begin')
Assert-True 'skin block follows unrelated keys' (($idxSkin -gt $idxPlusPrep) -and ($idxPlusPrep -ge 0))

$plusSkin = @"
patch:
  style/+:
    horizontal: true
    font_point: 30
  app_options:
    notepad.exe:
      ascii_mode: true
"@
$plusOut = Update-KinfxWeaselSkinText $plusSkin $skinBlock
$idxPlus = $plusOut.IndexOf('style/+')
$idxHoriz = $plusOut.LastIndexOf('"style/horizontal": false')
Assert-True 'skin block follows style/+' (($idxHoriz -gt $idxPlus) -and ($idxPlus -ge 0))
Assert-True 'style/+ map preserved' ($plusOut -match 'font_point: 30')
Assert-True 'style/+ does not remove vertical key' ($plusOut -match '"style/layout/type": vertical')

$removedSkin = Remove-KinfxWeaselSkinText $mergedSkin
Assert-True 'uninstall skin keeps file' (-not $removedSkin.Delete)
Assert-True 'uninstall skin drops marker' ($removedSkin.Text -notmatch 'weasel-skin begin')
Assert-True 'uninstall skin keeps app_options' ($removedSkin.Text -match 'notepad.exe')
Assert-True 'uninstall skin keeps hotkey' ($removedSkin.Text -match 'Control\+grave')
Assert-True 'uninstall skin keeps note' ($removedSkin.Text -match 'my weasel notes')
Assert-True 'uninstall skin keeps aqua body' ($removedSkin.Text -match '0x112233')
Assert-True 'uninstall skin drops kinfx scheme' ($removedSkin.Text -notmatch 'kinfx_modern')

$onlySkin = Remove-KinfxWeaselSkinText $freshSkin
Assert-True 'uninstall deletes skin-only file' ([bool]$onlySkin.Delete)

$noMarkerSkin = "patch:`n  app_options:`n    notepad.exe:`n      ascii_mode: true`n"
$untouchedSkin = Remove-KinfxWeaselSkinText $noMarkerSkin
Assert-True 'no skin marker leaves text' (($untouchedSkin.Text -eq $noMarkerSkin) -and (-not $untouchedSkin.Delete))

$oneLineSkin = 'patch: { "style/color_scheme": aqua }'
$threwSkin = $false
try { Update-KinfxWeaselSkinText $oneLineSkin $skinBlock | Out-Null } catch { $threwSkin = $true }
Assert-True 'weasel one-line patch fails clearly' $threwSkin

$crlfSkin = "patch:`r`n  app_options:`r`n    notepad.exe:`r`n      ascii_mode: true`r`n"
$fromCrlfSkin = Update-KinfxWeaselSkinText $crlfSkin $skinBlock
Assert-True 'CRLF weasel file keeps app_options' ($fromCrlfSkin -match 'notepad.exe')
Assert-True 'CRLF weasel file gains one skin' (([regex]::Matches($fromCrlfSkin, 'kinfx-ime:weasel-skin begin')).Count -eq 1)

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('kinfx-win-' + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  & (Join-Path $PSScriptRoot 'install-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo -NoDeploy
  if ($LASTEXITCODE -ne 0) { throw "install exit $LASTEXITCODE" }
  foreach ($rel in @(
      'kinfx_quick.schema.yaml',
      'kinfx_quick.dict.yaml',
      'kinfx_phrase.schema.yaml',
      'kinfx_en.schema.yaml',
      'kinfx_assoc.schema.yaml',
      'kinfx_capture.txt',
      'kinfx_en_unsafe.txt',
      'kinfx_en_names.txt',
      'kinfx_jyutping.schema.yaml',
      'kinfx_quick_phrase.dict.yaml',
      'kinfx_hk_words.dict.yaml',
      'kinfx_hk_idioms.dict.yaml',
      'kinfx_assoc.dict.yaml',
      'kinfx_en.dict.yaml',
      'rime.lua',
      'lua/win_quick.lua',
      'lua/phrase_mix.lua',
      'lua/english_mix.lua',
      'lua/assoc.lua',
      'default.custom.yaml',
      'weasel.custom.yaml',
      'kinfx-ime.deployed.txt'
    )) {
    Assert-True ("installed {0}" -f $rel) (Test-Path -LiteralPath (Join-RepoPath $tmp $rel))
  }
  Assert-True 'does not write default.yaml' (-not (Test-Path -LiteralPath (Join-Path $tmp 'default.yaml')))
  $custom = Read-Utf8Text (Join-Path $tmp 'default.custom.yaml')
  # KINFX first, then whatever the installed Weasel shared default.yaml seeds
  # (none on a machine without Weasel).
  $wantIds = @('kinfx_quick', 'kinfx_jyutping')
  $weaselForSeed = Find-WeaselInstall
  if (-not [string]::IsNullOrWhiteSpace($weaselForSeed.SharedData)) {
    foreach ($id in (Get-SchemaIdsFromYamlFile (Join-Path $weaselForSeed.SharedData 'default.yaml'))) {
      if ($wantIds -notcontains $id) { $wantIds += $id }
    }
  }
  Assert-Seq 'fresh user dir lists both schemas' (Ids-OfText $custom) $wantIds
  $installedSkin = Read-Utf8Text (Join-Path $tmp 'weasel.custom.yaml')
  Assert-True 'install writes vertical lightweight skin' (($installedSkin -match '"style/horizontal": false') -and ($installedSkin -match '"style/layout/shadow_radius": 8') -and ($installedSkin -notmatch 'page_size'))

  $other = Join-Path $tmp 'luna_pinyin.schema.yaml'
  Set-Content -LiteralPath $other -Value 'schema:' -Encoding ascii
  $userLua = Join-Path $tmp 'lua/my_extra.lua'
  Set-Content -LiteralPath $userLua -Value 'return {}' -Encoding ascii

  & (Join-Path $PSScriptRoot 'install-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo -NoDeploy
  if ($LASTEXITCODE -ne 0) { throw "reinstall exit $LASTEXITCODE" }
  Assert-Seq 'second install stays idempotent' (Ids-OfText (Read-Utf8Text (Join-Path $tmp 'default.custom.yaml'))) $wantIds
  Assert-True 'second install keeps one skin' (([regex]::Matches((Read-Utf8Text (Join-Path $tmp 'weasel.custom.yaml')), 'kinfx-ime:weasel-skin begin')).Count -eq 1)

  & (Join-Path $PSScriptRoot 'uninstall-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo
  if ($LASTEXITCODE -ne 0) { throw "uninstall exit $LASTEXITCODE" }
  foreach ($rel in (Get-KinfxOwnedUserRelativePaths)) {
    Assert-True ("removed {0}" -f $rel) (-not (Test-Path -LiteralPath (Join-RepoPath $tmp $rel)))
  }
  Assert-True 'left unrelated schema' (Test-Path -LiteralPath $other)
  Assert-True 'left unrelated lua' (Test-Path -LiteralPath $userLua)
  Assert-True 'removed stock default.custom.yaml' (-not (Test-Path -LiteralPath (Join-Path $tmp 'default.custom.yaml')))
  Assert-True 'removed stock weasel skin' (-not (Test-Path -LiteralPath (Join-Path $tmp 'weasel.custom.yaml')))

  $customOnly = Join-Path $tmp 'default.custom.yaml'
  Write-Utf8NoBom $customOnly @"
# keep this note
patch:
  schema_list:
    - schema: kinfx_quick
    - schema: kinfx_jyutping
    - schema: terra_pinyin
  "ascii_composer/switch_key/Shift_L": noop
"@
  Set-Content -LiteralPath (Join-Path $tmp 'rime.lua') -Value "require('not_kinfx')`n" -Encoding ascii
  & (Join-Path $PSScriptRoot 'uninstall-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo
  if ($LASTEXITCODE -ne 0) { throw "second uninstall exit $LASTEXITCODE" }
  Assert-True 'kept foreign rime.lua' (Test-Path -LiteralPath (Join-Path $tmp 'rime.lua'))
  $after = Read-Utf8Text $customOnly
  Assert-Seq 'second uninstall leaves terra' (Ids-OfText $after) @('terra_pinyin')
  Assert-True 'second uninstall keeps user patch' ($after -match 'noop')
  Assert-True 'second uninstall keeps user note' ($after -match 'keep this note')

  $zip = Join-Path $tmp 'share.zip'
  & (Join-Path $PSScriptRoot 'pack-windows-share.ps1') -RepoRoot $repo -OutputZip $zip
  if ($LASTEXITCODE -ne 0) { throw "pack exit $LASTEXITCODE" }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
  try {
    $names = @($archive.Entries | ForEach-Object { $_.FullName })
    Assert-True 'zip has WINDOWS.md' ($names -contains 'docs/WINDOWS.md')
    Assert-True 'zip has install script' ($names -contains 'scripts/install-windows.ps1')
    Assert-True 'zip has library' ($names -contains 'scripts/windows-rime.ps1')
    Assert-True 'zip has lexicon notice' ($names -contains 'lexicon/NOTICE')
    Assert-True 'zip has quick dict' ($names -contains 'schemas/kinfx-quick/kinfx_quick.dict.yaml')
    Assert-True 'zip has share blurb' ($names -contains 'WINDOWS-SHARE.txt')
    Assert-True 'zip has weasel skin example' ($names -contains 'schemas/examples/weasel.custom.yaml.example')
    Assert-True 'zip omits third_party' (-not ($names | Where-Object { $_ -like 'third_party/*' }))
    Assert-True 'zip uses forward slashes' (-not ($names | Where-Object { $_ -match '\\' }))
  } finally {
    $archive.Dispose()
  }
} finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failures -gt 0) {
  Write-Host ("{0} failure(s)" -f $script:failures)
  exit 1
}
Write-Host 'all windows rime checks passed'
exit 0
