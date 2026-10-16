param([string]$Codes = 'vd,hi', [string]$CodeFile = '', [string]$Out = '', [int]$Delay = 25)
# Reads Microsoft Quick candidate lists through TSF UILess mode (ITfUIElementSink).
# Nothing is committed: every code ends with Esc, so the MS IME does not learn.
$ErrorActionPreference = 'Stop'
if(-not $env:KWAIT){ $env:KWAIT = '600' }
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
[ComImport, Guid("1F02B6C5-7842-4EE6-8A0B-9A24183A95CA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfIPP {
  void Register(ref Guid a); void Unregister(ref Guid a);
  void AddLanguageProfile(ref Guid a, ushort l, ref Guid g, [MarshalAs(UnmanagedType.LPWStr)] string d, uint cd, [MarshalAs(UnmanagedType.LPWStr)] string f, uint cf, uint i);
  void RemoveLanguageProfile(ref Guid a, ushort l, ref Guid g);
  void EnumInputProcessorInfo(out IntPtr e);
  void GetDefaultLanguageProfile(ushort l, ref Guid c, out Guid a, out Guid g);
  void SetDefaultLanguageProfile(ushort l, ref Guid a, ref Guid g);
  void ActivateLanguageProfile(ref Guid a, ushort l, ref Guid g);
}
[ComImport, Guid("4ea48a35-60ae-446f-8fd6-e6a8d82459f7"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfSource {
  void AdviseSink(ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] object punk, out uint cookie);
  void UnadviseSink(uint cookie);
}
[ComImport, Guid("ea1ea136-19df-11d7-a6d2-00065b84435c"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfUIElementSink {
  [PreserveSig] int BeginUIElement(uint id, ref int show);
  [PreserveSig] int UpdateUIElement(uint id);
  [PreserveSig] int EndUIElement(uint id);
}
[ComImport, Guid("ea1ea135-19df-11d7-a6d2-00065b84435c"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfUIElementMgr {
  void BeginUIElement(IntPtr el, ref int show, out uint id);
  void UpdateUIElement(uint id);
  void EndUIElement(uint id);
  void GetUIElement(uint id, [MarshalAs(UnmanagedType.IUnknown)] out object el);
  void EnumUIElements(out IntPtr e);
}
[ComImport, Guid("ea1ea138-19df-11d7-a6d2-00065b84435c"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfCandidateListUIElement {
  void GetDescription([MarshalAs(UnmanagedType.BStr)] out string d);
  void GetGUID(out Guid g);
  void Show(int b);
  void IsShown(out int b);
  void GetUpdatedFlags(out uint f);
  void GetDocumentMgr(out IntPtr dm);
  void GetCount(out uint n);
  void GetSelection(out uint i);
  void GetString(uint i, [MarshalAs(UnmanagedType.BStr)] out string s);
  void GetPageIndex([Out, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1)] uint[] idx, uint size, out uint count);
  void SetPageIndex(IntPtr idx, uint count);
  void GetCurrentPage(out uint p);
}
[ComVisible(true), ClassInterface(ClassInterfaceType.None)]
public class KSink : ITfUIElementSink {
  public ITfUIElementMgr Mgr;
  public string Last = "";
  public int Events = 0;
  public string Desc = "";
  public int BeginUIElement(uint id, ref int show) { show = 0; Events++; Read(id); return 0; }
  public int UpdateUIElement(uint id) { Events++; Read(id); return 0; }
  public int EndUIElement(uint id) { return 0; }
  void Read(uint id) {
    try {
      object o; Mgr.GetUIElement(id, out o);
      var cl = o as ITfCandidateListUIElement;
      if (cl == null) return;
      uint n; cl.GetCount(out n);
      string d; try { cl.GetDescription(out d); Desc = d; } catch {}
      uint pc = 0; uint[] pages = new uint[64];
      try { cl.GetPageIndex(pages, 64, out pc); } catch {}
      var sb = new StringBuilder();
      sb.Append(n).Append(';');
      for (uint i = 0; i < pc && i < 64; i++) { if (i > 0) sb.Append(','); sb.Append(pages[i]); }
      sb.Append(';');
      for (uint i = 0; i < n; i++) { string s; cl.GetString(i, out s); if (i > 0) sb.Append('\u0001'); sb.Append(s); }
      Last = sb.ToString();
    } catch (Exception e) { Last = "ERR " + e.Message; }
  }
}
public static class KU {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("imm32.dll")] public static extern IntPtr ImmGetContext(IntPtr h);
  [DllImport("imm32.dll")] public static extern bool ImmReleaseContext(IntPtr h, IntPtr c);
  [DllImport("imm32.dll")] public static extern bool ImmSetOpenStatus(IntPtr c, bool o);
  [DllImport("imm32.dll")] public static extern bool ImmGetConversionStatus(IntPtr c, out uint a, out uint b);
  [DllImport("imm32.dll")] public static extern bool ImmSetConversionStatus(IntPtr c, uint a, uint b);
  public static KSink Sink;
  public static void Activate(string clsid, string prof) {
    var p = (ITfIPP)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("33C53A50-F456-4884-B049-85FD643ECFED")));
    Guid c = new Guid(clsid); Guid g = new Guid(prof); p.ActivateLanguageProfile(ref c, 0x0404, ref g);
  }
  public static string Hook() {
    object tm = Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("529A9E6B-6587-4F23-AB9E-9C7D683E3C50")));
    Sink = new KSink();
    Sink.Mgr = (ITfUIElementMgr)tm;
    var src = (ITfSource)tm;
    Guid iid = typeof(ITfUIElementSink).GUID; uint cookie;
    src.AdviseSink(ref iid, Sink, out cookie);
    return "cookie=" + cookie;
  }
  public static uint Native(IntPtr h) { IntPtr c = ImmGetContext(h); uint a,b; ImmGetConversionStatus(c,out a,out b); ImmSetOpenStatus(c,true); ImmSetConversionStatus(c,(a|1u)&~8u,b); uint x,y; ImmGetConversionStatus(c,out x,out y); ImmReleaseContext(h,c); return x; }
}
"@
function Pump([int]$ms) { $sw=[Diagnostics.Stopwatch]::StartNew(); while($sw.ElapsedMilliseconds -lt $ms){ [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 2 } }
function Key([int]$vk,[int]$after){ [KU]::keybd_event([byte]$vk,0,0,[UIntPtr]::Zero); Pump 6; [KU]::keybd_event([byte]$vk,0,2,[UIntPtr]::Zero); Pump $after }
$form = New-Object Windows.Forms.Form; $form.Text='kinfx ms-uiless'; $form.Width=420; $form.Height=100; $form.TopMost=$true; $form.StartPosition='CenterScreen'
$tb = New-Object Windows.Forms.TextBox; $tb.Dock='Fill'; $form.Controls.Add($tb)
$form.Show(); Pump 400; [void]$form.Activate(); [void][KU]::SetForegroundWindow($form.Handle); Pump 200; [void]$tb.Focus(); Pump 200
foreach($il in [Windows.Forms.InputLanguage]::InstalledInputLanguages){ if($il.Culture.Name -eq 'zh-TW'){ [Windows.Forms.InputLanguage]::CurrentInputLanguage=$il } }
Pump 300
Write-Output ("hook " + [KU]::Hook())
[KU]::Activate('531FDEBF-9B4C-4A43-A2AA-960E8FCDC732','6024B45F-5C54-11D4-B921-0080C882687E'); Pump 500
[void][KU]::Native($tb.Handle); Pump 300; [void][KU]::Native($tb.Handle); Pump 300
$list = @()
if($CodeFile){ $list = Get-Content -Encoding UTF8 $CodeFile } else { $list = $Codes -split ',' }
$res = New-Object System.Collections.ArrayList
$i = 0
foreach($code in $list){
  if(-not $code){ continue }
  $i++
  if(($i % 40) -eq 0){ [void][KU]::SetForegroundWindow($form.Handle); [void]$tb.Focus() }
  [KU]::Sink.Last = ''
  $sp = $code.EndsWith('_'); $kc = $code.TrimEnd('_')
  foreach($c in $kc.ToCharArray()){ Key ([int][char]$c - 32) $Delay }
  if($sp){ Pump 80; Key 0x20 $Delay }
  $sw=[Diagnostics.Stopwatch]::StartNew()
  while([KU]::Sink.Last -eq '' -and $sw.ElapsedMilliseconds -lt $env:KWAIT){ Pump 10 }
  Pump 30
  $r = [KU]::Sink.Last
  Key 0x1B 20; Key 0x1B 20
  if($tb.Text -ne ''){ $tb.Clear() }
  [void]$res.Add($code + "`t" + $r)
  if(-not $Out){ Write-Output ($code + "`t" + $r.Replace([string][char]1,' ')) }
}
Write-Output ("events=" + [KU]::Sink.Events + " desc=" + [KU]::Sink.Desc)
$form.Close()
if($Out){ [IO.File]::WriteAllLines($Out, [string[]]$res, (New-Object Text.UTF8Encoding($false))) }
