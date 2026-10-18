# Types "of" into a WinForms textbox through Weasel (zh-TW) and screenshots the candidate window.
# Output: $env:TEMP\kinfx-ime\preedit-of.png
param([string]$Keys = 'of', [string]$Out = "$env:TEMP\kinfx-ime\preedit-of.png")
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class KP {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
function Pump([int]$ms) { $t = [DateTime]::Now.AddMilliseconds($ms); while ([DateTime]::Now -lt $t) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 15 } }
function Key([int]$vk) { [KP]::keybd_event([byte]$vk,0,0,[UIntPtr]::Zero); Pump 40; [KP]::keybd_event([byte]$vk,0,2,[UIntPtr]::Zero); Pump 120 }
$f = New-Object System.Windows.Forms.Form
$f.Text = 'KINFX preedit check'; $f.Width = 700; $f.Height = 420; $f.StartPosition = 'Manual'; $f.Left = 200; $f.Top = 200; $f.TopMost = $true
$tb = New-Object System.Windows.Forms.TextBox; $tb.Multiline = $true; $tb.Dock = 'Fill'; $tb.Font = New-Object System.Drawing.Font('Microsoft JhengHei', 16)
$f.Controls.Add($tb); $f.Show(); Pump 400; [void][KP]::SetForegroundWindow($f.Handle); $tb.Focus() | Out-Null; Pump 300
$zh = [System.Windows.Forms.InputLanguage]::InstalledInputLanguages | ? { $_.Culture.Name -eq 'zh-TW' } | select -First 1
if ($zh) { [System.Windows.Forms.InputLanguage]::CurrentInputLanguage = $zh; Pump 400 }
# land on Weasel: probe hello + Space must give "hello " (KINFX only)
$ok = $false
for ($i = 0; $i -lt 6 -and -not $ok; $i++) {
  $tb.Text = ''; Key 0x1B
  foreach ($c in 'hello'.ToCharArray()) { Key ([int][char]$c - 32) }; Key 0x20; Pump 400
  if ($tb.Text -eq 'hello ') { $ok = $true; break }
  Key 0x1B
  [KP]::keybd_event(0x5B,0,0,[UIntPtr]::Zero); Pump 60; Key 0x20; [KP]::keybd_event(0x5B,0,2,[UIntPtr]::Zero); Pump 900
}
$tb.Text = ''; Pump 200
foreach ($c in $Keys.ToCharArray()) { Key ([int][char]$c - 32) }
Pump 700
$bmp = New-Object System.Drawing.Bitmap 900, 700
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen(150, 150, 0, 0, $bmp.Size); $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
Key 0x1B; Pump 200
"route=$ok keys=$Keys text=[$($tb.Text)] png=$Out"
$f.Close()
