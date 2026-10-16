// rimeh: headless librime harness for KINFX IME on Windows.
// Loads Weasel's rime.dll against a separate user dir (never the live %APPDATA%\Rime),
// deploys, then reads commands from stdin and prints results as TSV.
//
//   rimeh.exe <shared_dir> <user_dir> [--no-deploy]
//   stdin:  schema <id>
//           keys <rime key sequence>     e.g.  keys vd{space}{Return}
//           bench <rime key sequence> <repeat>
//           clear
// Output per keys line:  OK<TAB>commit<TAB>preedit<TAB>cand1|cand2|...<TAB>micros
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

static class Rime {
    const string D = "rime.dll";
    [StructLayout(LayoutKind.Sequential)]
    public struct Traits {
        public int data_size;
        public IntPtr shared_data_dir, user_data_dir, distribution_name, distribution_code_name,
            distribution_version, app_name, modules;
        public int min_log_level;
        public IntPtr log_dir, prebuilt_data_dir, staging_dir;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct Commit { public int data_size; public IntPtr text; }
    [StructLayout(LayoutKind.Sequential)]
    public struct Iter { public IntPtr ptr; public int index; public IntPtr text, comment, reserved; }
    [StructLayout(LayoutKind.Sequential)]
    public struct Context {
        public int data_size; public int len, cursor, ss, se; public IntPtr preedit;
        public int page_size, page_no, is_last, hl, num; public IntPtr cands, select_keys;
        public IntPtr commit_preview, select_labels;
    }
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void RimeSetup(ref Traits t);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void RimeInitialize(ref Traits t);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void RimeFinalize();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeStartMaintenance(int full);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void RimeJoinMaintenanceThread();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern UIntPtr RimeCreateSession();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeSelectSchema(UIntPtr s, byte[] id);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeSimulateKeySequence(UIntPtr s, byte[] seq);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeProcessKey(UIntPtr s, int code, int mask);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeGetCommit(UIntPtr s, ref Commit c);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeFreeCommit(ref Commit c);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeGetContext(UIntPtr s, ref Context c);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeFreeContext(ref Context c);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void RimeClearComposition(UIntPtr s);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeCandidateListBegin(UIntPtr s, ref Iter it);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int RimeCandidateListNext(ref Iter it);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void RimeCandidateListEnd(ref Iter it);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] public static extern bool SetDllDirectory(string p);
}

static class P {
    static IntPtr U8(string s) {
        if (s == null) return IntPtr.Zero;
        var b = Encoding.UTF8.GetBytes(s + "\0");
        var p = Marshal.AllocHGlobal(b.Length); Marshal.Copy(b, 0, p, b.Length); return p;
    }
    static byte[] Z(string s) { return Encoding.UTF8.GetBytes(s + "\0"); }
    static string S(IntPtr p) {
        if (p == IntPtr.Zero) return "";
        int n = 0; while (Marshal.ReadByte(p, n) != 0) n++;
        var b = new byte[n]; Marshal.Copy(p, b, 0, n); return Encoding.UTF8.GetString(b);
    }
    static string Clean(string s) { return s.Replace("\t", " ").Replace("\n", " ").Replace("|", "¦"); }

    static string ReadCommit(UIntPtr s) {
        var c = new Rime.Commit(); c.data_size = Marshal.SizeOf(typeof(Rime.Commit)) - 4;
        if (Rime.RimeGetCommit(s, ref c) == 0) return "";
        var t = S(c.text); Rime.RimeFreeCommit(ref c); return t;
    }
    static string Preedit(UIntPtr s) {
        var c = new Rime.Context(); c.data_size = Marshal.SizeOf(typeof(Rime.Context)) - 4;
        if (Rime.RimeGetContext(s, ref c) == 0) return "";
        var t = S(c.preedit); Rime.RimeFreeContext(ref c); return t;
    }
    static List<string> Cands(UIntPtr s, int max) {
        var l = new List<string>();
        var it = new Rime.Iter();
        if (Rime.RimeCandidateListBegin(s, ref it) == 0) return l;
        while (l.Count < max && Rime.RimeCandidateListNext(ref it) != 0) {
            var c = S(it.comment);
            l.Add(Clean(S(it.text)) + (c.Length > 0 ? "~" + Clean(c) : ""));
        }
        Rime.RimeCandidateListEnd(ref it);
        return l;
    }

    static int Main(string[] a) {
        Console.OutputEncoding = new UTF8Encoding(false);
        var stdin = new StreamReader(Console.OpenStandardInput(), new UTF8Encoding(false));
        string shared = a[0], user = a[1];
        bool deploy = Array.IndexOf(a, "--no-deploy") < 0;
        int maxc = 400;
        Rime.SetDllDirectory(Path.GetDirectoryName(Path.GetFullPath(shared)));
        var t = new Rime.Traits();
        t.data_size = Marshal.SizeOf(typeof(Rime.Traits)) - 4;
        t.shared_data_dir = U8(shared); t.user_data_dir = U8(user);
        t.distribution_name = U8("rimeh"); t.distribution_code_name = U8("rimeh"); t.distribution_version = U8("1");
        t.app_name = U8("rime.rimeh"); t.min_log_level = 1; t.log_dir = U8(Path.Combine(user, "log"));
        Directory.CreateDirectory(Path.Combine(user, "log"));
        var sw = Stopwatch.StartNew();
        Rime.RimeSetup(ref t);
        Rime.RimeInitialize(ref t);
        if (deploy) { if (Rime.RimeStartMaintenance(1) != 0) Rime.RimeJoinMaintenanceThread(); }
        Console.WriteLine("INIT\t" + sw.ElapsedMilliseconds + "ms");
        var s = Rime.RimeCreateSession();
        string line;
        while ((line = stdin.ReadLine()) != null) {
            line = line.TrimEnd('\r');
            if (line.Length == 0 || line.StartsWith("#")) continue;
            var sp = line.IndexOf(' ');
            var cmd = sp < 0 ? line : line.Substring(0, sp);
            var arg = sp < 0 ? "" : line.Substring(sp + 1);
            if (cmd == "schema") {
                sw.Restart();
                var ok = Rime.RimeSelectSchema(s, Z(arg));
                Console.WriteLine("SCHEMA\t" + arg + "\t" + ok + "\t" + sw.Elapsed.TotalMilliseconds.ToString("F1") + "ms");
            } else if (cmd == "max") {
                maxc = int.Parse(arg);
            } else if (cmd == "clear") {
                Rime.RimeClearComposition(s); ReadCommit(s);
            } else if (cmd == "keys") {
                Rime.RimeClearComposition(s); ReadCommit(s);
                sw.Restart();
                Rime.RimeSimulateKeySequence(s, Z(arg));
                var us = sw.Elapsed.TotalMilliseconds * 1000;
                var commit = ReadCommit(s);
                Console.WriteLine("OK\t" + arg + "\t" + Clean(commit) + "\t" + Clean(Preedit(s)) + "\t" +
                    string.Join("|", Cands(s, maxc)) + "\t" + us.ToString("F0"));
            } else if (cmd == "bench") {
                // bench <seq> <n>: time each RimeSimulateKeySequence of seq, n times, clearing between
                var parts = arg.Split(' ');
                int n = int.Parse(parts[parts.Length - 1]);
                var seq = string.Join(" ", parts, 0, parts.Length - 1);
                var times = new List<double>();
                for (int i = 0; i < n; i++) {
                    Rime.RimeClearComposition(s); ReadCommit(s);
                    sw.Restart();
                    Rime.RimeSimulateKeySequence(s, Z(seq));
                    times.Add(sw.Elapsed.TotalMilliseconds * 1000);
                    ReadCommit(s);
                }
                times.Sort();
                Console.WriteLine("BENCH\t" + seq + "\tp50=" + times[n / 2].ToString("F0") + "us\tp95=" +
                    times[(int)(n * 0.95)].ToString("F0") + "us\tmax=" + times[n - 1].ToString("F0") + "us\tlen=" + seq.Length);
            }
            Console.Out.Flush();
        }
        Rime.RimeFinalize();
        return 0;
    }
}
