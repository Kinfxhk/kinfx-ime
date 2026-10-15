-- English completion (M5). Word list is lexicon/en, not rime-ice.
--
-- Prefix completion is raised only when the input length is at least 4
-- (gmai → Gmail). Length 3 raises an exact dictionary hit only.
-- me/or/of and every other 1–2 letter code yield nothing.
-- Quality stays under the phrase-mix bands.

local index_lib = require("lexicon_index")

local EXACT_BASE = 2000000
local PREFIX_BASE = 1000000

local PROTECT = {
  me = true,
  ["or"] = true,
  ["of"] = true,
}

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
  env.enable = config_bool(config, "melt_eng/enable", true)
  env.top_k = config_int(config, "melt_eng/top_k", 4)
  env.prefix_len = config_int(config, "melt_eng/prefix_length", 4)
  local path = index_lib.user_file("kinfx_en.dict.yaml")
  if path then
    env.english = index_lib.load(path)
  end
end

local function func(input, seg, env)
  if not env.enable or not env.english then
    return
  end
  if not seg:has_tag("abc") then
    return
  end
  if PROTECT[input] or not input:match("^[a-z]+$") then
    return
  end
  local n = #input
  if n < 3 then
    return
  end
  local predictive = n >= env.prefix_len
  local rows = env.english:collect(input, not predictive)
  if #rows == 0 then
    return
  end
  sort_rows(rows, n)
  local limit = env.top_k
  if limit > #rows then
    limit = #rows
  end
  local yielded = 0
  for i = 1, #rows do
    local row = rows[i]
    local exact = #row.code == n
    if predictive or exact then
      local base = PREFIX_BASE
      if exact then
        base = EXACT_BASE
      end
      local cand = Candidate("english", seg.start, seg._end, row.text, "en")
      cand.quality = base + row.weight
      yield(cand)
      yielded = yielded + 1
      if yielded >= limit then
        break
      end
    end
  end
end

return { init = init, func = func }
