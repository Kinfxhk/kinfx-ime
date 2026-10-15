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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('kinfx-win-' + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  & (Join-Path $PSScriptRoot 'install-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo -NoDeploy
  if ($LASTEXITCODE -ne 0) { throw "install exit $LASTEXITCODE" }
  foreach ($rel in @(
      'kinfx_quick.schema.yaml',
      'kinfx_quick.dict.yaml',
      'kinfx_jyutping.schema.yaml',
      'kinfx_quick_phrase.dict.yaml',
      'kinfx_hk_words.dict.yaml',
      'kinfx_hk_idioms.dict.yaml',
      'kinfx_en.dict.yaml',
      'rime.lua',
      'lua/win_quick.lua',
      'lua/phrase_mix.lua',
      'lua/melt_eng.lua',
      'lua/lexicon_index.lua',
      'default.custom.yaml',
      'kinfx-ime.deployed.txt'
    )) {
    Assert-True ("installed {0}" -f $rel) (Test-Path -LiteralPath (Join-RepoPath $tmp $rel))
  }
  Assert-True 'does not write default.yaml' (-not (Test-Path -LiteralPath (Join-Path $tmp 'default.yaml')))
  $custom = Read-Utf8Text (Join-Path $tmp 'default.custom.yaml')
  Assert-Seq 'fresh user dir lists both schemas' (Ids-OfText $custom) @('kinfx_quick', 'kinfx_jyutping')

  $other = Join-Path $tmp 'luna_pinyin.schema.yaml'
  Set-Content -LiteralPath $other -Value 'schema:' -Encoding ascii
  $userLua = Join-Path $tmp 'lua/my_extra.lua'
  Set-Content -LiteralPath $userLua -Value 'return {}' -Encoding ascii

  & (Join-Path $PSScriptRoot 'install-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo -NoDeploy
  if ($LASTEXITCODE -ne 0) { throw "reinstall exit $LASTEXITCODE" }
  Assert-Seq 'second install stays idempotent' (Ids-OfText (Read-Utf8Text (Join-Path $tmp 'default.custom.yaml'))) @('kinfx_quick', 'kinfx_jyutping')

  & (Join-Path $PSScriptRoot 'uninstall-windows.ps1') -RimeUserDir $tmp -RepoRoot $repo
  if ($LASTEXITCODE -ne 0) { throw "uninstall exit $LASTEXITCODE" }
  foreach ($rel in (Get-KinfxOwnedUserRelativePaths)) {
    Assert-True ("removed {0}" -f $rel) (-not (Test-Path -LiteralPath (Join-RepoPath $tmp $rel)))
  }
  Assert-True 'left unrelated schema' (Test-Path -LiteralPath $other)
  Assert-True 'left unrelated lua' (Test-Path -LiteralPath $userLua)
  Assert-True 'removed stock default.custom.yaml' (-not (Test-Path -LiteralPath (Join-Path $tmp 'default.custom.yaml')))

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
