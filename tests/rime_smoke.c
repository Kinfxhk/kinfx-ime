/* Headless librime smoke: Sucheng + zero-switch mixed + optional Jyutping tones. */
#include <rime_api.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int g_deploy_ok = 0;

static void on_notify(void* ctx, RimeSessionId sid, const char* type,
                      const char* value) {
  (void)ctx;
  (void)sid;
  if (type && value && strcmp(type, "deploy") == 0) {
    fprintf(stderr, "[deploy] %s\n", value);
    if (strcmp(value, "success") == 0) g_deploy_ok = 1;
    if (strcmp(value, "failure") == 0) g_deploy_ok = -1;
  }
}

static int menu_has(RimeContext* ctx, const char* needle) {
  if (!ctx || !ctx->menu.candidates) return 0;
  for (int i = 0; i < ctx->menu.num_candidates; ++i) {
    const char* t = ctx->menu.candidates[i].text;
    if (t && strstr(t, needle)) return 1;
  }
  return 0;
}

static int menu_rank(RimeContext* ctx, const char* needle) {
  if (!ctx || !ctx->menu.candidates) return -1;
  for (int i = 0; i < ctx->menu.num_candidates; ++i) {
    const char* t = ctx->menu.candidates[i].text;
    if (t && strcmp(t, needle) == 0) return i + 1;
  }
  return -1;
}

static void print_menu(RimeContext* ctx) {
  printf("  preedit=%s num=%d page=%d\n",
         ctx->composition.preedit ? ctx->composition.preedit : "",
         ctx->menu.num_candidates, ctx->menu.page_no);
  for (int i = 0; i < ctx->menu.num_candidates && i < 12; ++i) {
    printf("  [%d] %s%s%s\n", i + 1,
           ctx->menu.candidates[i].text ? ctx->menu.candidates[i].text : "",
           ctx->menu.candidates[i].comment ? "  " : "",
           ctx->menu.candidates[i].comment ? ctx->menu.candidates[i].comment
                                           : "");
  }
}

static int try_code(RimeApi* api, RimeSessionId sid, const char* seq,
                    const char* expect) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) {
    fprintf(stderr, "simulate_key_sequence failed for %s\n", seq);
    return 0;
  }
  int ok = 0;
  printf("code '%s' expect '%s':\n", seq, expect);
  for (int page = 0; page < 30; ++page) {
    RIME_STRUCT(RimeContext, ctx);
    if (!api->get_context(sid, &ctx)) {
      fprintf(stderr, "get_context failed\n");
      return 0;
    }
    print_menu(&ctx);
    if (menu_has(&ctx, expect)) ok = 1;
    int last = ctx.menu.is_last_page;
    api->free_context(&ctx);
    if (ok || last) break;
    api->process_key(sid, 0xff56, 0);
  }
  api->clear_composition(sid);
  return ok;
}

static int rank_first_page(RimeApi* api, RimeSessionId sid, const char* seq,
                           const char* expect, int max_rank) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) return 0;
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return 0;
  int r = menu_rank(&ctx, expect);
  printf("rank '%s'→'%s' = %d (want ≤%d) page_size=%d num=%d\n", seq, expect, r,
         max_rank, ctx.menu.page_size, ctx.menu.num_candidates);
  print_menu(&ctx);
  api->free_context(&ctx);
  api->clear_composition(sid);
  return r > 0 && r <= max_rank;
}

/* Exact Windows slot, not a "at most N" frequency ceiling. */
static int rank_exact(RimeApi* api, RimeSessionId sid, const char* seq,
                      const char* expect, int want) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) return 0;
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return 0;
  int r = menu_rank(&ctx, expect);
  printf("exact '%s'→'%s' = %d (want %d) page_size=%d\n", seq, expect, r, want,
         ctx.menu.page_size);
  int ok = r == want && ctx.menu.page_size == 9;
  api->free_context(&ctx);
  api->clear_composition(sid);
  return ok;
}

/* First-page texts must equal the Windows top-9 list (shorter lists fill the page). */
static int assert_win_prefix(RimeApi* api, RimeSessionId sid, const char* seq,
                             const char* const* expect, int n) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) return 0;
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return 0;
  int ok = ctx.menu.page_size == 9 && ctx.menu.num_candidates >= n;
  printf("win '%s' page_size=%d num=%d\n", seq, ctx.menu.page_size,
         ctx.menu.num_candidates);
  for (int i = 0; i < n; ++i) {
    const char* got = "";
    if (i < ctx.menu.num_candidates && ctx.menu.candidates[i].text)
      got = ctx.menu.candidates[i].text;
    if (strcmp(got, expect[i]) != 0) {
      printf("  [%d] got '%s' want '%s'\n", i + 1, got, expect[i]);
      ok = 0;
    }
  }
  if (ok) {
    printf("  ");
    for (int i = 0; i < n; ++i) printf("%s", expect[i]);
    printf("\n");
  }
  api->free_context(&ctx);
  api->clear_composition(sid);
  return ok;
}

/* Product default: 9 candidates, select keys 1–9. A full page must be 9. */
static int assert_page_size(RimeApi* api, RimeSessionId sid, const char* seq,
                            int want) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) return 0;
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return 0;
  int ps = ctx.menu.page_size;
  int n = ctx.menu.num_candidates;
  const char* keys = ctx.menu.select_keys ? ctx.menu.select_keys : "";
  printf("page '%s' page_size=%d num=%d select_keys='%s' (want %d)\n", seq, ps,
         n, keys, want);
  int ok = ps == want && n == want;
  api->free_context(&ctx);
  api->clear_composition(sid);
  return ok;
}

/* Digit 1 selects rank 1 (page_size 9 → keys 1–9). */
static int assert_select_key_1(RimeApi* api, RimeSessionId sid, const char* seq,
                               const char* expect) {
  api->clear_composition(sid);
  char keys[16];
  snprintf(keys, sizeof(keys), "%s1", seq);
  if (!api->simulate_key_sequence(sid, keys)) return 0;
  RIME_STRUCT(RimeCommit, c);
  const char* got = NULL;
  if (api->get_commit(sid, &c)) got = c.text;
  printf("select1 '%s' commit=%s expect=%s\n", keys, got ? got : "", expect);
  int ok = got && strstr(got, expect);
  if (got) api->free_commit(&c);
  api->clear_composition(sid);
  return ok;
}

static int assert_absent(RimeApi* api, RimeSessionId sid, const char* seq,
                         const char* bad) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) return 0;
  int found = 0;
  for (int page = 0; page < 20; ++page) {
    RIME_STRUCT(RimeContext, ctx);
    if (!api->get_context(sid, &ctx)) break;
    if (menu_has(&ctx, bad)) found = 1;
    int last = ctx.menu.is_last_page;
    api->free_context(&ctx);
    if (found || last) break;
    api->process_key(sid, 0xff56, 0);
  }
  api->clear_composition(sid);
  printf("absent '%s' in '%s': %s\n", bad, seq, found ? "FAIL" : "PASS");
  return !found;
}

/* Zero-switch mixed: Chinese + uppercase Latin, ascii_mode stays 0. */
static int try_mixed_zero_switch(RimeApi* api, RimeSessionId sid) {
  api->clear_composition(sid);
  api->set_option(sid, "ascii_mode", False);
  /* vd + API → preedit 好API → space commits */
  api->simulate_key_sequence(sid, "vdAPI ");
  RIME_STRUCT(RimeCommit, c);
  const char* got = NULL;
  if (api->get_commit(sid, &c)) {
    got = c.text;
    printf("mixed commit=%s\n", got ? got : "");
  }
  int ok_commit = got && strstr(got, "好") && strstr(got, "API");
  if (got) api->free_commit(&c);

  RIME_STRUCT(RimeStatus, st);
  int ascii = 1;
  if (api->get_status(sid, &st)) {
    ascii = st.is_ascii_mode;
    api->free_status(&st);
  }
  printf("mixed ascii_mode=%d (want 0)\n", ascii);

  /* continuous: 好 + API + 好 */
  api->simulate_key_sequence(sid, "vd{Return}");
  if (api->get_commit(sid, &c)) api->free_commit(&c);
  api->simulate_key_sequence(sid, "API ");
  if (api->get_commit(sid, &c)) {
    printf("mixed2 API commit=%s\n", c.text ? c.text : "");
    ok_commit = ok_commit && c.text && strstr(c.text, "API");
    api->free_commit(&c);
  }
  api->simulate_key_sequence(sid, "vd ");
  if (api->get_commit(sid, &c)) {
    printf("mixed3 好 commit=%s\n", c.text ? c.text : "");
    api->free_commit(&c);
  }
  if (api->get_status(sid, &st)) {
    ascii = st.is_ascii_mode;
    api->free_status(&st);
  }
  printf("mixed final ascii_mode=%d\n", ascii);

  /* Enter on a menu-less mixed preedit also confirms, not raw vdAPI. */
  api->clear_composition(sid);
  api->simulate_key_sequence(sid, "vdAPI{Return}");
  if (api->get_commit(sid, &c)) {
    printf("mixed enter commit=%s\n", c.text ? c.text : "");
    ok_commit = ok_commit && c.text && strstr(c.text, "好") && strstr(c.text, "API");
    int raw = c.text && strcmp(c.text, "vdAPI") == 0;
    if (raw) ok_commit = 0;
    api->free_commit(&c);
  } else {
    printf("mixed enter commit=(none)\n");
    ok_commit = 0;
  }
  if (api->get_status(sid, &st)) {
    ascii = st.is_ascii_mode;
    api->free_status(&st);
  }
  return ok_commit && ascii == 0;
}

/* Windows Quick select keys. Space pages only while a menu is up. */
enum {
  XK_SPACE = 0x20,
  XK_TAB = 0xff09,
  XK_RETURN = 0xff0d,
  XK_LEFT = 0xff51,
  XK_RIGHT = 0xff53
};

typedef struct {
  char text[128];
  char comment[512];
  char preedit[512];
  int page_no;
  int page_size;
  int num;
  int last;
  int composing;
  int hot;
  int grid;
} Snap;

static void drain_commit(RimeApi* api, RimeSessionId sid) {
  RIME_STRUCT(RimeCommit, c);
  if (api->get_commit(sid, &c)) api->free_commit(&c);
}

static int take_commit(RimeApi* api, RimeSessionId sid, char* buf, size_t n) {
  buf[0] = 0;
  RIME_STRUCT(RimeCommit, c);
  if (!api->get_commit(sid, &c)) return 0;
  if (c.text) snprintf(buf, n, "%s", c.text);
  api->free_commit(&c);
  return buf[0] != 0;
}

static int snap_menu(RimeApi* api, RimeSessionId sid, Snap* s) {
  memset(s, 0, sizeof(*s));
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return 0;
  s->page_no = ctx.menu.page_no;
  s->page_size = ctx.menu.page_size;
  s->num = ctx.menu.num_candidates;
  s->last = ctx.menu.is_last_page;
  if (ctx.composition.preedit)
    snprintf(s->preedit, sizeof s->preedit, "%s", ctx.composition.preedit);
  if (s->num > 0 && ctx.menu.candidates[0].text)
    snprintf(s->text, sizeof s->text, "%s", ctx.menu.candidates[0].text);
  if (s->num > 0 && ctx.menu.candidates[0].comment)
    snprintf(s->comment, sizeof s->comment, "%s", ctx.menu.candidates[0].comment);
  for (int i = 0; i < ctx.menu.num_candidates; ++i) {
    const char* c = ctx.menu.candidates[i].comment;
    if (c && strstr(c, "♥")) s->hot = 1;
    if (c && strstr(c, "【")) s->grid = 1;
  }
  if (strstr(s->preedit, "常用") || strstr(s->preedit, "♥")) s->hot = 1;
  if (strstr(s->preedit, "展開")) s->grid = 1;
  api->free_context(&ctx);
  RIME_STRUCT(RimeStatus, st);
  if (api->get_status(sid, &st)) {
    s->composing = st.is_composing;
    api->free_status(&st);
  }
  return 1;
}

/* vd + Space does not commit 好; Space then Enter commits page-2 first. */
static int assert_space_enter(RimeApi* api, RimeSessionId sid) {
  char commit[128];
  Snap a, b;
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "vd")) return 0;
  if (!snap_menu(api, sid, &a)) return 0;
  api->process_key(sid, XK_SPACE, 0);
  int committed = take_commit(api, sid, commit, sizeof commit);
  if (!snap_menu(api, sid, &b)) return 0;
  printf("space-page '%s'→'%s' page %d→%d commit='%s' composing=%d\n", a.text,
         b.text, a.page_no, b.page_no, committed ? commit : "", b.composing);
  int ok = !committed && b.composing && strcmp(a.text, "好") == 0 &&
           strcmp(a.text, b.text) != 0 && b.page_no == a.page_no + 1 &&
           b.page_size == 9;
  api->process_key(sid, XK_RETURN, 0);
  committed = take_commit(api, sid, commit, sizeof commit);
  printf("space-then-enter commit='%s' want='%s'\n", committed ? commit : "",
         b.text);
  ok = ok && committed && strcmp(commit, b.text) == 0 &&
       strcmp(commit, "vd") != 0 && strcmp(commit, "好") != 0;
  api->clear_composition(sid);
  drain_commit(api, sid);

  if (!api->simulate_key_sequence(sid, "vd")) return 0;
  api->process_key(sid, XK_RETURN, 0);
  committed = take_commit(api, sid, commit, sizeof commit);
  printf("enter-focus commit='%s' want=好\n", committed ? commit : "");
  ok = ok && committed && strcmp(commit, "好") == 0;
  api->clear_composition(sid);
  return ok;
}

/* Multi-page code: Left from page 1 opens the 9-slot hot page; next wraps home. */
static int assert_hot_cycle(RimeApi* api, RimeSessionId sid) {
  Snap a, b, c;
  char commit[128];
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "of")) return 0;
  if (!snap_menu(api, sid, &a)) return 0;
  api->process_key(sid, XK_LEFT, 0);
  take_commit(api, sid, commit, sizeof commit);
  if (!snap_menu(api, sid, &b)) return 0;
  printf("hot-left page1 '%s' → hot num=%d ps=%d hot=%d preedit=%s comment=%s\n",
         a.text, b.num, b.page_size, b.hot, b.preedit, b.comment);
  /* Page 1 stays the Windows glyph (伙). Left only opens the hot wrap. */
  int ok = commit[0] == 0 && b.composing && b.hot && b.num == 9 &&
           b.page_size == 9 && b.page_size == a.page_size &&
           strcmp(a.text, "伙") == 0;
  api->process_key(sid, XK_SPACE, 0);
  if (!snap_menu(api, sid, &c)) return 0;
  printf("hot-next '%s' hot=%d (want page1 '%s')\n", c.text, c.hot, a.text);
  ok = ok && strcmp(c.text, a.text) == 0 && !c.hot && c.page_no == 0;

  /* Forward wrap: last normal page + Space lands on the hot page, then page 1. */
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "of")) return 0;
  int saw_hot = 0;
  for (int i = 0; i < 40; ++i) {
    api->process_key(sid, XK_SPACE, 0);
    if (!snap_menu(api, sid, &b)) return 0;
    if (b.hot) {
      saw_hot = 1;
      break;
    }
    if (!b.composing) break;
  }
  printf("hot-forward reached=%d num=%d text=%s\n", saw_hot, b.num, b.text);
  ok = ok && saw_hot && b.num == 9;
  api->process_key(sid, XK_SPACE, 0);
  if (!snap_menu(api, sid, &c)) return 0;
  printf("hot-forward-next '%s' hot=%d page=%d\n", c.text, c.hot, c.page_no);
  ok = ok && strcmp(c.text, a.text) == 0 && !c.hot && c.page_no == 0;
  api->clear_composition(sid);
  return ok;
}

static int assert_tab_expand(RimeApi* api, RimeSessionId sid) {
  Snap a, b;
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "of")) return 0;
  api->process_key(sid, XK_TAB, 0);
  int on = api->get_option(sid, "win_quick_expand");
  if (!snap_menu(api, sid, &a)) return 0;
  printf("tab-expand on=%d ps=%d num=%d grid=%d text=%s comment=%s\n", on,
         a.page_size, a.num, a.grid, a.text, a.comment);
  int ok = on && a.page_size == 9 && a.num == 9 && a.grid && a.composing;
  api->process_key(sid, XK_RIGHT, 0);
  if (!snap_menu(api, sid, &b)) return 0;
  printf("tab-right '%s'→'%s' grid=%d ps=%d page=%d\n", a.text, b.text, b.grid,
         b.page_size, b.page_no);
  ok = ok && b.grid && b.page_size == 9 && strcmp(a.text, b.text) != 0 &&
       b.page_no == 1;
  api->process_key(sid, XK_TAB, 0);
  int off = api->get_option(sid, "win_quick_expand");
  printf("tab-off option=%d (want 0)\n", off);
  ok = ok && !off;
  /* v0.5.2: Esc ends the expand; no 〔展開〕 text in the preedit. */
  api->clear_composition(sid);
  api->simulate_key_sequence(sid, "of");
  api->process_key(sid, XK_TAB, 0);
  Snap c;
  if (!snap_menu(api, sid, &c)) return 0;
  int clean = strstr(c.preedit, "\xe5\xb1\x95\xe9\x96\x8b") == NULL; /* 展開 */
  api->process_key(sid, 0xff1b, 0); /* Escape */
  int after_esc = api->get_option(sid, "win_quick_expand");
  printf("tab-esc preedit-clean=%d option-after-esc=%d (want 1, 0)\n", clean, after_esc);
  ok = ok && clean && !after_esc;
  api->clear_composition(sid);
  return ok;
}

/* A one-page code must not grow a hot page, and Space must not commit it. */
static int assert_single_page_space(RimeApi* api, RimeSessionId sid) {
  const char* codes[] = {"ix", "kx", NULL};
  for (int i = 0; codes[i]; ++i) {
    Snap a, b;
    char commit[128];
    api->clear_composition(sid);
    drain_commit(api, sid);
    if (!api->simulate_key_sequence(sid, codes[i])) continue;
    if (!snap_menu(api, sid, &a)) continue;
    printf("single? %s num=%d last=%d text=%s\n", codes[i], a.num, a.last,
           a.text);
    if (a.num < 1 || !a.last || a.page_no != 0) continue;
    api->process_key(sid, XK_LEFT, 0);
    int committed = take_commit(api, sid, commit, sizeof commit);
    if (!snap_menu(api, sid, &b)) return 0;
    int ok = !committed && !b.hot && strcmp(a.text, b.text) == 0;
    api->process_key(sid, XK_SPACE, 0);
    committed = take_commit(api, sid, commit, sizeof commit);
    Snap c;
    if (!snap_menu(api, sid, &c)) return 0;
    printf("single-space %s commit='%s' text '%s'→'%s' hot=%d\n", codes[i],
           committed ? commit : "", a.text, c.text, c.hot);
    ok = ok && !committed && !c.hot && strcmp(a.text, c.text) == 0 &&
         c.composing;
    api->clear_composition(sid);
    return ok;
  }
  printf("single-page code not found\n");
  return 0;
}

/* History is preferred on the hot page (9 slots, ♥常 first). */
static int assert_hot_history(RimeApi* api, RimeSessionId sid) {
  Snap page2, hot;
  char commit[128];
  char want[128];
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "of")) return 0;
  api->process_key(sid, XK_SPACE, 0);
  if (!snap_menu(api, sid, &page2)) return 0;
  snprintf(want, sizeof want, "%s", page2.text);
  api->process_key(sid, '1', 0);
  take_commit(api, sid, commit, sizeof commit);
  printf("hist-pick commit='%s' want='%s'\n", commit, want);
  if (strcmp(commit, want) != 0) {
    api->clear_composition(sid);
    return 0;
  }
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "of")) return 0;
  api->process_key(sid, XK_LEFT, 0);
  if (!snap_menu(api, sid, &hot)) return 0;
  printf("hist-hot first='%s' comment='%s' num=%d (want %s ♥常)\n", hot.text,
         hot.comment, hot.num, want);
  int ok = hot.num == 9 && hot.hot && strcmp(hot.text, want) == 0 &&
           strstr(hot.comment, "常") != NULL;
  api->clear_composition(sid);
  return ok;
}

/* Rank on the first page. -1 if missing or if page_size drifted from 9. */
static int first_page_rank(RimeApi* api, RimeSessionId sid, const char* seq,
                           const char* expect) {
  api->clear_composition(sid);
  if (!api->simulate_key_sequence(sid, seq)) return -1;
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return -1;
  int r = menu_rank(&ctx, expect);
  int ps = ctx.menu.page_size;
  printf("mix '%s'→'%s' rank=%d page_size=%d num=%d\n", seq, expect, r, ps,
         ctx.menu.num_candidates);
  print_menu(&ctx);
  api->free_context(&ctx);
  api->clear_composition(sid);
  if (ps != 9) return -1;
  return r;
}

/* Digit select commits the phrase/English text, not the raw code. */
static int commit_at_rank(RimeApi* api, RimeSessionId sid, const char* seq,
                          int rank, const char* expect) {
  if (rank < 1 || rank > 9) return 0;
  api->clear_composition(sid);
  drain_commit(api, sid);
  char keys[32];
  snprintf(keys, sizeof keys, "%s%d", seq, rank);
  if (!api->simulate_key_sequence(sid, keys)) return 0;
  char commit[128];
  int committed = take_commit(api, sid, commit, sizeof commit);
  printf("mix-commit '%s' → '%s' want '%s'\n", keys, committed ? commit : "",
         expect);
  int ok = committed && strcmp(commit, expect) == 0 && strcmp(commit, seq) != 0;
  api->clear_composition(sid);
  drain_commit(api, sid);
  return ok;
}

/* v0.5 English smart mode: Space commits a space-safe word. */
static int commit_space(RimeApi* api, RimeSessionId sid, const char* seq,
                        const char* expect) {
  api->clear_composition(sid);
  drain_commit(api, sid);
  char keys[64];
  snprintf(keys, sizeof keys, "%s ", seq);
  if (!api->simulate_key_sequence(sid, keys)) return 0;
  char commit[128];
  int committed = take_commit(api, sid, commit, sizeof commit);
  printf("space '%s ' → '%s' want '%s'\n", seq, committed ? commit : "", expect);
  int ok = committed && strcmp(commit, expect) == 0;
  api->clear_composition(sid);
  drain_commit(api, sid);
  return ok;
}

/* v0.5 English smart mode: Left Shift tap commits the raw letters. */
static int commit_shift_tap(RimeApi* api, RimeSessionId sid, const char* seq,
                            const char* expect) {
  api->clear_composition(sid);
  drain_commit(api, sid);
  char keys[64];
  snprintf(keys, sizeof keys, "%s{Shift_L}{Release+Shift_L}", seq);
  if (!api->simulate_key_sequence(sid, keys)) return 0;
  char commit[128];
  int committed = take_commit(api, sid, commit, sizeof commit);
  printf("shift-tap '%s' → '%s' want '%s'\n", seq, committed ? commit : "", expect);
  int ok = committed && strcmp(commit, expect) == 0;
  api->clear_composition(sid);
  drain_commit(api, sid);
  return ok;
}

/* A third letter that does not start a common phrase 頂字 like Windows. */
static int assert_top_keeps_char(RimeApi* api, RimeSessionId sid) {
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "vdz")) return 0;
  RIME_STRUCT(RimeContext, ctx);
  if (!api->get_context(sid, &ctx)) return 0;
  const char* pre = ctx.composition.preedit ? ctx.composition.preedit : "";
  const char* first = "";
  if (ctx.menu.num_candidates > 0 && ctx.menu.candidates[0].text)
    first = ctx.menu.candidates[0].text;
  printf("topchar vdz preedit=%s first=%s num=%d\n", pre, first,
         ctx.menu.num_candidates);
  int page_ok = ctx.menu.page_size == 9;
  api->free_context(&ctx);
  /* 頂字 commits 好 before the remainder menu; preedit is then only z. */
  char commit[128];
  int committed = take_commit(api, sid, commit, sizeof commit);
  printf("topchar vdz commit='%s'\n", committed ? commit : "");
  int ok = page_ok && committed && strstr(commit, "好") != NULL;
  api->clear_composition(sid);
  drain_commit(api, sid);
  return ok;
}

/* ofc/ofca phrases, gmai plus long-prefix extras, and short-code Chinese priority. */
static int assert_phrase_mix(RimeApi* api, RimeSessionId sid) {
  int ok_top = assert_top_keeps_char(api, sid);
  int r_ofc = first_page_rank(api, sid, "ofc", "無錯");
  int r_ofca = first_page_rank(api, sid, "ofca", "無錯");
  /* ofca is the full code of 無錯 and stays held (kinfx_capture.txt). */
  int ok = r_ofc > 0 && r_ofc <= 9 && r_ofca > 0 && r_ofca <= r_ofc;
  ok = ok && commit_at_rank(api, sid, "ofc", r_ofc, "無錯");
  ok = ok && commit_at_rank(api, sid, "ofca", r_ofca, "無錯");
  /* 3-letter phrases (1-letter + 2-letter char) and a held 4th key. */
  ok = ok && commit_at_rank(api, sid, "ofc", 1, "人類");
  ok = ok && commit_at_rank(api, sid, "lwm", 1, "中國");
  ok = ok && commit_at_rank(api, sid, "ofch", 1, "無錫");
  /* Windows top-out text comes first when it is itself a word. */
  ok = ok && commit_at_rank(api, sid, "vdvd", 1, "好好");
  /* Windows slots 8-9 on vd are 綑綵 (measured; not 網綜). */
  ok = ok && commit_at_rank(api, sid, "vd", 8, "綑");
  ok = ok && commit_at_rank(api, sid, "vd", 9, "綵");

  /* Short codes: English must not appear. 係 is Windows slot 3, not rank 1. */
  ok = ok && assert_absent(api, sid, "me", "me");
  ok = ok && assert_absent(api, sid, "or", "or");
  ok = ok && assert_absent(api, sid, "of", "of");
  ok = ok && assert_absent(api, sid, "of", "offer");
  ok = ok && assert_absent(api, sid, "me", "Gmail");
  ok = ok && rank_exact(api, sid, "of", "伙", 1);
  ok = ok && rank_exact(api, sid, "of", "係", 3);
  printf("phrase-mix ofc:%d ofca:%d top:%d\n", r_ofc, r_ofca, ok_top);
  return ok && ok_top;
}

/* v0.5 English smart mode: Space commits a safe word; Left Shift taps short words. */
static int assert_english_mix(RimeApi* api, RimeSessionId sid) {
  int ok = 1;
  ok = ok && commit_space(api, sid, "the", "the ");
  ok = ok && commit_space(api, sid, "hello", "hello ");
  ok = ok && commit_space(api, sid, "startup", "startup ");
  /* 2-letter word needs Left Shift (Space pages the Sucheng menu). */
  ok = ok && commit_shift_tap(api, sid, "of", "of");
  /* v0.5.1: a pending top-out (passion = 旨巨 + ion) must not let a Chinese
     phrase on the tail win over the whole English word. */
  ok = ok && commit_space(api, sid, "passion", "passion ");
  /* v0.5.2: names list + unknown long words (company / product names). */
  ok = ok && commit_space(api, sid, "wondershare", "Wondershare ");
  ok = ok && commit_space(api, sid, "wonderxyz", "wonderxyz ");
  /* v0.5.3: unknown-word Space must not skip the names list (gmail -> Gmail),
     a Shift used for a symbol is not a commit tap, hyphen joins English words. */
  ok = ok && commit_space(api, sid, "gmail", "Gmail ");
  ok = ok && commit_space(api, sid, "const", "const ");
  ok = ok && commit_space(api, sid, "tool{minus}calling", "tool-calling ");
  ok = ok && commit_space(api, sid,
      "https{Shift_L}{Shift+colon}{Shift+Release+Shift_L}//x.com", "https://x.com ");
  printf("english-mix space/shift:%s\n", ok ? "PASS" : "FAIL");
  return ok;
}

/* v0.5 association: a one-char pick opens follow-up words; Shift+digit picks. */
static int assert_association(RimeApi* api, RimeSessionId sid) {
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "hi7{Shift+exclam}")) return 0;
  char commit[128];
  int committed = take_commit(api, sid, commit, sizeof commit);
  printf("assoc 'hi7{Shift+exclam}' → '%s' (want 我 + suffix)\n",
         committed ? commit : "");
  int ok = committed && strstr(commit, "我") != NULL && strcmp(commit, "我") != 0;
  api->clear_composition(sid);
  drain_commit(api, sid);
  /* v0.5.1: punctuation and Space after a pick close the list and type
     (period was swallowed as Page_Down by key_binder). Collect every commit. */
  const struct { const char* keys; const char* want; } after[] = {
    {"vd1.", "好。"}, {"hi7,", "我，"}, {"vd1 ", "好 "}, {"vd1/", "好/"},
    {"/", "/"}, {NULL, NULL}};
  for (int i = 0; after[i].keys; ++i) {
    char got[256] = {0};
    api->clear_composition(sid);
    drain_commit(api, sid);
    for (const char* k = after[i].keys; *k; ++k) {
      api->process_key(sid, (unsigned char)*k, 0);
      char part[128];
      if (take_commit(api, sid, part, sizeof part))
        strncat(got, part, sizeof got - strlen(got) - 1);
    }
    /* A passed-through space is typed by the app, not committed. */
    int want_space = after[i].keys[strlen(after[i].keys) - 1] == ' ';
    char want[64];
    snprintf(want, sizeof want, "%s", after[i].want);
    if (want_space) want[strlen(want) - 1] = 0;
    int good = strcmp(got, want) == 0;
    if (want_space) {
      RIME_STRUCT(RimeContext, cx);
      int composing = 0;
      if (api->get_context(sid, &cx)) {
        composing = cx.composition.length > 0 || cx.menu.num_candidates > 0;
        api->free_context(&cx);
      }
      good = good && !composing;
    }
    printf("assoc-after '%s' → '%s' (want '%s')%s\n", after[i].keys, got,
           after[i].want, good ? "" : " FAIL");
    ok = ok && good;
  }
  api->clear_composition(sid);
  drain_commit(api, sid);
  return ok;
}

static int try_jyutping_tone(RimeApi* api, RimeSessionId sid) {
  if (!api->select_schema(sid, "kinfx_jyutping")) {
    printf("jyutping: select_schema failed (skip)\n");
    return 1; /* optional if dict missing */
  }
  api->clear_composition(sid);
  /* tonal */
  int ok5 = try_code(api, sid, "nei5", "你");
  int ok6 = try_code(api, sid, "jyut6", "粵");
  /* toneless still ok */
  int ok0 = try_code(api, sid, "ngo", "我");
  int ok_page = assert_page_size(api, sid, "aa", 9);
  /* Same select contract: Space pages, Enter confirms the focus, not raw aa. */
  int ok_keys = 0;
  api->clear_composition(sid);
  if (api->simulate_key_sequence(sid, "aa")) {
    Snap a, b;
    char commit[128];
    if (snap_menu(api, sid, &a) && a.num > 0 && !a.last) {
      api->process_key(sid, XK_SPACE, 0);
      int committed = take_commit(api, sid, commit, sizeof commit);
      snap_menu(api, sid, &b);
      printf("jyut space '%s'→'%s' commit='%s' page %d→%d\n", a.text, b.text,
             committed ? commit : "", a.page_no, b.page_no);
      ok_keys = !committed && b.page_no == a.page_no + 1;
    }
    api->clear_composition(sid);
    if (api->simulate_key_sequence(sid, "aa")) {
      api->process_key(sid, XK_RETURN, 0);
      int committed = take_commit(api, sid, commit, sizeof commit);
      printf("jyut enter commit='%s'\n", committed ? commit : "");
      ok_keys = ok_keys && committed && strcmp(commit, "aa") != 0 &&
                a.num > 0 && strcmp(commit, a.text) == 0;
    }
  }
  api->select_schema(sid, "kinfx_quick");
  printf("jyutping tones nei5→你:%s jyut6→粵:%s ngo→我:%s page9:%s keys:%s\n",
         ok5 ? "PASS" : "FAIL", ok6 ? "PASS" : "FAIL", ok0 ? "PASS" : "FAIL",
         ok_page ? "PASS" : "FAIL", ok_keys ? "PASS" : "FAIL");
  return ok5 && ok6 && ok0 && ok_page && ok_keys;
}

/* v0.4: later pages follow the measured Windows list too, not frequency. */
static int assert_page2(RimeApi* api, RimeSessionId sid) {
  const char* vd2[] = {"嫻", "槳", "樂", "繅", "孿", "姀", "孥", "姝", "婐"};
  Snap a;
  api->clear_composition(sid);
  drain_commit(api, sid);
  if (!api->simulate_key_sequence(sid, "vd")) return 0;
  api->process_key(sid, XK_SPACE, 0);
  if (!snap_menu(api, sid, &a)) return 0;
  RIME_STRUCT(RimeContext, ctx);
  int ok = api->get_context(sid, &ctx) && ctx.menu.num_candidates == 9;
  for (int i = 0; ok && i < 9; ++i) {
    const char* got = ctx.menu.candidates[i].text;
    if (!got || strcmp(got, vd2[i]) != 0) {
      printf("  vd page2 [%d] got '%s' want '%s'\n", i + 1, got ? got : "", vd2[i]);
      ok = 0;
    }
  }
  if (ctx.menu.candidates) api->free_context(&ctx);
  printf("vd page2 windows order: %s\n", ok ? "PASS" : "FAIL");
  api->clear_composition(sid);
  return ok;
}

/* Continuous Sucheng tops out exactly like Windows: vd o f 3 → 好係. */
static int assert_windows_topout(RimeApi* api, RimeSessionId sid) {
  struct { const char* keys; const char* want; } cases[] = {
      {"vdof3", "好係"}, {"hiofrr1", "凡伙呂"}, {"hi7", "我"}, {"ofcx1", "伙鏽"},
  };
  int ok = 1;
  for (unsigned i = 0; i < sizeof cases / sizeof cases[0]; ++i) {
    char all[256] = {0};
    char part[128];
    api->clear_composition(sid);
    drain_commit(api, sid);
    for (const char* k = cases[i].keys; *k; ++k) {
      api->process_key(sid, (unsigned char)*k, 0);
      if (take_commit(api, sid, part, sizeof part))
        strncat(all, part, sizeof all - strlen(all) - 1);
    }
    int pass = strcmp(all, cases[i].want) == 0;
    printf("topout %s → '%s' want '%s' %s\n", cases[i].keys, all, cases[i].want,
           pass ? "PASS" : "FAIL");
    ok = ok && pass;
  }
  api->clear_composition(sid);
  return ok;
}

/* Documented Windows first page. an has 8 glyphs in the table; the code has no 9th. */
static int assert_win_table(RimeApi* api, RimeSessionId sid) {
  const char* vd[] = {"好", "她", "妹", "紆", "巢", "媒", "彙", "綑", "綵"};
  const char* hi[] = {"凡", "么", "丟", "夙", "舟", "卵", "我", "私", "的"};
  const char* me[] = {"汞", "歿", "泵", "玻", "夏", "破", "球", "豉", "瑕"};
  const char* orc[] = {"合", "何", "估", "佑", "伽", "伺", "佔", "佝", "含"};
  const char* ai[] = {"昤", "時", "閎", "閩", "閥", "曇", "旳", "昡", "戥"};
  const char* mk[] = {"天", "攻", "更", "玟", "玫", "政", "殃", "致", "敔"};
  const char* of[] = {"伙", "你", "係", "偽", "氮", "焦", "無", "絛", "僚"};
  const char* rr[] = {"呂", "呵", "咖", "咕", "品", "哈", "咯", "唁", "唔"};
  const char* yr[] = {"占", "吝", "言", "迦", "迢", "迥", "迨", "站", "迴"};
  const char* go[] = {"坎", "走", "垓", "堤", "款", "塚", "壕", "垗", "欯"};
  const char* an[] = {"門", "剔", "旯", "昑", "昲", "閌", "閅", "闁"};
  const char* ni[] = {"夕", "弘", "多", "兔", "弦", "虱", "附", "強", "蛋"};
  const char* wm[] = {"國", "置", "疊", "畇", "罡", "罝", "罭", "黚", "翾"};
  int ok = 1;
  ok = assert_win_prefix(api, sid, "vd", vd, 9) && ok;
  ok = assert_win_prefix(api, sid, "hi", hi, 9) && ok;
  ok = assert_win_prefix(api, sid, "me", me, 9) && ok;
  ok = assert_win_prefix(api, sid, "or", orc, 9) && ok;
  ok = assert_win_prefix(api, sid, "ai", ai, 9) && ok;
  ok = assert_win_prefix(api, sid, "mk", mk, 9) && ok;
  ok = assert_win_prefix(api, sid, "of", of, 9) && ok;
  ok = assert_win_prefix(api, sid, "rr", rr, 9) && ok;
  ok = assert_win_prefix(api, sid, "yr", yr, 9) && ok;
  ok = assert_win_prefix(api, sid, "go", go, 9) && ok;
  ok = assert_win_prefix(api, sid, "an", an, 8) && ok;
  ok = assert_win_prefix(api, sid, "ni", ni, 9) && ok;
  ok = assert_win_prefix(api, sid, "wm", wm, 9) && ok;
  /* 倉 is outside the Windows nine; it must not be lifted onto page 1. */
  ok = rank_exact(api, sid, "hi", "凡", 1) && ok;
  ok = rank_exact(api, sid, "hi", "我", 7) && ok;
  /* Single letter = Windows: no completion into hi, so h lists 竹丿 only. */
  ok = rank_exact(api, sid, "h", "竹", 1) && ok;
  {
    api->clear_composition(sid);
    api->simulate_key_sequence(sid, "h");
    RIME_STRUCT(RimeContext, ctx);
    int buried = 0;
    if (api->get_context(sid, &ctx)) {
      int mo = menu_rank(&ctx, "么");
      int wo = menu_rank(&ctx, "我");
      int diu = menu_rank(&ctx, "丟");
      printf("h page rare-pins 么=%d 我=%d 丟=%d (want absent)\n", mo, wo, diu);
      print_menu(&ctx);
      buried = mo > 0 || wo > 0 || diu > 0;
      api->free_context(&ctx);
    } else {
      buried = 1;
    }
    api->clear_composition(sid);
    ok = ok && !buried;
  }
  ok = rank_exact(api, sid, "rr", "呂", 1) && ok;
  ok = rank_exact(api, sid, "rr", "唔", 9) && ok;
  ok = rank_exact(api, sid, "me", "夏", 5) && ok;
  {
    api->clear_composition(sid);
    api->simulate_key_sequence(sid, "or");
    RIME_STRUCT(RimeContext, ctx);
    int on_page = 0;
    if (api->get_context(sid, &ctx)) {
      on_page = menu_rank(&ctx, "倉");
      printf("倉@or first-page rank=%d (want absent)\n", on_page);
      api->free_context(&ctx);
    }
    api->clear_composition(sid);
    ok = ok && on_page < 0;
  }
  return ok;
}

int main(int argc, char** argv) {
  const char* user_dir =
      argc > 1 ? argv[1] : "/tmp/kinfx-ime-smoke-user";
  const char* shared = "/usr/share/rime-data";

  RimeApi* api = rime_get_api();
  if (!api) {
    fprintf(stderr, "rime_get_api failed\n");
    return 2;
  }

  RIME_STRUCT(RimeTraits, traits);
  traits.shared_data_dir = shared;
  traits.user_data_dir = user_dir;
  traits.distribution_name = "KINFX-IME-Smoke";
  traits.distribution_code_name = "kinfx-ime";
  traits.distribution_version = "0.3.0";
  traits.app_name = "rime.kinfx-ime-smoke";
  traits.min_log_level = 2;
  traits.log_dir = "";

  api->setup(&traits);
  api->set_notification_handler(on_notify, NULL);
  api->initialize(&traits);

  if (api->start_maintenance(True)) {
    api->join_maintenance_thread();
  }
  for (int i = 0; i < 50 && g_deploy_ok == 0; ++i) usleep(20000);

  RimeSessionId sid = api->create_session();
  if (!sid) {
    fprintf(stderr, "create_session failed\n");
    api->finalize();
    return 3;
  }

  if (!api->select_schema(sid, "kinfx_quick")) {
    fprintf(stderr, "select_schema kinfx_quick failed\n");
  }

  RIME_STRUCT(RimeStatus, st);
  if (api->get_status(sid, &st)) {
    printf("schema=%s name=%s ascii=%d\n",
           st.schema_id ? st.schema_id : "?",
           st.schema_name ? st.schema_name : "?", st.is_ascii_mode);
    api->free_status(&st);
  }

  int ok_page = assert_page_size(api, sid, "hi", 9);
  int ok_sel = assert_select_key_1(api, sid, "vd", "好");
  int ok_me = try_code(api, sid, "me", "夏");
  int ok_vd = try_code(api, sid, "vd", "好");
  int ok_or = try_code(api, sid, "or", "倉");
  int ok_page2 = assert_page2(api, sid);
  int ok_topout = assert_windows_topout(api, sid);
  int ok_win = assert_win_table(api, sid);
  /* 丂 is Windows slot 32 on ms: kept (Windows order), never on page 1. */
  int ok_no_qiao = first_page_rank(api, sid, "ms", "丂") < 0;
  int ok_mix = try_mixed_zero_switch(api, sid);
  int ok_phrase = assert_phrase_mix(api, sid);
  int ok_engmix = assert_english_mix(api, sid);
  int ok_assoc = assert_association(api, sid);
  int ok_keys = assert_space_enter(api, sid);
  int ok_hot = assert_hot_cycle(api, sid);
  int ok_tab = assert_tab_expand(api, sid);
  int ok_one = assert_single_page_space(api, sid);
  int ok_hist = assert_hot_history(api, sid);
  int ok_jyut = try_jyutping_tone(api, sid);

  api->destroy_session(sid);
  api->finalize();

  printf(
      "\nRESULT page9:%s sel1:%s me:%s vd:%s or:%s win-top9:%s no丂:%s "
      "mix0switch:%s phrase:%s engmix:%s assoc:%s space/enter:%s hot:%s tab:%s single:%s hist:%s "
      "jyut:%s\n",
      ok_page ? "PASS" : "FAIL", ok_sel ? "PASS" : "FAIL",
      ok_me ? "PASS" : "FAIL", ok_vd ? "PASS" : "FAIL", ok_or ? "PASS" : "FAIL",
      ok_win ? "PASS" : "FAIL", ok_no_qiao ? "PASS" : "FAIL",
      ok_mix ? "PASS" : "FAIL", ok_phrase ? "PASS" : "FAIL",
      ok_engmix ? "PASS" : "FAIL", ok_assoc ? "PASS" : "FAIL",
      ok_keys ? "PASS" : "FAIL", ok_hot ? "PASS" : "FAIL",
      ok_tab ? "PASS" : "FAIL", ok_one ? "PASS" : "FAIL",
      ok_hist ? "PASS" : "FAIL", ok_jyut ? "PASS" : "FAIL");
  printf("RESULT2 page2:%s topout:%s\n", ok_page2 ? "PASS" : "FAIL",
         ok_topout ? "PASS" : "FAIL");
  return (ok_page && ok_sel && ok_me && ok_vd && ok_or && ok_win &&
          ok_no_qiao && ok_mix && ok_phrase && ok_engmix && ok_assoc &&
          ok_keys && ok_hot && ok_tab &&
          ok_one && ok_hist && ok_jyut && ok_page2 && ok_topout)
             ? 0
             : 1;
}
