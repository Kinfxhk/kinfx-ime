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
  int ok = commit[0] == 0 && b.composing && b.hot && b.num == 9 &&
           b.page_size == 9 && b.page_size == a.page_size;
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
  traits.distribution_version = "0.2.0";
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
  int ok_rank_wo = rank_first_page(api, sid, "hi", "我", 1);
  int ok_rank_si = rank_first_page(api, sid, "ai", "時", 1);
  int ok_rank_ho = rank_first_page(api, sid, "vd", "好", 1);
  int ok_rank_xia = rank_first_page(api, sid, "me", "夏", 5);
  int ok_rank_cang = rank_first_page(api, sid, "or", "倉", 9);
  int ok_rank_tin = rank_first_page(api, sid, "mk", "天", 9);
  int ok_no_qiao = assert_absent(api, sid, "ms", "丂");
  int ok_mix = try_mixed_zero_switch(api, sid);
  int ok_keys = assert_space_enter(api, sid);
  int ok_hot = assert_hot_cycle(api, sid);
  int ok_tab = assert_tab_expand(api, sid);
  int ok_one = assert_single_page_space(api, sid);
  int ok_hist = assert_hot_history(api, sid);
  int ok_jyut = try_jyutping_tone(api, sid);

  api->destroy_session(sid);
  api->finalize();

  printf(
      "\nRESULT page9:%s sel1:%s me:%s vd:%s or:%s 我@hi≤1:%s 時@ai≤1:%s "
      "好@vd≤1:%s 夏@me≤5:%s 倉@or≤9:%s 天@mk≤9:%s no丂:%s mix0switch:%s "
      "space/enter:%s hot:%s tab:%s single:%s hist:%s jyut:%s\n",
      ok_page ? "PASS" : "FAIL", ok_sel ? "PASS" : "FAIL",
      ok_me ? "PASS" : "FAIL", ok_vd ? "PASS" : "FAIL", ok_or ? "PASS" : "FAIL",
      ok_rank_wo ? "PASS" : "FAIL", ok_rank_si ? "PASS" : "FAIL",
      ok_rank_ho ? "PASS" : "FAIL", ok_rank_xia ? "PASS" : "FAIL",
      ok_rank_cang ? "PASS" : "FAIL", ok_rank_tin ? "PASS" : "FAIL",
      ok_no_qiao ? "PASS" : "FAIL", ok_mix ? "PASS" : "FAIL",
      ok_keys ? "PASS" : "FAIL", ok_hot ? "PASS" : "FAIL",
      ok_tab ? "PASS" : "FAIL", ok_one ? "PASS" : "FAIL",
      ok_hist ? "PASS" : "FAIL", ok_jyut ? "PASS" : "FAIL");
  return (ok_page && ok_sel && ok_me && ok_vd && ok_or && ok_rank_wo &&
          ok_rank_si && ok_rank_ho && ok_rank_xia && ok_rank_cang &&
          ok_rank_tin && ok_no_qiao && ok_mix && ok_keys && ok_hot && ok_tab &&
          ok_one && ok_hist && ok_jyut)
             ? 0
             : 1;
}
