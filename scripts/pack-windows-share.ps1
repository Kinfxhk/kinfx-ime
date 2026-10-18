#Requires -Version 5.1
<#
.SYNOPSIS
  Build dist/kinfx-ime-windows-share.zip for handing the schema pack to someone else.

.DESCRIPTION
  The zip keeps repo-relative paths so install-windows.ps1 can find schemas
  next to scripts/. It does not include third_party sources, build output, or
  git metadata. Legal notices ride along because the lexicons are not MIT.
#>
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$OutputZip
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows-rime.ps1')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}
if ([string]::IsNullOrWhiteSpace($OutputZip)) {
  $OutputZip = Join-RepoPath $RepoRoot 'dist/kinfx-ime-windows-share.zip'
}

$relative = New-Object System.Collections.Generic.List[string]
foreach ($rel in @(
    'docs/WINDOWS.md',
    'schemas/examples/weasel.custom.yaml.example',
    'scripts/install-windows.ps1',
    'scripts/uninstall-windows.ps1',
    'scripts/windows-rime.ps1',
    'LICENSE',
    'NOTICE',
    'licenses/rime-quick-LGPL-3.0.txt',
    'lexicon/NOTICE',
    'lexicon/en/extras.tsv'
  )) {
  [void]$relative.Add($rel)
}
foreach ($item in (Get-KinfxDeployItems)) {
  [void]$relative.Add($item.Src)
}

$missing = New-Object System.Collections.Generic.List[string]
foreach ($rel in $relative) {
  $src = Join-RepoPath $RepoRoot $rel
  if (-not (Test-Path -LiteralPath $src)) { [void]$missing.Add($src) }
}
if ($missing.Count -gt 0) {
  Write-Host 'ERROR: share pack is missing inputs:'
  foreach ($path in $missing) { Write-Host ("  missing {0}" -f $path) }
  exit 1
}

$outParent = Split-Path -Parent $OutputZip
if (-not [string]::IsNullOrWhiteSpace($outParent) -and -not (Test-Path -LiteralPath $outParent)) {
  New-Item -ItemType Directory -Path $outParent -Force | Out-Null
}
if (Test-Path -LiteralPath $OutputZip) {
  Remove-Item -LiteralPath $OutputZip -Force
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$archive = [System.IO.Compression.ZipFile]::Open($OutputZip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($rel in $relative) {
    $src = Join-RepoPath $RepoRoot $rel
    $entryName = ($rel -replace '\\', '/')
    [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
      $archive,
      $src,
      $entryName,
      [System.IO.Compression.CompressionLevel]::Optimal)
  }
  $share = @'
KINFX 中英混打輸入法 — Windows 11 分享包
版本見 GitHub Releases：https://github.com/Kinfxhk/kinfx-ime/releases

1. 裝 Weasel（小狼毫）：winget install Rime.Weasel
   或 https://github.com/rime/weasel/releases
2. 解壓呢個 zip，保留目錄結構。
3. 用打字嗰個 Windows 帳戶（唔好用管理員身分）跑：
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
4. 小狼毫圖示右鍵 → 重新部署。
5. Win+Space 揀小狼毫，選「KINFX 中英混打輸入法 · 速成」。
   候選窗係輕量皮膚：圓角、淺陰影、淺色／深色，仍然直列每頁 9。

說明同驗收表：docs/WINDOWS.md（候選窗外觀）
卸載 KINFX 檔：scripts/uninstall-windows.ps1
小狼毫本體：設定 → 應用程式，或 winget uninstall Rime.Weasel

詞庫唔係 MIT。見 NOTICE、lexicon/NOTICE、licenses/rime-quick-LGPL-3.0.txt。
'@
  $entry = $archive.CreateEntry('WINDOWS-SHARE.txt', [System.IO.Compression.CompressionLevel]::Optimal)
  $writer = New-Object System.IO.StreamWriter($entry.Open(), (New-Object System.Text.UTF8Encoding $false))
  try {
    $writer.Write($share.Replace("`r`n", "`n").TrimEnd("`n") + "`n")
  } finally {
    $writer.Dispose()
  }
} finally {
  $archive.Dispose()
}

Write-Host ("Wrote {0}" -f $OutputZip)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$check = [System.IO.Compression.ZipFile]::OpenRead($OutputZip)
try {
  foreach ($entry in $check.Entries) {
    Write-Host ("  {0}" -f $entry.FullName)
  }
} finally {
  $check.Dispose()
}
exit 0
