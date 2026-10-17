"""Measure which English words KINFX v0.5.3 can type straight (Space / Left Shift).

For every word w (lowercase letters only) run rimeh `typed w{space}` and
`typed w{Shift_L}{Release+Shift_L}` on a staged user dir and classify:
  space   - Space commits the word (case-insensitive, any trailing space)
  shift   - only Left Shift commits it
  broken  - neither: Chinese leaks in (adsense -> 杲sense)
Usage: python english_reach.py <userdir> <wordfile> <out.tsv> [limit]
"""
import subprocess, sys, os, re, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RIMEH = os.path.join(ROOT, "tools", "rimeh", "rimeh.exe")
SHARED = os.environ.get("RIMEH_SHARED", "C:/Program Files/Rime/weasel-0.17.4/data")


def run(userdir, words):
    cmds = ["schema kinfx_quick"]
    for w in words:
        cmds.append(f"typed {w}{{space}}")
        cmds.append(f"typed {w}{{Shift_L}}{{Release+Shift_L}}")
    p = subprocess.run([RIMEH, SHARED, userdir, "--no-deploy"], input="\n".join(cmds) + "\n",
                       capture_output=True, text=True, encoding="utf-8")
    out = {}
    for line in p.stdout.splitlines():
        f = line.rstrip("\r").split("\t")
        if len(f) >= 3 and f[0] == "TYPED":
            out[f[1]] = f[2]
    return out


def classify(w, sp, sh):
    def ok(t):
        return t is not None and t.strip().lower() == w
    if ok(sp):
        return "space"
    if ok(sh):
        return "shift"
    return "broken"


def main():
    userdir, wordfile, outp = sys.argv[1:4]
    limit = int(sys.argv[4]) if len(sys.argv) > 4 else 0
    words = []
    for l in open(wordfile, encoding="utf-8"):
        w = l.strip().split("\t")[0].lower()
        if re.fullmatch(r"[a-z]{2,20}", w) and w not in words:
            words.append(w)
    if limit:
        words = words[:limit]
    res = {}
    for i in range(0, len(words), 400):
        chunk = words[i:i + 400]
        out = run(userdir, chunk)
        for w in chunk:
            res[w] = (out.get(f"{w}{{space}}"), out.get(f"{w}{{Shift_L}}{{Release+Shift_L}}"))
    c = collections.Counter()
    with open(outp, "w", encoding="utf-8") as fh:
        for rank, w in enumerate(words, 1):
            sp, sh = res[w]
            k = classify(w, sp, sh)
            c[k] += 1
            fh.write(f"{rank}\t{w}\t{k}\t{sp}\t{sh}\n")
    n = len(words)
    print(f"{wordfile}: {n} words  " + "  ".join(f"{k}={c[k]} ({100*c[k]/n:.1f}%)" for k in ("space", "shift", "broken")))


if __name__ == "__main__":
    main()
