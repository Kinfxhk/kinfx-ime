/* Headless librime smoke: Sucheng candidates for ME / VD.
 * Build: see run_smoke.sh
 */
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

static void print_menu(RimeContext* ctx) {
  printf("  preedit=%s num=%d\n",
         ctx->composition.preedit ? ctx->composition.preedit : "",
         ctx->menu.num_candidates);
  for (int i = 0; i < ctx->menu.num_candidates && i < 12; ++i) {
    printf("  [%d] %s\n", i + 1,
           ctx->menu.candidates[i].text ? ctx->menu.candidates[i].text : "");
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
    /* Page_Down */
    api->process_key(sid, 0xff56, 0);
  }
  api->clear_composition(sid);
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
  traits.distribution_version = "0.1.0";
  traits.app_name = "rime.kinfx-ime-smoke";
  traits.min_log_level = 2;
  traits.log_dir = "";

  api->setup(&traits);
  api->set_notification_handler(on_notify, NULL);
  api->initialize(&traits);

  if (api->start_maintenance(True)) {
    api->join_maintenance_thread();
  }
  /* give deploy notify a moment */
  for (int i = 0; i < 50 && g_deploy_ok == 0; ++i) usleep(20000);

  RimeSessionId sid = api->create_session();
  if (!sid) {
    fprintf(stderr, "create_session failed\n");
    api->finalize();
    return 3;
  }

  if (!api->select_schema(sid, "kinfx_quick")) {
    fprintf(stderr, "select_schema kinfx_quick failed (is schema deployed?)\n");
    /* still try */
  }

  RIME_STRUCT(RimeStatus, st);
  if (api->get_status(sid, &st)) {
    printf("schema=%s name=%s ascii=%d\n",
           st.schema_id ? st.schema_id : "?",
           st.schema_name ? st.schema_name : "?", st.is_ascii_mode);
    api->free_status(&st);
  }

  int ok_me = try_code(api, sid, "me", "夏");
  int ok_vd = try_code(api, sid, "vd", "好");
  int ok_or = try_code(api, sid, "or", "倉");

  /* ascii mode toggle smoke: set option and type latin */
  api->set_option(sid, "ascii_mode", True);
  api->simulate_key_sequence(sid, "API");
  RIME_STRUCT(RimeContext, ctx);
  api->get_context(sid, &ctx);
  printf("ascii_mode typing 'API': preedit/commit path num=%d\n",
         ctx.menu.num_candidates);
  api->free_context(&ctx);
  api->set_option(sid, "ascii_mode", False);

  api->destroy_session(sid);
  api->finalize();

  printf("\nRESULT me→夏:%s vd→好:%s or→倉:%s\n",
         ok_me ? "PASS" : "FAIL", ok_vd ? "PASS" : "FAIL",
         ok_or ? "PASS" : "FAIL");
  return (ok_me && ok_vd && ok_or) ? 0 : 1;
}
