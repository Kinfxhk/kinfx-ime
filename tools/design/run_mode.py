"""Analytic collision rate per English word for "Space commits held English".

A collision for word w = Windows-optimal typing of some Chinese text produces the
held letter run w and then Space (Space needed to page or to list a 1-letter code).
For len(w) <= 4 the only shapes are:
  - w itself is a code whose wanted char needs Space          (1 char)
  - w = c1 + c2, c1 a 2-letter code typed for a rank-1 char,
    c2 the code of the next char that needs Space              (2 chars)
Rates use char unigram/bigram weights from essay-cantonese (within-word bigrams
plus cross-word pairs from end/start distributions). Output: expected collisions
per 10k Chinese chars for every top-N English word of length 1-4.
"""
import json, os, sys
from collections import Counter, defaultdict
from wordfreq import top_n_list

R = 'C:/Users/kinfx/kinfx-ime/'
order = {}
for l in open(R + 'schemas/kinfx-quick/ms_quick_order.tsv', encoding='utf-8'):
    l = l.rstrip('\r\n')
    if l and not l.startswith('#'):
        c, v = l.split('\t', 1); order[c] = v.split(' ')
for l in open(R + 'schemas/kinfx-quick/win_quick_top9.tsv', encoding='utf-8'):
    l = l.rstrip('\r\n')
    if l and not l.startswith('#'):
        c, v = l.split('\t', 1); order.setdefault(c, list(v))

def cost(c, r):
    return len(c) + (r - 1) // 9 + (len(c) == 1) + (r > 1 or len(c) == 1)
best = {}
for c, cs in order.items():
    for r, ch in enumerate(cs, 1):
        k = cost(c, r)
        if ch not in best or k < best[ch][2]:
            best[ch] = (c, r, k)
needs_space = {ch for ch, (c, r, _) in best.items() if len(c) == 1 or r > 9}
rank1 = {ch for ch, (c, r, _) in best.items() if len(c) == 2 and r == 1}

uni = Counter(); bi = Counter(); start = Counter(); end = Counter(); tot_w = 0
for l in open(os.environ['APPDATA'] + '/Rime/essay-cantonese.txt', encoding='utf-8'):
    p = l.rstrip('\r\n').split('\t')
    if len(p) < 2 or not p[1].isdigit(): continue
    w, f = p[0], int(p[1])
    if not all(ch in best for ch in w): continue
    tot_w += f
    for ch in w: uni[ch] += f
    for a, b in zip(w, w[1:]): bi[(a, b)] += f
    start[w[0]] += f; end[w[-1]] += f
U = sum(uni.values())
S = sum(start.values())
# per-char-position probabilities
p_uni = {ch: n / U for ch, n in uni.items()}
# P(pair at a random position) = within-word bigrams + cross-word boundary pairs
n_bound = tot_w  # one boundary per word
p_bi = defaultdict(float)
for (a, b), n in bi.items(): p_bi[(a, b)] += n / U
for a, na in end.items():
    for b in needs_space:
        nb = start.get(b, 0)
        if nb: p_bi[(a, b)] += (na / U) * (nb / S)

by_code_space = defaultdict(list)  # code -> chars needing Space whose best code is it
for ch in needs_space: by_code_space[best[ch][0]].append(ch)
rank1_by_code = {}
for ch in rank1: rank1_by_code[best[ch][0]] = ch

def rate(w):
    r = 0.0
    if w in by_code_space:
        r += sum(p_uni.get(ch, 0) for ch in by_code_space[w])
    for i in (2,):
        c1, c2 = w[:i], w[i:]
        if len(c2) in (1, 2) and c1 in rank1_by_code and c2 in by_code_space:
            a = rank1_by_code[c1]
            r += sum(p_bi.get((a, b), 0) for b in by_code_space[c2])
    return r * 1e4


from wordfreq import top_n_list
eng=[w for w in top_n_list('en',20000) if w.isascii() and w.isalpha() and len(w)<=4]
rates=json.load(open('rates.json'))
safe={w for w in eng if rates.get(w,1)<=0.01}
unsafe=[w for w in eng if w not in safe]
# P(collision per English->Chinese transition) in "English run" mode
def p_start(w):
    r=0.0
    for ch in by_code_space.get(w,[]): r+=start.get(ch,0)/S
    c1,c2=w[:2],w[2:]
    if c2 and c1 in rank1_by_code and c2 in by_code_space:
        a=rank1_by_code[c1]
        if start.get(a):
            # P(first=a) * P(next=b | a) approx via within-word bigram share
            pa=start[a]/S; na=sum(n for (x,y),n in bi.items() if x==a) or 1
            r+=pa*sum(bi.get((a,b),0) for b in by_code_space[c2])/na
    return r
rows=sorted(((p_start(w),w) for w in unsafe), reverse=True)
print('total per transition', round(sum(p for p,_ in rows)*100,3),'%')
print([ (w,round(p*100,3)) for p,w in rows[:15]])
blk={w for p,w in rows if p>0.0005}
print('block',len(blk),'remaining', round(sum(p for p,w in rows if w not in blk)*100,3),'%', sorted(blk))
