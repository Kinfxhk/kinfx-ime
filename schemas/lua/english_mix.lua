-- KINFX v0.5 English: delayed top-out + Space + Left Shift tap.
--
-- Rule: Chinese typed the Windows way must come out exactly as v0.4.1.
-- How: while the letters typed since the run started are still a prefix of an
-- English word (native kinfx_en table, never a Lua heap table), this processor
-- runs the same v0.4.1 key rule (phrase_mix helpers + speller top-out) for each
-- letter, but every top-out it would commit goes into a pending buffer instead
-- of the app. ctx.input therefore stays exactly in the v0.4.1 state (same menu,
-- same phrase hold, same paging).
--   * Space on a space-safe English word (>= 3 letters, not in
--     kinfx_en_unsafe.txt, no Chinese phrase held) commits the word + " ".
--   * Comma / period on such a word commits the word; the punctuator follows.
--   * Left Shift tap (english/commit_key) commits the raw letters.
--   * Any other key first commits the pending buffer and then runs untouched,
--     so the app ends up with the v0.4.1 text.
--   * A letter that ends the English prefix does the same.
-- A run starts on an empty composition or right after a Windows top-out
-- (vd + hello: 好 is committed as usual, then hello is tracked).
-- english/mode: shift (= v0.4.1) or off turns all of this off.

local pm = require("phrase_mix").helpers

local kAccepted = 1
local kNoop = 2

local function config_int(config, path, default)
  local v = config:get_int(path)
  if v == nil then
    return default
  end
  return v
end

local function config_str(config, path, default)
  local v = config:get_string(path)
  if v == nil or v == "" then
    return default
  end
  return v
end

local function user_file(name)
  if not rime_api or not rime_api.get_user_data_dir then
    return nil
  end
  local dir = rime_api.get_user_data_dir()
  if not dir or dir == "" then
    return nil
  end
  return dir .. "/" .. name
end

-- About 350 short words; small enough for a Lua set.
local unsafe_cache = nil
local function load_unsafe()
  if unsafe_cache then
    return unsafe_cache
  end
  unsafe_cache = {}
  local path = user_file("kinfx_en_unsafe.txt")
  local fh = path and io.open(path, "r")
  if fh then
    for line in fh:lines() do
      local w = line:match("^([a-z]+)%s*$")
      if w then
        unsafe_cache[w] = true
      end
    end
    fh:close()
  end
  return unsafe_cache
end

-- Product / company names (kinfx_en_names.txt: "Display<TAB>code", a few
-- hundred lines). Most are missing from SCOWL, so their letters would top out
-- as Chinese. A small Lua set of names and their prefixes (a few thousand
-- short strings) is fine for the heap; the big English table stays native.
local names_cache, name_prefix_cache = nil, nil
local function load_names()
  if names_cache then
    return names_cache, name_prefix_cache
  end
  names_cache, name_prefix_cache = {}, {}
  local path = user_file("kinfx_en_names.txt")
  local fh = path and io.open(path, "r")
  if fh then
    for line in fh:lines() do
      line = line:gsub("\r$", "")
      if line ~= "" and line:sub(1, 1) ~= "#" then
        local text, code = line:match("^([^\t]+)\t([a-z][a-z0-9]*)%s*$")
        if not code then
          code = line:match("^([a-z][a-z0-9]*)%s*$")
          text = code
        end
        if code then
          names_cache[code] = text
          for i = 1, #code do
            name_prefix_cache[code:sub(1, i)] = true
          end
        end
      end
    end
    fh:close()
  end
  return names_cache, name_prefix_cache
end

-- Display text for an exact English code: the lowercase entry when the table
-- has one, else its first entry (gmail -> Gmail). Second value: whether a
-- lowercase entry exists (proper nouns such as Chen / Ohio have none).
local function word_text(mem, code)
  if not mem then
    return nil
  end
  local first, exact = nil, nil
  pcall(function()
    if mem:dict_lookup(code, false, 20) then
      for entry in mem:iter_dict() do
        first = first or entry.text
        if entry.text == code then
          exact = entry.text
          break
        end
      end
    end
  end)
  return exact or first, exact ~= nil
end

local function assoc_active(ctx)
  local comp = ctx.composition
  if not comp or comp:empty() then
    return false
  end
  local seg = comp:back()
  return seg and seg:has_tag("kinfx_assoc") or false
end

local function close_assoc(ctx)
  local comp = ctx.composition
  if comp and not comp:empty() then
    local seg = comp:back()
    if seg and seg:has_tag("kinfx_assoc") then
      comp:pop_back()
    end
  end
  ctx:set_property("kinfx_assoc_code", "")
end

-- Run state, shared by the processor and the hint filter (one Lua state).
-- known: length of the longest prefix of raw that is a kinfx_en prefix.
-- raw longer than known = an unknown word held on (wondershare, kubernetes).
local S = { raw = "", pending = "", tracking = false, guard = false, known = 0 }

local function reset()
  S.raw, S.pending, S.tracking, S.known = "", "", false, 0
end

-- Older builds put the hint in seg.prompt; nothing to clear now.
local function clear_hint(_ctx)
end

local function flush(env)
  local text = S.pending
  reset()
  if text ~= "" then
    env.engine:commit_text(text)
  end
end

local function set_input(ctx, text)
  S.guard = true
  ctx.input = text
  S.guard = false
end

-- The top-out candidate v0.4.1's speller would confirm for a full 2-letter code.
local function topout_text(ctx, input)
  if not ctx:has_menu() then
    return nil
  end
  local cand = ctx:get_selected_candidate()
  if not cand or cand.start ~= 0 or cand._end ~= #input then
    return nil
  end
  return cand.text
end

-- One letter through the v0.4.1 rule with its commit sent to S.pending.
-- Returns false when v0.4.1 would take a path this does not mirror; the caller
-- then flushes and lets the normal processors run.
local function v041_letter(env, ctx, ch)
  local input = ctx.input or ""
  if #input < 2 then
    set_input(ctx, input .. ch)
    return true
  end
  local extended = input .. ch
  if #input == 2 then
    if pm.may_capture(env, extended) then
      set_input(ctx, extended)
      return true
    end
    if not ctx:has_menu() then
      set_input(ctx, extended) -- speller pushes when nothing to top out
      return true
    end
    local text = topout_text(ctx, input)
    if not text then
      return false
    end
    S.pending = S.pending .. text
    set_input(ctx, ch)
    return true
  end
  if pm.may_capture(env, extended) or (#extended >= 5 and pm.continues(env, extended)) then
    set_input(ctx, extended)
    return true
  end
  -- split_commit: first candidate of every complete pair, the rest stays.
  local out = {}
  local i = 1
  while i + 1 <= #input do
    local text = pm.first_text(env.main, input:sub(i, i + 1))
    if not text then
      return false
    end
    out[#out + 1] = text
    i = i + 2
  end
  S.pending = S.pending .. table.concat(out)
  set_input(ctx, input:sub(i) .. ch)
  return true
end

-- A Chinese phrase is held (the menu leads with a Chinese phrase for 3+
-- letters). Chinese wins there: Space and punctuation behave like v0.4.1.
local function chinese_held(ctx)
  -- Only a phrase that spans the whole letter run counts. When top-outs are
  -- already pending (passion: 旨巨 + ion → 之隔…), the Chinese phrase covers the
  -- tail only and the run as a whole is the English word.
  if S.pending ~= "" then
    return false
  end
  local input = ctx.input or ""
  if #input < 3 or not ctx:has_menu() then
    return false
  end
  local cand = ctx:get_selected_candidate()
  return cand ~= nil and cand.text:find("[\128-\255]") ~= nil
end

local function space_allowed(env, raw)
  if #raw < 3 or env.space_mode == "off" then
    return false
  end
  if env.space_mode == "long" and #raw < 5 then
    return false
  end
  if env.space_mode == "safe" and env.unsafe[raw] then
    return false
  end
  return true
end

local function commit_word(env, ctx, text)
  reset()
  S.guard = true
  ctx:clear()
  S.guard = false
  env.engine:commit_text(text)
end

-- Keys that close the association list and then type themselves. Shift+digit
-- symbols (exclam at numbersign ... parenleft) pick from the list instead, and
-- equal stays a page key.
local ASSOC_PUNCT = {
  period = true, comma = true, minus = true, semicolon = true, colon = true,
  question = true, slash = true, apostrophe = true, quotedbl = true,
  bracketleft = true, bracketright = true, braceleft = true, braceright = true,
  backslash = true, bar = true, grave = true, asciitilde = true,
  underscore = true, plus = true, less = true, greater = true,
  parenright = true,
}

local KEYCODE = { Shift_L = 0xffe1, Shift_R = 0xffe2, Caps_Lock = 0xffe5 }

-- Space may commit this word: a common (lowercase) word, or a listed extra
-- such as Gmail. Proper nouns only through Left Shift; they collide with
-- Chinese more and are rarely typed lowercase on purpose.
local function space_text(env, raw)
  local text, lower = word_text(env.en_mem, raw)
  -- An ordinary lowercase word stays lowercase (word, apple, edge); the
  -- names list only supplies the form for codes without one (openai -> OpenAI).
  if lower then
    return text
  end
  if env.names[raw] then
    return env.names[raw]
  end
  if text and env.hold_set[raw] then
    return text
  end
  return nil
end

-- Left Shift form: same rule (lowercase word first, then the names list).
local function shift_text(env, raw)
  local text, lower = word_text(env.en_mem, raw)
  if lower then
    return text
  end
  return env.names[raw] or raw
end

-- An unknown word (raw ran past every kinfx_en prefix): Space commits the raw
-- letters once the word is long enough that Chinese typing rarely ends there.
local function unknown_space_ok(env, ctx)
  return env.space_mode ~= "off" and #S.raw > S.known and env.unknown_space_min > 0
    and #S.raw >= env.unknown_space_min and not chinese_held(ctx)
end

local function read_env(env)
  local config = env.engine.schema.config
  local on = pm.config_bool(config, "english/enable", true)
  env.smart = on and config_str(config, "english/mode", "smart") == "smart"
  env.space_mode = config_str(config, "english/space", "safe")
  -- association/space: type (Space closes the list and types a space) | page
  -- (Windows: Space pages the list and is swallowed).
  env.assoc_space = config_str(config, "association/space", "type")
  env.commit_key = config_str(config, "english/commit_key", "Shift_L")
  env.commit_code = KEYCODE[env.commit_key] or 0xffe1
  env.en_mem = pm.new_memory(env, "kinfx_en")
  env.unsafe = load_unsafe()
  env.names, env.name_prefix = load_names()
  -- english/empty_shift: noop (default; a Left Shift tap with nothing typed
  -- does nothing) | ascii (librime inline_ascii: switch to English).
  env.empty_shift = config_str(config, "english/empty_shift", "noop")
  -- english/hold_min: once an English prefix of this many letters breaks,
  -- keep holding up to hold_extra more letters as an unknown word (company /
  -- product names). 0 = off. Chinese output is still v0.4.1 for every key
  -- except Space / Left Shift on such a run.
  env.hold_min = config_int(config, "english/hold_min", 4)
  env.hold_extra = config_int(config, "english/hold_extra", 8)
  env.unknown_space_min = config_int(config, "english/unknown_space_min", 7)
  local _, hold = pm.load_capture()
  env.hold = hold
  env.hold_set = {}
  for _, w in ipairs(hold) do
    env.hold_set[w] = true
  end
end

local function init(env)
  pm.init(env)
  read_env(env)
  env.shift_down = false
  reset()
  if not env.smart then
    return
  end
  local ctx = env.engine.context
  -- A candidate picked with the mouse commits without a key event: send the
  -- pending top-outs first (grouped slots run before the engine's own).
  env.commit_conn = ctx.commit_notifier:connect(function(_)
    if not S.guard and S.pending ~= "" then
      local text = S.pending
      reset()
      env.engine:commit_text(text)
    end
  end, 0)
  -- Composition cleared from outside (focus change, schema switch): drop the run.
  env.update_conn = ctx.update_notifier:connect(function(c)
    if not S.guard and (c.input or "") == "" then
      reset()
    end
  end)
end

local function fini(env)
  if env.commit_conn then
    env.commit_conn:disconnect()
  end
  if env.update_conn then
    env.update_conn:disconnect()
  end
end

local function start_run(ctx, ch)
  S.tracking, S.raw, S.pending, S.known = true, ch, "", 1
  set_input(ctx, ch)
end

-- May the run take letter ch? A kinfx_en prefix, or an unknown word that
-- started as a long enough English prefix (hold_min) and is still short.
local function can_extend(env, raw)
  if pm.has_prefix(env.en_mem, raw) or env.name_prefix[raw] then
    return true, true
  end
  if env.hold_min > 0 and S.known >= env.hold_min
     and #raw <= S.known + env.hold_extra then
    return true, false
  end
  return false, false
end

local function extend(env, ctx, ch)
  local raw = S.raw .. ch
  local ok, known = can_extend(env, raw)
  if not ok or not (ctx.input or ""):match("^[a-z]*$") then
    return false
  end
  S.raw = raw -- before set_input, so the hint filter sees it
  if known and S.known == #raw - 1 then
    S.known = #raw
  end
  return v041_letter(env, ctx, ch)
end

-- Backspace inside a held run: drop the last letter and rebuild the run, so a
-- typo in an English word does not commit the held Chinese top-outs.
local function backspace(env, ctx)
  local raw = S.raw:sub(1, -2)
  reset()
  S.guard = true
  ctx:clear()
  S.guard = false
  if raw == "" then
    return
  end
  start_run(ctx, raw:sub(1, 1))
  for i = 2, #raw do
    if not extend(env, ctx, raw:sub(i, i)) then
      break
    end
  end
end

local function func(key, env)
  local ctx = env.engine.context
  local repr = key:repr()
  -- Compare keycodes, not repr: Weasel sends "Shift+Shift_L" for the press
  -- and "Shift+Release+Shift_L" for the release on a real keyboard.
  local kc = key.keycode

  -- Left Shift tap while the association list shows: close it (Windows) and
  -- swallow the tap so ascii_composer does not switch to English.
  if kc == 0xffe1 then
    if not key:release() then
      env.assoc_tap = true
    elseif env.assoc_tap and assoc_active(ctx) then
      env.assoc_tap = false
      close_assoc(ctx)
      return kAccepted
    end
  elseif not key:release() then
    env.assoc_tap = false
  end

  -- Association list open (after a one-character pick). key_binder runs
  -- before assoc_keys and maps period to Page_Down whenever a menu shows, so a
  -- full stop typed after a Chinese pick was swallowed as paging. Close the
  -- list first; the key then reaches key_binder with no menu and types.
  if not key:release() and assoc_active(ctx) and
     not (key:ctrl() or key:alt() or key:super()) then
    if ASSOC_PUNCT[repr] or (repr == "space" and env.assoc_space == "type") then
      close_assoc(ctx)
      return kNoop
    end
  end

  if not env.smart then
    return kNoop
  end

  -- Left Shift tap: press, then release with no other key in between.
  if kc == env.commit_code and not key:release() then
    env.shift_down = true
    return kNoop
  end
  if kc == env.commit_code and key:release() then
    local tap = env.shift_down
    env.shift_down = false
    if tap and S.tracking and S.raw ~= "" then
      -- the raw letters (or a listed name: openai -> OpenAI) replace the held top-outs
      commit_word(env, ctx, shift_text(env, S.raw))
      return kAccepted
    end
    local input = ctx.input or ""
    if tap and not ctx:get_option("ascii_mode") and input:match("^[a-z]+$") then
      commit_word(env, ctx, input) -- letters left after a Windows commit
      return kAccepted
    end
    -- Anything else being composed (uppercase / digits / a punctuation menu,
    -- e.g. 好API, or an inline-English run): commit what is shown and stay
    -- in Chinese. Letting ascii_composer run here turned the composition into
    -- an underlined inline-English run that only Enter or Esc could leave
    -- (Enter then committed the raw code, vdAPI instead of 好API).
    if tap and input ~= "" then
      local text = ctx:get_commit_text()
      flush(env)
      commit_word(env, ctx, text)
      if ctx:get_option("ascii_mode") then
        ctx:set_option("ascii_mode", false)
      end
      return kAccepted
    end
    -- Nothing typed: a stray tap must not switch to English (it looked like
    -- a stuck mode). english/empty_shift: ascii keeps the librime toggle.
    if tap and input == "" and env.empty_shift ~= "ascii"
       and not ctx:get_option("ascii_mode") then
      return kAccepted
    end
    return kNoop
  end
  if key:release() then
    return kNoop
  end
  env.shift_down = false
  if ctx:get_option("ascii_mode") then
    return kNoop
  end

  local plain = not (key:ctrl() or key:alt() or key:super())
  local input = ctx.input or ""

  if plain and repr == "BackSpace" and S.tracking and S.raw ~= "" then
    backspace(env, ctx)
    return kAccepted
  end

  if plain and repr:match("^[a-z]$") then
    if S.tracking then
      local raw = S.raw .. repr
      if can_extend(env, raw) and input:match("^[a-z]*$") then
        if extend(env, ctx, repr) then
          return kAccepted
        end
        flush(env)
        return kNoop
      end
      -- The English prefix broke: send the held top-outs now (v0.4.1 had
      -- committed them already) and fall through, so this letter can still
      -- start a new English run at a code boundary.
      flush(env)
    end
    if input == "" then
      flush(env)
      if assoc_active(ctx) then
        close_assoc(ctx)
      end
      start_run(ctx, repr)
      return kAccepted
    end
    if not input:match("^[a-z]+$") then
      flush(env)
      return kNoop
    end
    -- v0.4.1 step for this letter, commits held in S.pending.
    S.pending = ""
    if not v041_letter(env, ctx, repr) then
      flush(env)
      return kNoop
    end
    local rest = ctx.input or ""
    flush(env)
    if rest:match("^[a-z]+$") and (pm.has_prefix(env.en_mem, rest) or env.name_prefix[rest]) then
      -- Everything committed so far is final; the letters still composing
      -- start at a Windows code boundary, so track them as a possible word.
      S.tracking, S.raw, S.pending, S.known = true, rest, "", #rest
    end
    return kAccepted
  end

  if not S.tracking then
    return kNoop
  end
  clear_hint(ctx)
  local endkey = plain and (repr == "space" or repr == "comma" or repr == "period")
  if endkey and unknown_space_ok(env, ctx) then
    if repr == "space" then
      commit_word(env, ctx, S.raw .. " ")
      return kAccepted
    end
    commit_word(env, ctx, S.raw)
    return kNoop
  end
  if endkey and space_allowed(env, S.raw) and not chinese_held(ctx) then
    local text = space_text(env, S.raw)
    if text then
      if repr == "space" then
        commit_word(env, ctx, text .. " ")
        return kAccepted
      end
      commit_word(env, ctx, text)
      return kNoop -- the punctuator types the comma / period
    end
  end
  flush(env)
  return kNoop
end

-- Hint after the caret: pending top-outs, then ␣word (Space commits English)
-- or ⇧letters (Left Shift commits them).
local function filter_init(env)
  read_env(env)
end

local function filter_func(input, env)
  -- The hint rides on the first candidate's comment, never on seg.prompt:
  -- a prompt is drawn inside the inline preedit, and clients that commit the
  -- preedit (Fcitx5 on focus change / IM switch) wrote it into the document.
  local hint = nil
  if env.smart and S.tracking and #S.raw >= 2 then
    local ctx = env.engine.context
    local mark = "⇧"
    if (space_allowed(env, S.raw) and not chinese_held(ctx)
        and space_text(env, S.raw)) or unknown_space_ok(env, ctx) then
      mark = "␣"
    end
    local pre = S.pending ~= "" and (S.pending .. " ") or ""
    hint = pre .. mark .. S.raw
  end
  for cand in input:iter() do
    if hint then
      local c = cand.comment or ""
      yield(ShadowCandidate(cand, cand.type, cand.text, c ~= "" and (c .. " " .. hint) or hint))
      hint = nil
    else
      yield(cand)
    end
  end
end

return {
  processor = { init = init, func = func, fini = fini },
  filter = { init = filter_init, func = filter_func },
}
