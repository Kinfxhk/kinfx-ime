#Requires -Version 5.1
<#
.SYNOPSIS
  Remove KINFX files from the Weasel per-user Rime directory.

.DESCRIPTION
  Deletes only the kinfx-owned schema, dictionary, lua, and manifest files.
  Drops kinfx_quick / kinfx_jyutping from default.custom.yaml and leaves every
  other schema. Drops the kinfx-ime:weasel-skin block from weasel.custom.yaml
  and leaves unrelated patches. Does not uninstall Weasel. Does not require
  elevation.

  rime.lua is removed only when it is still the KINFX entry this repo wrote.
  If it requires any other module, it is left in place and a warning is printed.
#>
[CmdletBinding()]
param(
  [string]$RimeUserDir,
  [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows-rime.ps1')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}

$userDir = Resolve-RimeUserDir $RimeUserDir
if (-not (Test-Path -LiteralPath $userDir)) {
  Write-Host ("Nothing to remove. Rime user directory does not exist: {0}" -f $userDir)
  exit 0
}
if (Test-Path -LiteralPath $userDir -PathType Leaf) {
  throw ("Rime user path is a file, not a directory: {0}" -f $userDir)
}

Write-Host ("Removing KINFX files from {0}" -f $userDir)
Write-Host 'Weasel itself is not uninstalled. Use Apps & Features or: winget uninstall Rime.Weasel'

$allow = @{}
foreach ($rel in (Get-KinfxOwnedUserRelativePaths)) {
  $allow[$rel] = $true
}

foreach ($rel in @($allow.Keys)) {
  if ($rel -eq 'kinfx-ime.deployed.txt') { continue }
  if ($rel -eq 'rime.lua') { continue }
  $path = Join-RepoPath $userDir $rel
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Force
    Write-Host ("  - {0}" -f $rel)
  }
}

$rimeLua = Join-Path $userDir 'rime.lua'
if (Test-Path -LiteralPath $rimeLua) {
  if (Test-KinfxRimeLua $rimeLua) {
    Remove-Item -LiteralPath $rimeLua -Force
    Write-Host '  - rime.lua'
  } else {
    Write-Host 'WARN: left rime.lua in place because it is not the stock KINFX entry (or it requires other modules). Remove the KINFX require lines yourself if you still want them gone.'
  }
}

$luaDir = Join-Path $userDir 'lua'
if (Test-Path -LiteralPath $luaDir -PathType Container) {
  $left = @(Get-ChildItem -LiteralPath $luaDir -Force -ErrorAction SilentlyContinue)
  if ($left.Count -eq 0) {
    Remove-Item -LiteralPath $luaDir -Force
    Write-Host '  - lua/ (empty after KINFX files were removed)'
  }
}

$buildDir = Join-Path $userDir 'build'
if (Test-Path -LiteralPath $buildDir -PathType Container) {
  $prefixes = @('kinfx_quick', 'kinfx_jyutping', 'kinfx_hk_words', 'kinfx_hk_idioms', 'kinfx_en')
  foreach ($file in @(Get-ChildItem -LiteralPath $buildDir -Force -ErrorAction SilentlyContinue)) {
    foreach ($prefix in $prefixes) {
      if ($file.Name.StartsWith($prefix)) {
        Remove-Item -LiteralPath $file.FullName -Force -Recurse
        Write-Host ("  - build/{0}" -f $file.Name)
        break
      }
    }
  }
}

foreach ($schemaId in @('kinfx_quick', 'kinfx_jyutping')) {
  foreach ($db in @(Get-ChildItem -LiteralPath $userDir -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "$schemaId.userdb" -or $_.Name -like "$schemaId.userdb.*" })) {
    Remove-Item -LiteralPath $db.FullName -Force -Recurse
    Write-Host ("  - {0} (learned user dict)" -f $db.Name)
  }
}

$manifest = Join-Path $userDir 'kinfx-ime.deployed.txt'
if (Test-Path -LiteralPath $manifest) {
  Remove-Item -LiteralPath $manifest -Force
  Write-Host '  - kinfx-ime.deployed.txt'
}

$weaselCustomPath = Join-Path $userDir 'weasel.custom.yaml'
if (Test-Path -LiteralPath $weaselCustomPath) {
  $originalSkin = Read-Utf8Text $weaselCustomPath
  $editedSkin = Remove-KinfxWeaselSkinText $originalSkin
  if ($editedSkin.Delete) {
    Remove-Item -LiteralPath $weaselCustomPath -Force
    Write-Host '  - weasel.custom.yaml (only the KINFX lightweight skin remained)'
  } elseif ($editedSkin.Text -ne $originalSkin) {
    Write-Utf8NoBom $weaselCustomPath $editedSkin.Text
    Write-Host '  weasel.custom.yaml: removed KINFX skin block; other patches kept'
  }
}

$customPath = Join-Path $userDir 'default.custom.yaml'
if (Test-Path -LiteralPath $customPath) {
  $weasel = Find-WeaselInstall
  $sharedIds = @()
  if (-not [string]::IsNullOrWhiteSpace($weasel.SharedData)) {
    $sharedIds = Get-SchemaIdsFromYamlFile (Join-Path $weasel.SharedData 'default.yaml')
  }
  $edited = Remove-KinfxSchemaListText (Read-Utf8Text $customPath) $sharedIds
  if ($edited.Delete) {
    Remove-Item -LiteralPath $customPath -Force
    Write-Host '  - default.custom.yaml (only KINFX schema_list remained)'
  } else {
    Write-Utf8NoBom $customPath $edited.Text
    $leftIds = Get-SchemaIdSequence (Get-AllSchemaEntries $edited.Text)
    $shown = '(no schema_list override)'
    if ($leftIds.Count -gt 0) { $shown = $leftIds -join ', ' }
    Write-Host ("  default.custom.yaml schema_list now: {0}" -f $shown)
  }
}

Write-Host ''
Write-Host 'KINFX schemas are removed from this user directory. Other Rime schemas were left as they were.'
Write-Host 'Redeploy Weasel (重新部署 or WeaselDeployer.exe /deploy) so the menu drops KINFX.'
Write-Host 'To remove the IME host: Settings -> Apps -> 小狼毫, or winget uninstall Rime.Weasel.'
exit 0
