# KINFX Weasel user-directory helpers. Dot-source from the Windows scripts.
# PowerShell 5.1+. This file has no side effects when dot-sourced.
# encoding: UTF-8 with BOM so Windows PowerShell 5.1 reads the Chinese strings.

if ($MyInvocation.InvocationName -ne '.') {
  Write-Host 'windows-rime.ps1 is a library. Run scripts/install-windows.ps1.'
  exit 0
}

$script:KinfxQuickId = 'kinfx_quick'
$script:KinfxJyutpingId = 'kinfx_jyutping'
$script:KinfxSchemaListBegin = '# kinfx-ime:schema_list begin'
$script:KinfxSchemaListEnd = '# kinfx-ime:schema_list end'

function Join-RepoPath {
  param(
    [Parameter(Mandatory = $true)][string]$Base,
    [Parameter(Mandatory = $true)][string]$Relative
  )
  $path = $Base
  foreach ($part in ($Relative -split '[\\/]' | Where-Object { $_ -ne '' })) {
    $path = Join-Path $path $part
  }
  return $path
}

function Get-KinfxDeployItems {
  # Flat names under %APPDATA%\Rime. Rime compiles dictionaries from the user
  # directory root, and librime-lua loads rime.lua plus lua/*.lua.
  $rows = @(
    [pscustomobject]@{ Rel = 'kinfx_quick.schema.yaml'; Src = 'schemas/kinfx-quick/kinfx_quick.schema.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_quick.dict.yaml'; Src = 'schemas/kinfx-quick/kinfx_quick.dict.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_phrase.schema.yaml'; Src = 'schemas/kinfx-quick/kinfx_phrase.schema.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_en.schema.yaml'; Src = 'schemas/kinfx-quick/kinfx_en.schema.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_capture.txt'; Src = 'lexicon/hk/kinfx_capture.txt' },
    [pscustomobject]@{ Rel = 'kinfx_jyutping.schema.yaml'; Src = 'schemas/kinfx-jyutping/kinfx_jyutping.schema.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_quick_phrase.dict.yaml'; Src = 'lexicon/hk/kinfx_quick_phrase.dict.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_hk_words.dict.yaml'; Src = 'lexicon/hk/kinfx_hk_words.dict.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_hk_idioms.dict.yaml'; Src = 'lexicon/hk/kinfx_hk_idioms.dict.yaml' },
    [pscustomobject]@{ Rel = 'kinfx_en.dict.yaml'; Src = 'lexicon/en/kinfx_en.dict.yaml' },
    [pscustomobject]@{ Rel = 'rime.lua'; Src = 'schemas/rime.lua' },
    [pscustomobject]@{ Rel = 'lua/win_quick.lua'; Src = 'schemas/lua/win_quick.lua' },
    [pscustomobject]@{ Rel = 'lua/phrase_mix.lua'; Src = 'schemas/lua/phrase_mix.lua' }
  )
  # NoEnumerate: a bare return (and @()) collapses empty and one-item arrays.
  Write-Output -NoEnumerate $rows
}

function Get-MissingKinfxSources {
  param([Parameter(Mandatory = $true)][string]$RepoRoot)
  $missing = New-Object System.Collections.Generic.List[string]
  foreach ($item in (Get-KinfxDeployItems)) {
    $src = Join-RepoPath $RepoRoot $item.Src
    if (-not (Test-Path -LiteralPath $src)) {
      [void]$missing.Add($src)
    }
  }
  $skinExample = Join-RepoPath $RepoRoot 'schemas/examples/weasel.custom.yaml.example'
  if (-not (Test-Path -LiteralPath $skinExample)) {
    [void]$missing.Add($skinExample)
  }
  Write-Output -NoEnumerate $missing.ToArray()
}

function Get-KinfxOwnedUserRelativePaths {
  $rels = New-Object System.Collections.Generic.List[string]
  foreach ($item in (Get-KinfxDeployItems)) {
    [void]$rels.Add($item.Rel)
  }
  [void]$rels.Add('kinfx-ime.deployed.txt')
  foreach ($old in (Get-KinfxRetiredUserRelativePaths)) { [void]$rels.Add($old) }
  Write-Output -NoEnumerate $rels.ToArray()
}

function Get-KinfxRetiredUserRelativePaths {
  # Files earlier releases installed. v0.4 loads lexicons natively, so these
  # Lua-heap loaders must not stay behind after an upgrade.
  Write-Output -NoEnumerate @('lua/melt_eng.lua', 'lua/lexicon_index.lua')
}

function ConvertTo-YamlLineList {
  param([AllowNull()][string]$Text)
  $list = New-Object System.Collections.Generic.List[string]
  if ([string]::IsNullOrEmpty($Text)) {
    Write-Output -NoEnumerate $list
    return
  }
  # String.Split, not -split. "-split "`n", -1" keeps the whole text as one line.
  $norm = $Text.TrimStart([char]0xFEFF).Replace("`r`n", "`n").Replace("`r", "`n")
  foreach ($line in $norm.Split([char]10)) {
    [void]$list.Add($line)
  }
  if ($list.Count -gt 0 -and $list[$list.Count - 1] -eq '') {
    $list.RemoveAt($list.Count - 1)
  }
  # Keep the List intact. A bare return enumerates it, and @() wraps an empty array.
  Write-Output -NoEnumerate $list
}

function Join-YamlLines {
  param($Lines)
  $text = [string]::Join("`n", [string[]]$Lines)
  if (-not $text.EndsWith("`n")) {
    $text += "`n"
  }
  return $text
}

function Find-SchemaListSpans {
  # Inclusive start/end indexes of every schema_list block, including the
  # adjacent kinfx-ime marker comments when they belong to that block.
  param($Lines)
  $spans = New-Object System.Collections.Generic.List[object]
  $i = 0
  while ($i -lt $Lines.Count) {
    if ($Lines[$i] -match '^(\s*)schema_list:\s*(\[\]|#.*)?$') {
      $indent = $Matches[1].Length
      $start = $i
      $j = $i - 1
      while ($j -ge 0 -and $Lines[$j] -match '^\s*$') { $j-- }
      if ($j -ge 0 -and $Lines[$j] -match '^\s*#\s*kinfx-ime:schema_list begin\s*$') {
        $start = $j
      }
      $k = $i + 1
      while ($k -lt $Lines.Count) {
        $line = $Lines[$k]
        if ($line -match '^\s*#\s*kinfx-ime:schema_list end\s*$') {
          $k++
          break
        }
        if ($line -match '^\s*$') {
          $k++
          continue
        }
        if ($line -match '^(\s*)#') {
          if ($Matches[1].Length -gt $indent) {
            $k++
            continue
          }
          break
        }
        if ($line -match '^\s*-\s+') {
          $k++
          continue
        }
        if ($line -match '^(\s*)\S') {
          if ($Matches[1].Length -gt $indent) {
            $k++
            continue
          }
        }
        break
      }
      while ($k -gt ($i + 1) -and $Lines[$k - 1] -match '^\s*$') {
        $k--
      }
      [void]$spans.Add([pscustomobject]@{ Start = $start; End = ($k - 1) })
      $i = $k
      continue
    }
    $i++
  }
  Write-Output -NoEnumerate $spans.ToArray()
}

function Get-SchemaEntriesFromLines {
  param([string[]]$Chunk)
  $entries = New-Object System.Collections.Generic.List[object]
  $current = $null
  foreach ($line in $Chunk) {
    if ($line -match '^\s*schema_list:') { continue }
    if ($line -match '^\s*#\s*kinfx-ime:schema_list (begin|end)\s*$') { continue }
    if ($line -match '^\s*$') { continue }
    if ($line -match '^\s*-\s+schema:\s*[''"]?([A-Za-z0-9_.-]+)[''"]?\s*(#.*)?$') {
      if ($null -ne $current) { [void]$entries.Add($current) }
      $tails = New-Object System.Collections.Generic.List[string]
      $current = [pscustomobject]@{ Id = $Matches[1]; Tails = $tails }
      continue
    }
    if ($null -ne $current) {
      [void]$current.Tails.Add($line)
    }
  }
  if ($null -ne $current) { [void]$entries.Add($current) }
  Write-Output -NoEnumerate $entries.ToArray()
}

function Get-AllSchemaEntries {
  param([AllowNull()][string]$Text)
  $lines = ConvertTo-YamlLineList $Text
  $spans = Find-SchemaListSpans $lines
  $all = New-Object System.Collections.Generic.List[object]
  foreach ($span in $spans) {
    $chunk = New-Object System.Collections.Generic.List[string]
    for ($i = $span.Start; $i -le $span.End; $i++) {
      [void]$chunk.Add($lines[$i])
    }
    $chunkEntries = Get-SchemaEntriesFromLines $chunk.ToArray()
    for ($n = 0; $n -lt $chunkEntries.Count; $n++) {
      [void]$all.Add($chunkEntries[$n])
    }
  }
  Write-Output -NoEnumerate $all.ToArray()
}

function New-SchemaEntry {
  param([Parameter(Mandatory = $true)][string]$Id)
  $tails = New-Object System.Collections.Generic.List[string]
  return [pscustomobject]@{ Id = $Id; Tails = $tails }
}

function Merge-KinfxSchemaEntries {
  # Union $SeedSchemaIds into $ExistingEntries on every call. A first run
  # without Weasel writes only kinfx_*; a later re-run must still append the
  # Weasel seed. Existing ids (and their tails) stay in place. No wipe, no dupes.
  param(
    $ExistingEntries,
    [AllowNull()][string[]]$SeedSchemaIds
  )
  $have = New-Object System.Collections.Generic.List[object]
  $seen = @{}
  $source = New-Object System.Collections.Generic.List[object]
  if ($null -ne $ExistingEntries) {
    for ($n = 0; $n -lt $ExistingEntries.Count; $n++) {
      $entry = $ExistingEntries[$n]
      if ($null -eq $entry) { continue }
      if ([string]::IsNullOrEmpty($entry.Id)) { continue }
      [void]$source.Add($entry)
    }
  }
  if ($null -ne $SeedSchemaIds) {
    for ($n = 0; $n -lt $SeedSchemaIds.Count; $n++) {
      $id = [string]$SeedSchemaIds[$n]
      if (-not [string]::IsNullOrWhiteSpace($id)) {
        [void]$source.Add((New-SchemaEntry $id))
      }
    }
  }
  for ($n = 0; $n -lt $source.Count; $n++) {
    $entry = $source[$n]
    if ($seen.ContainsKey($entry.Id)) { continue }
    $seen[$entry.Id] = $true
    [void]$have.Add($entry)
  }
  if (-not $seen.ContainsKey($script:KinfxQuickId)) {
    $have.Insert(0, (New-SchemaEntry $script:KinfxQuickId))
    $seen[$script:KinfxQuickId] = $true
  }
  if (-not $seen.ContainsKey($script:KinfxJyutpingId)) {
    $idx = 0
    for ($i = 0; $i -lt $have.Count; $i++) {
      if ($have[$i].Id -eq $script:KinfxQuickId) { $idx = $i; break }
    }
    $have.Insert($idx + 1, (New-SchemaEntry $script:KinfxJyutpingId))
  }
  Write-Output -NoEnumerate $have.ToArray()
}

function Remove-KinfxSchemaEntries {
  param($Entries)
  $kept = New-Object System.Collections.Generic.List[object]
  if ($null -ne $Entries) {
    for ($n = 0; $n -lt $Entries.Count; $n++) {
      $entry = $Entries[$n]
      if ($null -eq $entry) { continue }
      if ($entry.Id -eq $script:KinfxQuickId -or $entry.Id -eq $script:KinfxJyutpingId) { continue }
      [void]$kept.Add($entry)
    }
  }
  Write-Output -NoEnumerate $kept.ToArray()
}

function Get-SchemaIdSequence {
  param($Entries)
  $ids = New-Object System.Collections.Generic.List[string]
  if ($null -ne $Entries) {
    for ($n = 0; $n -lt $Entries.Count; $n++) {
      $entry = $Entries[$n]
      if ($null -eq $entry) { continue }
      if (-not [string]::IsNullOrEmpty($entry.Id)) { [void]$ids.Add($entry.Id) }
    }
  }
  Write-Output -NoEnumerate $ids.ToArray()
}

function Test-SameSchemaSequence {
  param($Left, $Right)
  if ($null -eq $Left -or ($Left -is [string])) {
    if ($Left -is [string]) { $Left = @([string]$Left) } else { $Left = @() }
  }
  if ($null -eq $Right -or ($Right -is [string])) {
    if ($Right -is [string]) { $Right = @([string]$Right) } else { $Right = @() }
  }
  if ($Left.Count -ne $Right.Count) { return $false }
  for ($i = 0; $i -lt $Left.Count; $i++) {
    if ([string]$Left[$i] -ne [string]$Right[$i]) { return $false }
  }
  return $true
}

function New-SchemaListBlockLines {
  param($Entries)
  $lines = New-Object System.Collections.Generic.List[string]
  [void]$lines.Add('  # kinfx-ime:schema_list begin')
  [void]$lines.Add('  schema_list:')
  if ($null -ne $Entries) {
    for ($n = 0; $n -lt $Entries.Count; $n++) {
      $entry = $Entries[$n]
      if ($null -eq $entry) { continue }
      [void]$lines.Add(('    - schema: ' + $entry.Id))
      if ($null -eq $entry.Tails) { continue }
      for ($t = 0; $t -lt $entry.Tails.Count; $t++) {
        [void]$lines.Add([string]$entry.Tails[$t])
      }
    }
  }
  [void]$lines.Add('  # kinfx-ime:schema_list end')
  Write-Output -NoEnumerate $lines.ToArray()
}

function Remove-ListRange {
  param($List, [int]$Start, [int]$EndInclusive)
  $count = $EndInclusive - $Start + 1
  if ($Start -lt 0 -or $count -le 0) { return }
  $List.RemoveRange($Start, $count)
}

function Replace-ListRange {
  param($List, [int]$Start, [int]$EndInclusive, [string[]]$NewLines)
  Remove-ListRange $List $Start $EndInclusive
  for ($n = $NewLines.Count - 1; $n -ge 0; $n--) {
    $List.Insert($Start, $NewLines[$n])
  }
}

function Assert-PatchMapIsBlock {
  param(
    $Lines,
    [string]$FileLabel = 'default.custom.yaml'
  )
  if ($null -eq $Lines) { return }
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    # "patch: { ... }" is a one-line map. "patch:" and "patch: # comment" are blocks.
    if ($Lines[$i] -match '^patch:\s+[^#\s]') {
      throw ($FileLabel + ' has a one-line patch: value. Put patch: on its own line, then re-run. This script will not guess how to merge a one-line patch.')
    }
  }
}

function Set-SchemaListEntries {
  param($Lines, $Entries, [bool]$RemoveOnly)
  $spans = Find-SchemaListSpans $Lines
  $entryCount = 0
  if ($null -ne $Entries) { $entryCount = $Entries.Count }
  if ($RemoveOnly -and $entryCount -eq 0) {
    for ($s = $spans.Count - 1; $s -ge 0; $s--) {
      if ($null -eq $spans[$s]) { continue }
      Remove-ListRange $Lines $spans[$s].Start $spans[$s].End
    }
    return
  }
  $block = New-SchemaListBlockLines $Entries
  if ($spans.Count -gt 0 -and $null -ne $spans[0]) {
    for ($s = $spans.Count - 1; $s -ge 1; $s--) {
      Remove-ListRange $Lines $spans[$s].Start $spans[$s].End
    }
    Replace-ListRange $Lines $spans[0].Start $spans[0].End $block
    return
  }
  $patchIdx = -1
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^patch:\s*(#.*)?$') { $patchIdx = $i; break }
  }
  if ($patchIdx -ge 0) {
    for ($n = $block.Count - 1; $n -ge 0; $n--) {
      $Lines.Insert($patchIdx + 1, $block[$n])
    }
    return
  }
  if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') {
    [void]$Lines.Add('')
  }
  [void]$Lines.Add('patch:')
  foreach ($blockLine in $block) { [void]$Lines.Add($blockLine) }
}

function Remove-EmptyPatchKey {
  param($Lines)
  $idx = -1
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^patch:\s*(#.*)?$') { $idx = $i; break }
  }
  if ($idx -lt 0) { return }
  for ($i = $idx + 1; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }
    if ($line -match '^\S') { break }
    if ($line -match '^\s+\S') { return }
  }
  $Lines.RemoveAt($idx)
  while ($idx -lt $Lines.Count -and $Lines[$idx] -match '^\s*$') {
    $Lines.RemoveAt($idx)
  }
  while ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -match '^\s*$') {
    $Lines.RemoveAt($Lines.Count - 1)
  }
}

function Test-OnlyKinfxComments {
  param([AllowNull()][string]$Text)
  $lines = ConvertTo-YamlLineList $Text
  foreach ($line in @($lines)) {
    if ([string]::IsNullOrWhiteSpace([string]$line)) { continue }
    if ($line -match '^\s*#') {
      if ($line -match '(?i)encoding:\s*utf-8|kinfx|weasel|小狼毫|中英混打|install-windows|uninstall-windows|schema_list') {
        continue
      }
      return $false
    }
    return $false
  }
  return $true
}

function Update-KinfxSchemaListText {
  param(
    [AllowNull()][string]$Text,
    [AllowNull()][string[]]$SeedSchemaIds
  )
  if ([string]::IsNullOrWhiteSpace($Text)) {
    $Text = "patch:`n"
  }
  $lines = ConvertTo-YamlLineList $Text
  Assert-PatchMapIsBlock $lines
  $existing = Get-AllSchemaEntries $Text
  $merged = Merge-KinfxSchemaEntries $existing $SeedSchemaIds
  Set-SchemaListEntries $lines $merged $false
  return (Join-YamlLines $lines)
}

function Remove-KinfxSchemaListText {
  param(
    [AllowNull()][string]$Text,
    [AllowNull()][string[]]$SharedDefaultIds
  )
  $result = [pscustomobject]@{ Text = $Text; Delete = $false }
  if ([string]::IsNullOrWhiteSpace($Text)) {
    $result.Delete = $true
    $result.Text = ''
    return $result
  }
  $lines = ConvertTo-YamlLineList $Text
  Assert-PatchMapIsBlock $lines
  $existing = Get-AllSchemaEntries $Text
  $kept = Remove-KinfxSchemaEntries $existing
  $keptIds = Get-SchemaIdSequence $kept
  $dropList = $false
  $sharedCount = 0
  if ($null -ne $SharedDefaultIds) { $sharedCount = $SharedDefaultIds.Count }
  if ($keptIds.Count -eq 0) {
    $dropList = $true
  } elseif ($sharedCount -gt 0 -and (Test-SameSchemaSequence $keptIds $SharedDefaultIds)) {
    $dropList = $true
  }
  if ($dropList) {
    Set-SchemaListEntries $lines $null $true
  } else {
    Set-SchemaListEntries $lines $kept $false
  }
  Remove-EmptyPatchKey $lines
  $updated = Join-YamlLines $lines
  if (Test-OnlyKinfxComments $updated) {
    $result.Delete = $true
    $result.Text = ''
    return $result
  }
  $result.Text = $updated
  return $result
}

function New-KinfxDefaultCustomText {
  param([AllowNull()][string[]]$SeedSchemaIds)
  $header = @(
    '# encoding: utf-8',
    '# KINFX 中英混打輸入法 — Weasel 用戶覆寫',
    '# 由 scripts/install-windows.ps1 寫入。只保證 kinfx_quick / kinfx_jyutping 在 schema_list；',
    '# 其他方案保留。卸載：scripts/uninstall-windows.ps1'
  ) -join "`n"
  $body = Update-KinfxSchemaListText -Text "patch:`n" -SeedSchemaIds $SeedSchemaIds
  return ($header + "`n" + $body)
}

function Read-Utf8Text {
  param([Parameter(Mandatory = $true)][string]$Path)
  $text = [System.IO.File]::ReadAllText($Path)
  return $text.TrimStart([char]0xFEFF)
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text
  )
  $enc = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Get-SchemaIdsFromYamlFile {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
    Write-Output -NoEnumerate @()
    return
  }
  $entries = Get-AllSchemaEntries (Read-Utf8Text $Path)
  Write-Output -NoEnumerate (Get-SchemaIdSequence $entries)
}

function Resolve-RimeUserDir {
  param([AllowNull()][string]$Explicit)
  if (-not [string]::IsNullOrWhiteSpace($Explicit)) { return $Explicit }
  if (-not [string]::IsNullOrWhiteSpace($env:RIME_USER_DIR)) { return $env:RIME_USER_DIR }
  if ($env:OS -eq 'Windows_NT') {
    try {
      $regPath = 'HKCU:\Software\Rime\Weasel'
      if (Test-Path -LiteralPath $regPath) {
        $props = Get-ItemProperty -LiteralPath $regPath
        if ($props.RimeUserDir -and -not [string]::IsNullOrWhiteSpace([string]$props.RimeUserDir)) {
          return [string]$props.RimeUserDir
        }
      }
    } catch {
      Write-Host ("WARN: cannot read HKCU Software\Rime\Weasel ({0})" -f $_.Exception.Message)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
      return (Join-Path $env:APPDATA 'Rime')
    }
    throw 'APPDATA is empty. Re-run with -RimeUserDir pointing at the Weasel user directory (usually %APPDATA%\Rime).'
  }
  throw 'Rime user directory is unknown off Windows. Pass -RimeUserDir (on Windows 11 the default is %APPDATA%\Rime).'
}

function Find-WeaselInstall {
  $found = [pscustomobject]@{
    Root = $null
    SharedData = $null
    Deployer = $null
    Server = $null
  }
  if ($env:OS -ne 'Windows_NT') { return $found }

  $regPaths = @(
    'HKLM:\Software\Rime\Weasel',
    'HKLM:\Software\WOW6432Node\Rime\Weasel',
    'HKCU:\Software\Rime\Weasel'
  )
  foreach ($regPath in $regPaths) {
    try {
      if (-not (Test-Path -LiteralPath $regPath)) { continue }
      $props = Get-ItemProperty -LiteralPath $regPath
      $root = [string]$props.WeaselRoot
      if (-not [string]::IsNullOrWhiteSpace($root) -and (Test-Path -LiteralPath $root)) {
        $found.Root = $root
        break
      }
    } catch {
      Write-Host ("WARN: cannot read {0} ({1})" -f $regPath, $_.Exception.Message)
    }
  }
  if ([string]::IsNullOrWhiteSpace($found.Root)) {
    $bases = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
      [void]$bases.Add((Join-Path $env:ProgramFiles 'Rime'))
    }
    $pf86 = ${env:ProgramFiles(x86)}
    if (-not [string]::IsNullOrWhiteSpace($pf86)) {
      [void]$bases.Add((Join-Path $pf86 'Rime'))
    }
    foreach ($base in $bases) {
      if (-not (Test-Path -LiteralPath $base)) { continue }
      $dirs = @(Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'weasel*' })
      if ($dirs.Count -gt 0) {
        $found.Root = ($dirs | Sort-Object Name -Descending | Select-Object -First 1).FullName
        break
      }
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($found.Root)) {
    $data = Join-Path $found.Root 'data'
    if (Test-Path -LiteralPath $data) { $found.SharedData = $data }
    $deployer = Join-Path $found.Root 'WeaselDeployer.exe'
    if (Test-Path -LiteralPath $deployer) { $found.Deployer = $deployer }
    $server = Join-Path $found.Root 'WeaselServer.exe'
    if (Test-Path -LiteralPath $server) { $found.Server = $server }
  }
  return $found
}

function Test-RunningElevated {
  if ($env:OS -ne 'Windows_NT') { return $false }
  try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch {
    return $false
  }
}

function Test-DataFilePresent {
  param([string[]]$Dirs, [string]$Name)
  foreach ($dir in @($Dirs)) {
    if ([string]::IsNullOrWhiteSpace($dir)) { continue }
    $path = Join-Path $dir $Name
    if (Test-Path -LiteralPath $path) { return $true }
  }
  return $false
}

function Test-KinfxRimeLua {
  # True when rime.lua is still the file this repo installs. A user copy that
  # requires anything else is left in place on uninstall.
  param([Parameter(Mandatory = $true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $false }
  $text = Read-Utf8Text $Path
  if ($text -notmatch 'KINFX IME lua entry') { return $false }
  $allowed = @('win_quick', 'phrase_mix', 'melt_eng', 'lexicon_index')
  foreach ($match in [regex]::Matches($text, 'require\s*\(\s*["'']([^"'']+)["'']\s*\)')) {
    $name = $match.Groups[1].Value
    if ($allowed -notcontains $name) { return $false }
  }
  return $true
}

function Write-KinfxDeployManifest {
  param(
    [Parameter(Mandatory = $true)][string]$UserDir
  )
  $lines = New-Object System.Collections.Generic.List[string]
  [void]$lines.Add('# kinfx-ime deployed files. scripts/uninstall-windows.ps1 removes this allowlist only.')
  $retired = Get-KinfxRetiredUserRelativePaths
  foreach ($rel in (Get-KinfxOwnedUserRelativePaths)) {
    if ($rel -eq 'kinfx-ime.deployed.txt') { continue }
    if ($retired -contains $rel) { continue }
    [void]$lines.Add(($rel -replace '\\', '/'))
  }
  $path = Join-Path $UserDir 'kinfx-ime.deployed.txt'
  Write-Utf8NoBom $path (($lines.ToArray() -join "`n") + "`n")
}

$script:KinfxWeaselSkinBegin = '# kinfx-ime:weasel-skin begin'
$script:KinfxWeaselSkinEnd = '# kinfx-ime:weasel-skin end'
$script:KinfxWeaselSkinExampleRel = 'schemas/examples/weasel.custom.yaml.example'

function Get-YamlPatchKey {
  # Top-level or nested "key": / key: on a line. List items ("- key:") do not match.
  param([AllowNull()][string]$Line)
  if ([string]::IsNullOrEmpty($Line)) { return $null }
  if ($Line -match '^(\s+)"([^"]+)"\s*:') {
    return [pscustomobject]@{ Indent = $Matches[1].Length; Name = $Matches[2] }
  }
  if ($Line -match '^(\s+)([A-Za-z0-9_./+-]+)\s*:') {
    return [pscustomobject]@{ Indent = $Matches[1].Length; Name = $Matches[2] }
  }
  return $null
}

function Find-WeaselSkinSpan {
  # Inclusive indexes of the marker comments. $null when the file has neither.
  param($Lines)
  $begin = -1
  $end = -1
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*#\s*kinfx-ime:weasel-skin begin\s*$') {
      if ($begin -ge 0) {
        throw 'weasel.custom.yaml has more than one kinfx-ime:weasel-skin begin marker.'
      }
      $begin = $i
    } elseif ($line -match '^\s*#\s*kinfx-ime:weasel-skin end\s*$') {
      if ($begin -lt 0) {
        throw 'weasel.custom.yaml has a weasel-skin end marker without a begin marker.'
      }
      $end = $i
      break
    }
  }
  if ($begin -ge 0 -and $end -lt 0) {
    throw 'weasel.custom.yaml has a weasel-skin begin marker without an end marker.'
  }
  if ($begin -lt 0) { return $null }
  return [pscustomobject]@{ Start = $begin; End = $end }
}

function Get-KinfxWeaselSkinBlockLines {
  # The marked block from the example, including begin/end. One source of truth.
  param([Parameter(Mandatory = $true)][string]$RepoRoot)
  $path = Join-RepoPath $RepoRoot $script:KinfxWeaselSkinExampleRel
  if (-not (Test-Path -LiteralPath $path)) {
    throw ('KINFX Weasel skin example is missing: ' + $path)
  }
  $lines = ConvertTo-YamlLineList (Read-Utf8Text $path)
  $span = Find-WeaselSkinSpan $lines
  if ($null -eq $span) {
    throw ('KINFX Weasel skin example has no kinfx-ime:weasel-skin markers: ' + $path)
  }
  $block = New-Object System.Collections.Generic.List[string]
  for ($i = $span.Start; $i -le $span.End; $i++) {
    [void]$block.Add($lines[$i])
  }
  $joined = [string]::Join("`n", $block.ToArray())
  if ($joined -notmatch '"style/horizontal": false') {
    throw 'KINFX Weasel skin example must keep style/horizontal false (vertical list).'
  }
  if ($joined -notmatch '"style/layout/type": vertical') {
    throw 'KINFX Weasel skin example must keep style/layout/type vertical.'
  }
  if ($joined -notmatch 'kinfx_modern_dark' -or $joined -notmatch '"style/color_scheme": kinfx_modern') {
    throw 'KINFX Weasel skin example must define kinfx_modern and kinfx_modern_dark.'
  }
  if ($joined -match 'horizontal:\s*true' -or $joined -match 'page_size\s*:') {
    throw 'KINFX Weasel skin example must not switch to a horizontal list or set page_size.'
  }
  Write-Output -NoEnumerate $block.ToArray()
}

function Get-KinfxWeaselSkinOwnedKeys {
  # Quoted patch paths in the skin block. Nested scheme fields (name, text_color) are not owned.
  param([string[]]$SkinBlock)
  $keys = @{}
  foreach ($line in @($SkinBlock)) {
    if ($line -match '^\s+"([^"]+)"\s*:') {
      $keys[$Matches[1]] = $true
    }
  }
  return $keys
}

function Remove-OwnedKeysOutsideSkinBlock {
  # Drop flat copies of skin keys outside the marker so the file has one definition.
  # Keys inside the marker are replaced separately. Nested maps such as style/+ stay;
  # the skin block is appended last so its flat keys win on the next deploy.
  param($Lines, $Owned)
  if ($null -eq $Owned) { return }
  $spans = New-Object System.Collections.Generic.List[object]
  $inSkin = $false
  $i = 0
  while ($i -lt $Lines.Count) {
    $line = $Lines[$i]
    if ($line -match '^\s*#\s*kinfx-ime:weasel-skin begin\s*$') {
      $inSkin = $true
      $i++
      continue
    }
    if ($line -match '^\s*#\s*kinfx-ime:weasel-skin end\s*$') {
      $inSkin = $false
      $i++
      continue
    }
    if (-not $inSkin) {
      $key = Get-YamlPatchKey $line
      if ($null -ne $key -and $Owned.ContainsKey($key.Name)) {
        $j = $i + 1
        while ($j -lt $Lines.Count) {
          $next = $Lines[$j]
          if ($next -match '^\s*#\s*kinfx-ime:weasel-skin (begin|end)\s*$') { break }
          if ($next -match '^\s*$' -or $next -match '^\s*#') {
            $k = $j
            while ($k -lt $Lines.Count -and ($Lines[$k] -match '^\s*$' -or $Lines[$k] -match '^\s*#')) {
              if ($Lines[$k] -match '^\s*#\s*kinfx-ime:weasel-skin (begin|end)\s*$') { break }
              $k++
            }
            if ($k -ge $Lines.Count) { break }
            if ($Lines[$k] -match '^\s*#\s*kinfx-ime:weasel-skin (begin|end)\s*$') { break }
            $nextIndent = 0
            if ($Lines[$k] -match '^(\s*)') { $nextIndent = $Matches[1].Length }
            if ($nextIndent -gt $key.Indent) {
              $j = $k
              continue
            }
            break
          }
          $indent = 0
          if ($next -match '^(\s*)') { $indent = $Matches[1].Length }
          if ($indent -gt $key.Indent) {
            $j++
            continue
          }
          break
        }
        [void]$spans.Add([pscustomobject]@{ Start = $i; End = ($j - 1) })
        $i = $j
        continue
      }
    }
    $i++
  }
  for ($s = $spans.Count - 1; $s -ge 0; $s--) {
    Remove-ListRange $Lines $spans[$s].Start $spans[$s].End
  }
}

function Get-PatchSectionInsertIndex {
  # Index at the end of the patch: body. Column-0 comments stop the body.
  param($Lines)
  $patchIdx = -1
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^patch:\s*(#.*)?$') { $patchIdx = $i; break }
  }
  if ($patchIdx -lt 0) { return -1 }
  $i = $patchIdx + 1
  while ($i -lt $Lines.Count) {
    $line = $Lines[$i]
    if ($line -match '^\s*$' -or $line -match '^\s+#' -or $line -match '^\s+\S') {
      $i++
      continue
    }
    break
  }
  return $i
}

function Ensure-PatchKey {
  param($Lines)
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^patch:\s*(#.*)?$') { return }
  }
  if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') {
    [void]$Lines.Add('')
  }
  [void]$Lines.Add('patch:')
}

function Update-KinfxWeaselSkinText {
  # Insert or replace the lightweight skin. Unrelated patch keys stay.
  # Owned skin keys outside the marker are removed. The marker is always
  # rewritten at the end of patch: so it overrides an earlier style/+ merge.
  param(
    [AllowNull()][string]$Text,
    [Parameter(Mandatory = $true)][string[]]$SkinBlock
  )
  if ($null -eq $SkinBlock -or @($SkinBlock).Count -eq 0) {
    throw 'KINFX Weasel skin block is empty.'
  }
  if ([string]::IsNullOrWhiteSpace($Text)) {
    $Text = "patch:`n"
  }
  $lines = ConvertTo-YamlLineList $Text
  Assert-PatchMapIsBlock $lines 'weasel.custom.yaml'
  $owned = Get-KinfxWeaselSkinOwnedKeys $SkinBlock
  Remove-OwnedKeysOutsideSkinBlock $lines $owned
  $span = Find-WeaselSkinSpan $lines
  if ($null -ne $span) {
    Remove-ListRange $lines $span.Start $span.End
  }
  Ensure-PatchKey $lines
  $insertAt = Get-PatchSectionInsertIndex $lines
  if ($insertAt -lt 0) {
    throw 'weasel.custom.yaml is missing a patch: block.'
  }
  if ($insertAt -gt 0 -and $lines[$insertAt - 1] -match '\S') {
    $lines.Insert($insertAt, '')
    $insertAt++
  }
  $block = @($SkinBlock)
  for ($n = $block.Count - 1; $n -ge 0; $n--) {
    $lines.Insert($insertAt, [string]$block[$n])
  }
  return (Join-YamlLines $lines)
}

function New-KinfxWeaselCustomText {
  param([Parameter(Mandatory = $true)][string[]]$SkinBlock)
  $header = @(
    '# encoding: utf-8',
    '# KINFX Weasel lightweight candidate skin. Vertical list, light/dark colors.',
    '# Written by scripts/install-windows.ps1. Removed by scripts/uninstall-windows.ps1.'
  ) -join "`n"
  $body = Update-KinfxWeaselSkinText -Text "patch:`n" -SkinBlock $SkinBlock
  return ($header + "`n" + $body)
}

function Test-OnlyKinfxWeaselSkinResidue {
  # True when nothing remains except the header this repo writes for a new file.
  param($Lines)
  $allowed = @(
    '# encoding: utf-8',
    '# KINFX Weasel lightweight candidate skin. Vertical list, light/dark colors.',
    '# Written by scripts/install-windows.ps1. Removed by scripts/uninstall-windows.ps1.'
  )
  foreach ($line in @($Lines)) {
    if ([string]::IsNullOrWhiteSpace([string]$line)) { continue }
    $trim = ([string]$line).Trim()
    $ok = $false
    foreach ($item in $allowed) {
      if ($trim -eq $item) { $ok = $true; break }
    }
    if (-not $ok) { return $false }
  }
  # Empty residue (skin block only) and the stock header are both disposable.
  return $true
}

function Remove-KinfxWeaselSkinText {
  # Drop the marked skin. Leave every other patch. Delete only a file that
  # was solely the header plus that skin.
  param([AllowNull()][string]$Text)
  $result = [pscustomobject]@{ Text = $Text; Delete = $false }
  if ([string]::IsNullOrWhiteSpace($Text)) {
    $result.Text = ''
    return $result
  }
  $lines = ConvertTo-YamlLineList $Text
  Assert-PatchMapIsBlock $lines 'weasel.custom.yaml'
  $span = Find-WeaselSkinSpan $lines
  if ($null -eq $span) {
    $result.Text = $Text
    return $result
  }
  Remove-ListRange $lines $span.Start $span.End
  Remove-EmptyPatchKey $lines
  if (Test-OnlyKinfxWeaselSkinResidue $lines) {
    $result.Delete = $true
    $result.Text = ''
    return $result
  }
  $result.Text = Join-YamlLines $lines
  return $result
}
