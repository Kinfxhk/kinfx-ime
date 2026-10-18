"""Estimate: if Space commits English when the held run is an English word,
how often does that change Windows Quick output for pure-Chinese typing?

Model: Windows-optimal typing of sampled Cantonese text (essay-cantonese weights).
Each char is typed with its cheapest Windows Quick code: letters, Space per page,
digit when rank>1 or single-letter code. Held run = letters since last commit that
still form an English-word prefix (delayed top-out). A divergence = Space pressed
while the held run is a complete English word (hybrid would commit English).
"""
import json, os, random, sys
from collections import Counter
from wordfreq import top_n_list, zipf_frequency

R = 'C:/HermesHub/profiles/it-dog/projects/kinfx-ime/'
order = {}
for l in open(R + 'schemas/kinfx-quick/ms_quick_order.tsv', encoding='utf-8'):
    l = l.rstrip('\r\n')
    if l and not l.startswith('#'):
        c, v = l.split('\t', 1); order[c] = v.split(' ')
for l in open(R + 'schemas/kinfx-quick/win_quick_top9.tsv', encoding='utf-8'):
    l = l.rstrip('\r\n')
    if l and not l.startswith('#'):
        c, v = l.split('\t', 1)
        order.setdefault(c, list(v))

def cost(c, r):
    pages = (r - 1) // 9
    single = len(c) == 1
    return len(c) + pages + (1 if single else 0) + (1 if (r > 1 or single) else 0)

best = {}
for c, cs in order.items():
    for r, ch in enumerate(cs, 1):
        k = cost(c, r)
        if ch not in best or k < best[ch][2]:
            best[ch] = (c, r, k)

words, wts = [], []
for l in open(os.environ['APPDATA'] + '/Rime/essay-cantonese.txt', encoding='utf-8'):
    p = l.rstrip('\r\n').split('\t')
    if len(p) >= 2 and p[1].isdigit() and all(ch in best for ch in p[0]):
        words.append(p[0]); wts.append(int(p[1]))
random.seed(7)
import itertools
cum=list(itertools.accumulate(wts))
text = []
n = 0
while n < 500000:
    cl = ''.join(random.choices(words, cum_weights=cum, k=random.randint(2, 7)))
    text.append(cl + random.choice('，，，。、！？')); n += len(cl)
text = ''.join(text)
nchars = sum(ch in best for ch in text)

# Event stream: per char, ('code', c, r, ch) or ('punct',)
PUN=set('，。、！？')
def events():
    for ch in text:
        if ch in best and ch not in PUN:
            c, r, _ = best[ch]
            yield c, r, ch
        else:
            yield None, None, ch

paging = Counter()  # code -> Space presses (any Space) in Windows typing
for c, r, ch in events():
    if c is None: continue
    sp = (r - 1) // 9 + (1 if len(c) == 1 else 0)
    if sp: paging[c] += sp

out = {'chars': nchars, 'space_presses_total': sum(paging.values()),
       'chars_needing_space': None}
out['chars_needing_space'] = sum(1 for c, r, ch in events() if c and ((r - 1) // 9 or len(c) == 1))

def simulate(eng):
    pref = {w[:i] for w in eng for i in range(1, len(w) + 1)}
    div = Counter(); held_tail = 0; global pdiv; pdiv = Counter()
    run = ''; dead = False
    for c, r, ch in events():
        if c is None:
            if not dead and run in eng: pdiv[run] += 1
            run = ''; dead = False; continue
        typed = ''
        for x in c:
            typed += x
            if not dead and (run + x) in pref:
                run += x
            else:
                # top-out of earlier codes; restart at the current code start
                run = typed if typed in pref else ''
                dead = run == ''
        spaces = (r - 1) // 9 + (1 if len(c) == 1 else 0)
        if spaces:
            if not dead and run in eng:
                div[run] += 1
            run = ''; dead = False  # Space pages, then digit commits
            continue
        if r > 1:
            run = ''; dead = False  # digit commits
            continue
        # rank-1 two-letter: stays held; next key tops it out
        if dead:
            run = ''; dead = False
    return div

res = {}
WL={'is','it','we','an','as','us','at','by','up','am','in','go','so','a'}
r1=sum(1 for c,r,ch in events() if c and len(c)==2 and r==1); out['rank1_2letter']=r1
for N in (3000, 20000):
    pass
for N in (20000,):
    raw = [w for w in top_n_list('en', N) if w.isascii() and w.isalpha()]
    for label, eng in (('ge3', {w for w in raw if len(w) >= 3}), ('ge5', {w for w in raw if len(w) >= 5})):
        div = simulate(eng)
        tot = sum(div.values())
        res[f'{N}_{label}_punct'] = {'n': sum(pdiv.values()), 'top': pdiv.most_common(12)}
        res[f'{N}_{label}'] = {'words': len(eng), 'divergences': tot,
                               'per_10k_chars': round(tot / nchars * 1e4, 2),
                               'top': div.most_common(15)}
out['res'] = res
short = ['is', 'am', 'of', 'on', 'in', 'it', 'to', 'be', 'do', 'go', 'so', 'no',
         'we', 'me', 'he', 'my', 'up', 'an', 'as', 'at', 'by', 'or', 'if', 'us', 'ok', 'hi', 'a', 'i']
out['short'] = {w: {'code': w in order, 'first3': ''.join(order.get(w, [])[:3]),
                    'ncand': len(order.get(w, [])), 'win_space_presses': paging.get(w, 0),
                    'zipf_en': zipf_frequency(w, 'en')} for w in short}
json.dump(out, open(sys.argv[1], 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('ok', nchars)
