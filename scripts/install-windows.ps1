#Requires -Version 5.1
<#
.SYNOPSIS
  Copy KINFX schemas into the Weasel (小狼毫) per-user Rime directory.

.DESCRIPTION
  Idempotent. Copies schema, lua, and lexicon files to %APPDATA%\Rime and
  merges kinfx_quick / kinfx_jyutping into default.custom.yaml without
  removing other schemas. Merges the lightweight vertical candidate skin
  (schemas/examples/weasel.custom.yaml.example) into weasel.custom.yaml
  without removing unrelated patches. Does not copy a full default.yaml:
  Weasel's shared data must stay in charge, and *.custom.yaml is the patch.
  Does not install Weasel, register a TSF profile, or require elevation for
  the file copy. Does not change page size or candidate order.

  Release v0.4.0. This script does not create a git tag.
#>
[CmdletBinding()]
param(
  [string]$RimeUserDir,
  [string]$RepoRoot,
  [switch]$NoDeploy
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows-rime.ps1')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}

$missing = Get-MissingKinfxSources $RepoRoot
if ($missing.Count -gt 0) {
  Write-Host 'ERROR: KINFX source files are missing. Run this script from a checkout or the Windows share zip.'
  foreach ($path in $missing) {
    Write-Host ("  missing {0}" -f $path)
  }
  exit 1
}

$userDir = Resolve-RimeUserDir $RimeUserDir
if ([string]::IsNullOrWhiteSpace($userDir)) {
  throw 'Rime user directory resolved empty. Pass -RimeUserDir.'
}
if (Test-Path -LiteralPath $userDir -PathType Leaf) {
  throw ("Rime user path exists and is a file, not a directory: {0}" -f $userDir)
}
if (-not (Test-Path -LiteralPath $userDir)) {
  New-Item -ItemType Directory -Path $userDir -Force | Out-Null
}

Write-Host ("KINFX schema pack -> {0}" -f $userDir)
Write-Host 'Host: Weasel (小狼毫). This repo does not register a TSF text service.'

if ((Test-RunningElevated) -and [string]::IsNullOrWhiteSpace($RimeUserDir) -and [string]::IsNullOrWhiteSpace($env:RIME_USER_DIR)) {
  Write-Host 'WARN: this window is elevated. %APPDATA% may belong to the administrator account, so schemas would land in the wrong profile. Run again as the Windows user who types, or pass -RimeUserDir explicitly.'
}

foreach ($item in (Get-KinfxDeployItems)) {
  $src = Join-RepoPath $RepoRoot $item.Src
  $dest = Join-RepoPath $userDir $item.Rel
  $destParent = Split-Path -Parent $dest
  if (-not [string]::IsNullOrWhiteSpace($destParent) -and -not (Test-Path -LiteralPath $destParent)) {
    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
  }
  Copy-Item -LiteralPath $src -Destination $dest -Force
  Write-Host ("  + {0}" -f $item.Rel)
}
foreach ($old in (Get-KinfxRetiredUserRelativePaths)) {
  $oldPath = Join-RepoPath $userDir $old
  if (Test-Path -LiteralPath $oldPath) {
    Remove-Item -LiteralPath $oldPath -Force
    Write-Host ("  - {0} (retired in v0.4)" -f $old)
  }
}
Write-KinfxDeployManifest $userDir

$weasel = Find-WeaselInstall
$seed = @()
if (-not [string]::IsNullOrWhiteSpace($weasel.SharedData)) {
  $sharedDefault = Join-Path $weasel.SharedData 'default.yaml'
  $seed = Get-SchemaIdsFromYamlFile $sharedDefault
  Write-Host ("Weasel shared data: {0}" -f $weasel.SharedData)
} else {
  Write-Host 'WARN: Weasel was not found. Schemas are copied anyway. Install Weasel, then run this script again so default.custom.yaml can keep Weasel''s other schemas.'
  Write-Host '  winget install Rime.Weasel'
  Write-Host '  https://github.com/rime/weasel/releases'
}

$customPath = Join-Path $userDir 'default.custom.yaml'
$existed = Test-Path -LiteralPath $customPath
if ($existed) {
  $updated = Update-KinfxSchemaListText (Read-Utf8Text $customPath) $seed
} else {
  $updated = New-KinfxDefaultCustomText $seed
}
Write-Utf8NoBom $customPath $updated
$writtenIds = Get-SchemaIdSequence (Get-AllSchemaEntries $updated)
Write-Host ("default.custom.yaml schema_list: {0}" -f ($writtenIds -join ', '))
if (-not $existed) {
  Write-Host '  created default.custom.yaml (other Weasel schemas kept when Weasel shared data was readable)'
} else {
  Write-Host '  merged default.custom.yaml (existing schemas kept; missing KINFX and Weasel schemas added)'
}

$skinBlock = Get-KinfxWeaselSkinBlockLines $RepoRoot
$weaselCustomPath = Join-Path $userDir 'weasel.custom.yaml'
$weaselExisted = Test-Path -LiteralPath $weaselCustomPath
if ($weaselExisted) {
  $weaselText = Update-KinfxWeaselSkinText (Read-Utf8Text $weaselCustomPath) $skinBlock
  Write-Host '  merged weasel.custom.yaml (lightweight kinfx_modern skin; other patches kept)'
} else {
  $weaselText = New-KinfxWeaselCustomText $skinBlock
  Write-Host '  created weasel.custom.yaml (kinfx_modern / kinfx_modern_dark, vertical, lightweight)'
}
Write-Utf8NoBom $weaselCustomPath $weaselText

$searchDirs = @($userDir)
if (-not [string]::IsNullOrWhiteSpace($weasel.SharedData)) { $searchDirs += $weasel.SharedData }
if (-not (Test-DataFilePresent $searchDirs 'jyut6ping3.dict.yaml') -and -not (Test-DataFilePresent $searchDirs 'jyut6ping3.schema.yaml')) {
  Write-Host 'WARN: jyut6ping3 was not found. KINFX 速成 (kinfx_quick) does not need it. KINFX 粵拼 (kinfx_jyutping) will not deploy until rime-cantonese data is in the user or Weasel shared directory.'
  Write-Host '  https://github.com/rime/rime-cantonese'
}
if (-not (Test-DataFilePresent $searchDirs 'luna_pinyin.dict.yaml')) {
  Write-Host 'WARN: luna_pinyin.dict.yaml was not found. Sucheng reverse lookup (backtick) needs it. A normal Weasel install already ships luna_pinyin under its data directory.'
}

Write-Host ''
Write-Host 'Next:'
Write-Host '  1. Redeploy Weasel: right-click the tray icon -> 重新部署'
Write-Host '     or: WeaselDeployer.exe /deploy'
Write-Host '  2. Win+Space, choose 小狼毫 / RIME.'
Write-Host '  3. Select schema: KINFX 中英混打輸入法 · 速成  (schema_id kinfx_quick).'
Write-Host '     Jyutping: KINFX 中英混打輸入法 · 粵拼  (schema_id kinfx_jyutping).'
Write-Host 'v0.4.0: Windows 11 Quick order on every page; page_size 9, vertical, Space pages, 1-9/Enter select, Tab expands.'
Write-Host 'Candidate skin: rounded corners, soft shadow, light/dark. Static colors only (no images or animation). See docs/WINDOWS.md.'
Write-Host 'Smoke: vd -> 好, ofc 1 -> 人類, ofca -> 無錯, gmai -> Gmail. See docs/WINDOWS.md.'

$deployed = $false
if ($NoDeploy) {
  Write-Host 'Deploy skipped (-NoDeploy).'
} elseif ([string]::IsNullOrWhiteSpace($weasel.Deployer)) {
  Write-Host 'WeaselDeployer.exe was not found. Redeploy from the tray menu after Weasel is installed.'
} else {
  Write-Host ("Running {0} /deploy" -f $weasel.Deployer)
  $proc = Start-Process -FilePath $weasel.Deployer -ArgumentList '/deploy' -WorkingDirectory (Split-Path -Parent $weasel.Deployer) -Wait -PassThru -WindowStyle Hidden
  if ($proc.ExitCode -ne 0) {
    Write-Host ("ERROR: WeaselDeployer exited {0}. Schemas are copied; redeploy from the tray menu (重新部署)." -f $proc.ExitCode)
    exit 1
  }
  $deployed = $true
  Write-Host 'WeaselDeployer /deploy finished.'
}

if (-not $deployed) {
  Write-Host 'Schemas are in the user directory. They are not active until Weasel redeploys.'
}
exit 0
