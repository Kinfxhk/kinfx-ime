-- KINFX v0.5 English smart mode: delayed top-out + Space + Left Shift.
--
-- No big tables in the Lua heap. English word / prefix checks go through the
-- native kinfx_en table (Memory:dict_lookup); only the small unsafe set
-- (lexicon/en/kinfx_en_unsafe.txt, ~300 lines) is loaded into Lua.
--
-- Processors / filter:
--   english_shift  — Left Shift tap commits the held letters as English
--                    (registered before ascii_composer so it can block the
--                    inline_ascii toggle).
--   english_space  — Space commits a space-safe word (word + " "); a comma /
--                    period after a safe word commits the word so the
--                    punctuator can run (registered before key_binder).
--   english_menu   — lua_filter: while held as English-only, replace the empty
--                    menu with the Windows result (topped-out pairs + the
--                    pending code's candidates in dict order), so digits /
--                    Enter / paging work natively.
--
-- The "held as English" state is recomputed from ctx.input everywhere, so no
-- cross-module property is needed.

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

-- Text of the first entry for an exact code (e.g. "gmail" -> "Gmail").
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

local function read_env(env)
  local config = env.engine.schema.config
  env.enable = config_bool(config, "english/enable", true)
  env.mode = config_str(config, "english/mode", "smart")
  env.space_mode = config_str(config, "english/space", "safe")
  env.commit_key = config_str(config, "english/commit_key", "Shift_L")
end

-- Every complete two-letter pair must be a real Sucheng code, so the
-- split_commit fallback (and the flush) always has a top candidate.
local function all_pairs_valid(env, input)
  local i = 1
  while i + 1 <= #input do
    if not has_exact(env.main, input:sub(i, i + 1)) then
      return false
    end
    i = i + 2
  end
  return true
end

-- Held as English: >= 3 letters, still an English prefix, fallback-safe.
local function is_held_english(env, input)
  if #input < 3 then
    return false
  end
  if not has_prefix(env.en_mem, input) then
    return false
  end
  return all_pairs_valid(env, input)
end

-- Space may commit this input as an English word.
local function space_allows(env, input)
  if not has_exact(env.en_mem, input) then
    return false
  end
  if env.space_mode == "off" then
    return false
  end
  if env.space_mode == "long" then
    return #input >= 5
  end
  return not env.unsafe[input]  -- safe
end

local function word_text(env, input)
  return first_text(env.en_mem, input) or input
end

-- Split the held input into (committed prefix, pending code).
local function split_parts(input)
  local n = #input
  local keep = (n % 2 == 0) and 2 or 1
  return n - keep
end

-- Flush a held-English run back to the Windows state: commit every topped-out
-- pair, leave the last 1-2 letters pending (key_binder then pages them).
local function flush_windows(env, ctx, input)
  local commit_len = split_parts(input)
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
  local rest = input:sub(commit_len + 1)
  ctx:clear()
  if #out > 0 then
    env.engine:commit_text(table.concat(out))
  end
  if rest ~= "" then
    ctx:push_input(rest)
  end
  return true
end

-- ---------------------------------------------------------------- Shift tap

local function shift_init(env)
  read_env(env)
  env.shift_pending = false
end

local function shift_func(key, env)
  if not env.enable or env.mode ~= "smart" then
    return kNoop
  end
  local repr = key:repr()
  if repr == env.commit_key then
    env.shift_pending = true
    return kNoop
  elseif repr == "Release+" .. env.commit_key then
    local pending = env.shift_pending
    env.shift_pending = false
    if pending then
      local ctx = env.engine.context
      local input = ctx.input or ""
      if input ~= "" and input:match("^[a-z]+$") then
        env.engine:commit_text(input)
        ctx:clear()
        return kAccepted
      end
    end
    return kNoop
  else
    env.shift_pending = false
    return kNoop
  end
end

-- ---------------------------------------------------------------- Space

local function space_init(env)
  read_env(env)
  env.main = new_memory(env, nil)
  env.en_mem = new_memory(env, "kinfx_en")
  env.unsafe = load_unsafe()
end

local function space_func(key, env)
  if not env.enable or env.mode ~= "smart" then
    return kNoop
  end
  if key:release() or key:ctrl() or key:alt() or key:super() then
    return kNoop
  end
  local repr = key:repr()
  local ctx = env.engine.context
  local input = ctx.input or ""
  if input == "" or not input:match("^[a-z]+$") then
    return kNoop
  end
  if repr == "space" then
    if space_allows(env, input) then
      env.engine:commit_text(word_text(env, input) .. " ")
      ctx:clear()
      return kAccepted
    end
    if is_held_english(env, input) then
      flush_windows(env, ctx, input)
    end
    return kNoop
  elseif repr == "comma" or repr == "period" then
    if space_allows(env, input) then
      env.engine:commit_text(word_text(env, input))
      ctx:clear()
      return kNoop  -- punctuator commits the comma/period
    end
    if is_held_english(env, input) then
      flush_windows(env, ctx, input)
    end
    return kNoop
  end
  return kNoop
end

-- ---------------------------------------------------------------- menu filter

local function filter_init(env)
  read_env(env)
  env.main = new_memory(env, nil)
  env.en_mem = new_memory(env, "kinfx_en")
  env.unsafe = load_unsafe()
end

local function yield_english_menu(env, ctx, code)
  local commit_len = split_parts(code)
  local prefix = {}
  local i = 1
  while i + 1 <= commit_len do
    local text = first_text(env.main, code:sub(i, i + 1))
    if not text then
      return
    end
    prefix[#prefix + 1] = text
    i = i + 2
  end
  local pending = code:sub(commit_len + 1)
  local pre = table.concat(prefix)
  local seg = ctx.composition and ctx.composition:back() or nil
  local start_i = seg and seg.start or 0
  local end_i = seg and seg._end or #code
  if seg then
    seg.prompt = space_allows(env, code) and ("␣" .. code) or ("⇧" .. code)
  end
  pcall(function()
    if env.main:dict_lookup(pending, false, 1000) then
      for entry in env.main:iter_dict() do
        yield(Candidate("phrase", start_i, end_i, pre .. entry.text, ""))
      end
    end
  end)
end

local function filter_func(input, env)
  local ctx = env.engine.context
  if not env.enable or env.mode ~= "smart" then
    for cand in input:iter() do
      yield(cand)
    end
    return
  end
  local code = ctx.input or ""
  if code:match("^[a-z]+$") and #code >= 3
     and ctx:get_property("kinfx_hold") == "en"
     and is_held_english(env, code) then
    -- English-only hold: replace whatever the native translators offered
    -- (a coincidental phrase prefix) with the Windows result.
    yield_english_menu(env, ctx, code)
    return
  end
  for cand in input:iter() do
    yield(cand)
  end
end

return {
  shift = { init = shift_init, func = shift_func },
  space = { init = space_init, func = space_func },
  filter = { init = filter_init, func = filter_func },
}
