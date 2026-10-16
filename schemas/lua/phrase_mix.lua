-- KINFX phrase / English mix on top of Windows-style Sucheng.
--
-- Lookups go to librime's compiled tables (kinfx_quick_phrase, kinfx_en) through
-- Memory:dict_lookup. Nothing large lives in the Lua heap, so a keystroke costs
-- a few milliseconds instead of a garbage-collector sweep over 240k rows.
--
-- Key rule (Windows first):
--   * Two letters, then a third: Windows tops out (頂字) and starts a new code.
--     KINFX holds keys 3 and 4 only while the input is in the gate list
--     (kinfx_capture.txt: prefixes of common phrases, plus full 4-letter
--     phrases such as ofch 無錫). So ofc shows 人類 / 無錯, ofca = 無錯.
--   * From key 5, any word in the compiled phrase table keeps it held. When
--     nothing continues, Windows takes over: the first candidate of each full
--     pair is committed and the rest becomes the new code, so ofcx → 伙 + cx
--     and vd o f 3 still gives 好係.
--   * English hold words ("+gmail" lines in kinfx_capture.txt: Gmail,
--     scriptwriting, voiceover ...) keep every letter while the input is still
--     a prefix of such a word. Other English goes through Shift or uppercase.
-- Segmentor: tags the held abc segment kinfx_phrase / kinfx_en (len ≥ 3) so the
-- native phrase / English translators never touch two-letter page 1.

local kAccepted = 1
local kNoop = 2

local function config_bool(config, path, default)
  local v = config:get_bool(path)
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

-- Small set: one 3-letter prefix per line (about a thousand lines).
local capture_cache = nil
local hold_words = nil
local function load_capture()
  if capture_cache then
    return capture_cache, hold_words
  end
  capture_cache = {}
  hold_words = {}
  local path = user_file("kinfx_capture.txt")
  local fh = path and io.open(path, "r")
  if fh then
    for line in fh:lines() do
      local w = line:match("^%+([a-z]+)")
      if w then
        -- English hold words live in their own list; they never enter the
        -- Chinese gate set, so gm+a still tops out when English is off.
        hold_words[#hold_words + 1] = w
      else
        local p = line:match("^([a-z][a-z][a-z]+)%s*$")
        if p then
          capture_cache[p] = true
        end
      end
    end
    fh:close()
  end
  return capture_cache, hold_words
end

local function is_hold_prefix(words, code)
  for _, w in ipairs(words) do
    if #w >= #code and w:sub(1, #code) == code then
      return true
    end
  end
  return false
end

local function new_memory(env, ns)
  local ok, mem = pcall(function()
    if ns then
      return Memory(env.engine, Schema(ns))
    end
    return Memory(env.engine, env.engine.schema)
  end)
  if ok then
    return mem
  end
  return nil
end

local function has_prefix(mem, code)
  if not mem then
    return false
  end
  local ok, hit = pcall(function()
    return mem:dict_lookup(code, true, 1)
  end)
  return ok and hit and true or false
end

local function has_exact(mem, code)
  if not mem then
    return false
  end
  local ok, hit = pcall(function()
    return mem:dict_lookup(code, false, 1)
  end)
  return ok and hit and true or false
end

local function first_text(mem, code)
  if not mem then
    return nil
  end
  local found = nil
  pcall(function()
    if mem:dict_lookup(code, false, 1) then
      for entry in mem:iter_dict() do
        found = entry.text
        break
      end
    end
  end)
  return found
end

-- Every complete two-letter pair must be a real Sucheng code, so the
-- split_commit fallback always has a top candidate to commit.
local function all_pairs_valid(env, code)
  local i = 1
  while i + 1 <= #code do
    if not has_exact(env.main, code:sub(i, i + 1)) then
      return false
    end
    i = i + 2
  end
  return true
end

-- English hold: smart = any English-word prefix (fallback-safe); shift = the
-- +word hold list (v0.4.1). off = none.
local function english_continues(env, code)
  if not env.eng_enable then
    return false
  end
  if env.mode == "smart" then
    return has_prefix(env.en_mem, code) and all_pairs_valid(env, code)
  elseif env.mode == "shift" then
    return is_hold_prefix(env.hold, code)
  end
  return false
end

local function processor_init(env)
  local config = env.engine.schema.config
  env.enable = config_bool(config, "phrase_mix/enable", true)
  env.eng_enable = config_bool(config, "english/enable", true)
  env.capture = config:get_string("phrase_mix/capture") or "hot"
  env.mode = config_str(config, "english/mode", "smart")
  env.main = new_memory(env, nil)
  env.phrase = new_memory(env, "kinfx_phrase")
  env.en_mem = new_memory(env, "kinfx_en")
  env.hot, env.hold = load_capture()
end

-- Whether the code is held, and by which side. "zh" = Chinese phrase gate
-- (its menu takes precedence); "en" = English prefix (smart) or hold word
-- (shift). Returns nil when nothing holds it.
local function hold_kind(env, code)
  if env.enable and env.capture ~= "none" then
    if env.hot[code] then
      return "zh"
    end
    if env.capture == "all" and has_prefix(env.phrase, code) then
      return "zh"
    end
    if #code >= 5 and has_prefix(env.phrase, code) then
      return "zh"
    end
  end
  if english_continues(env, code) then
    return "en"
  end
  return nil
end

-- Windows fallback: commit the top candidate of each topped-out pair, leaving
-- the last 1-2 letters pending (so the incoming char can still start a phrase,
-- e.g. latc + j → 帕 + tcj → 其它). Mirrors flush_windows' split_parts.
local function split_commit(env, ctx, input, ch)
  local n = #input
  local keep = (n % 2 == 0) and 2 or 1
  local commit_len = n - keep
  local out = {}
  local i = 1
  while i + 1 <= commit_len do
    local text = first_text(env.main, input:sub(i, i + 1))
    if not text then
      return false
    end
    out[#out + 1] = text
    i = i + 2
  end
  local rest = input:sub(commit_len + 1) .. ch
  ctx:clear()
  env.engine:commit_text(table.concat(out))
  ctx:push_input(rest)
  return true
end

local function processor_func(key, env)
  if not env.enable and not env.eng_enable then
    return kNoop
  end
  if key:release() or key:ctrl() or key:alt() or key:super() then
    return kNoop
  end
  local ch = key:repr()
  if not ch or not ch:match("^[a-z]$") then
    return kNoop
  end
  local ctx = env.engine.context
  local input = ctx.input or ""
  if #input < 2 or not input:match("^[a-z]+$") then
    ctx:set_property("kinfx_hold", "")
    return kNoop
  end
  local extended = input .. ch
  local kind = hold_kind(env, extended)
  if kind then
    ctx:set_property("kinfx_hold", kind)
  end
  if #input == 2 then
    if kind and ctx:push_input(ch) then
      return kAccepted
    end
    return kNoop -- speller tops out, exactly like Windows
  end
  -- Held composition (length ≥ 3). Key 4 must pass the gate list too
  -- (ofca 無錯, ofch 無錫); a full-table key 4 would turn 好同 into 好貼.
  -- From key 5 on, any phrase in the compiled table keeps it held.
  if kind then
    ctx:push_input(ch)
    return kAccepted
  end
  if split_commit(env, ctx, input, ch) then
    ctx:set_property("kinfx_hold", "")
    return kAccepted
  end
  return kNoop
end

-- Tag long abc segments so the native phrase / English translators run there
-- only, and only when their switch is on. English starts at 4 letters.
local function segmentor_init(env)
  local config = env.engine.schema.config
  env.enable = config_bool(config, "phrase_mix/enable", true)
  env.eng_enable = config_bool(config, "english/enable", true)
  env.mode = config_str(config, "english/mode", "smart")
end

local function segmentor_func(segmentation, env)
  if segmentation:empty() then
    return true
  end
  local seg = segmentation:back()
  if not seg or not seg:has_tag("abc") then
    return true
  end
  local n = seg._end - seg.start
  local tags = {}
  if env.enable and n >= 3 then
    tags[#tags + 1] = "kinfx_phrase"
  end
  -- Native English completion is only for mode shift (+word holds). In smart
  -- mode the Lua filter draws the Windows-like menu, so kinfx_en is not tagged
  -- (English must never sit in the 9 Windows slots).
  if env.eng_enable and env.mode ~= "smart" and n >= 4 then
    tags[#tags + 1] = "kinfx_en"
  end
  if #tags > 0 then
    seg.tags = seg.tags + Set(tags)
  end
  return true
end

return {
  processor = { init = processor_init, func = processor_func },
  segmentor = { init = segmentor_init, func = segmentor_func },
}
