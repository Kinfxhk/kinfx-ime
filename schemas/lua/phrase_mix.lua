-- Lexicon-driven Sucheng phrases, plus the key hook that keeps a prefix together.
--
-- max_code_length 2 would 頂字 the first candidate when a third letter arrives
-- (of + c confirms 係). If that letter continues a stored phrase code or an
-- English word, phrase_mix_keys appends it instead, so ofc stays one segment
-- and can surface 無錯. Two-letter menus (me/or/of) are untouched.
--
-- Odd length is a trailing-code prefix (ofc → ofca). Even length prefers the
-- exact code, which uses a higher quality band.

local index_lib = require("lexicon_index")

local EXACT_BASE = 5000000
local PREFIX_BASE = 3000000

local kAccepted = 1
local kNoop = 2

local function config_bool(config, path, default)
  local v = config:get_bool(path)
  if v == nil then
    return default
  end
  return v
end

local function config_int(config, path, default)
  local v = config:get_int(path)
  if v == nil or v < 1 then
    return default
  end
  return v
end

local function pair_comment(code)
  if not code or code == "" then
    return "詞"
  end
  local parts = {}
  local i = 1
  while i <= #code do
    if i == #code then
      parts[#parts + 1] = code:sub(i, i)
      i = i + 1
    else
      parts[#parts + 1] = code:sub(i, i + 1)
      i = i + 2
    end
  end
  return table.concat(parts, "+")
end

local function open_indexes(env)
  local phrase_files = {
    index_lib.user_file("kinfx_hk_words.dict.yaml"),
    index_lib.user_file("kinfx_hk_idioms.dict.yaml"),
  }
  local en_file = index_lib.user_file("kinfx_en.dict.yaml")
  if phrase_files[1] and phrase_files[2] then
    env.phrases = index_lib.load_merged(phrase_files)
  end
  if en_file then
    env.english = index_lib.load(en_file)
  end
end

local function sort_rows(rows, input_len)
  table.sort(rows, function(a, b)
    local a_exact = #a.code == input_len
    local b_exact = #b.code == input_len
    if a_exact ~= b_exact then
      return a_exact
    end
    local a_rest = #a.code - input_len
    local b_rest = #b.code - input_len
    if a_rest ~= b_rest then
      return a_rest < b_rest
    end
    if a.weight ~= b.weight then
      return a.weight > b.weight
    end
    return a.text < b.text
  end)
end

local function init(env)
  local config = env.engine.schema.config
  env.enable = config_bool(config, "phrase_mix/enable", true)
  env.top_k = config_int(config, "phrase_mix/top_k", 12)
  env.min_len = config_int(config, "phrase_mix/min_length", 3)
  open_indexes(env)
end

local function func(input, seg, env)
  if not env.enable or not env.phrases then
    return
  end
  if not seg:has_tag("abc") then
    return
  end
  if #input < env.min_len or not input:match("^[a-z]+$") then
    return
  end
  local rows = env.phrases:collect(input, false)
  if #rows == 0 then
    return
  end
  sort_rows(rows, #input)
  local limit = env.top_k
  if limit > #rows then
    limit = #rows
  end
  for i = 1, limit do
    local row = rows[i]
    local base = PREFIX_BASE
    if #row.code == #input then
      base = EXACT_BASE
    end
    local cand = Candidate(
      "phrase",
      seg.start,
      seg._end,
      row.text,
      pair_comment(row.code)
    )
    cand.quality = base + row.weight
    yield(cand)
  end
end

-- Runs before the speller. A third letter that continues a lexicon code must
-- not 頂字 the 2-letter character (that would drop 無 and keep only 係).
local function key_init(env)
  local config = env.engine.schema.config
  env.enable = config_bool(config, "phrase_mix/enable", true)
  env.eng_enable = config_bool(config, "melt_eng/enable", true)
  open_indexes(env)
end

local function key_func(key, env)
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
  local input = ctx.input
  if not input or not input:match("^[a-z]*$") or #input < 2 then
    return kNoop
  end
  local extended = input .. ch
  local hit = false
  if env.enable and env.phrases and env.phrases:has_prefix(extended) then
    hit = true
  end
  if env.eng_enable and env.english and env.english:has_prefix(extended) then
    hit = true
  end
  if not hit then
    return kNoop
  end
  if not ctx:push_input(ch) then
    return kNoop
  end
  return kAccepted
end

local translator = { init = init, func = func }
local processor = { init = key_init, func = key_func }

return { translator = translator, processor = processor }
