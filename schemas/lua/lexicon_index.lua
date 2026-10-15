-- Sorted code index over a generated *.dict.yaml (text, code, weight).
-- Binary search is the runtime prefix lookup. One code per lexicon row;
-- the file is produced by gen_quick_phrases.py, not by a cartesian product.

local M = {}

local cache = {}

local function lower_bound(rows, prefix)
  local lo = 1
  local hi = #rows + 1
  while lo < hi do
    local mid = math.floor((lo + hi) / 2)
    if rows[mid].code < prefix then
      lo = mid + 1
    else
      hi = mid
    end
  end
  return lo
end

local function parse_dict(path)
  local rows = {}
  local fh = io.open(path, "r")
  if not fh then
    return rows
  end
  local body = false
  for line in fh:lines() do
    if not body then
      if line == "..." then
        body = true
      end
    elseif line ~= "" and not line:match("^#") then
      local text, code, weight = line:match("^([^\t]+)\t([a-z]+)\t(%d+)")
      if text and code then
        rows[#rows + 1] = {
          text = text,
          code = code,
          weight = tonumber(weight) or 0,
        }
      end
    end
  end
  fh:close()
  return rows
end

local function merge_sorted(a, b)
  local out = {}
  local i, j = 1, 1
  local na, nb = #a, #b
  while i <= na and j <= nb do
    local x, y = a[i], b[j]
    local take_a = false
    if x.code < y.code then
      take_a = true
    elseif x.code == y.code and x.weight > y.weight then
      take_a = true
    elseif x.code == y.code and x.weight == y.weight and x.text < y.text then
      take_a = true
    end
    if take_a then
      out[#out + 1] = x
      i = i + 1
    else
      out[#out + 1] = y
      j = j + 1
    end
  end
  while i <= na do
    out[#out + 1] = a[i]
    i = i + 1
  end
  while j <= nb do
    out[#out + 1] = b[j]
    j = j + 1
  end
  return out
end

local function wrap(rows)
  local index = { rows = rows }
  function index:has_prefix(prefix)
    if not prefix or prefix == "" then
      return false
    end
    local i = lower_bound(self.rows, prefix)
    local row = self.rows[i]
    if not row then
      return false
    end
    return row.code:sub(1, #prefix) == prefix
  end
  function index:collect(prefix, exact_only)
    local found = {}
    if not prefix or prefix == "" then
      return found
    end
    local i = lower_bound(self.rows, prefix)
    local n = #prefix
    while i <= #self.rows do
      local row = self.rows[i]
      if row.code:sub(1, n) ~= prefix then
        break
      end
      if not exact_only or row.code == prefix then
        found[#found + 1] = row
      elseif row.code > prefix then
        break
      end
      i = i + 1
    end
    return found
  end
  return index
end

function M.load(path)
  local hit = cache[path]
  if hit then
    return hit
  end
  local index = wrap(parse_dict(path))
  cache[path] = index
  return index
end

function M.load_merged(paths)
  local key = table.concat(paths, "|")
  local hit = cache[key]
  if hit then
    return hit
  end
  local merged = {}
  for _, path in ipairs(paths) do
    merged = merge_sorted(merged, parse_dict(path))
  end
  local index = wrap(merged)
  cache[key] = index
  return index
end

function M.user_file(name)
  if not rime_api or not rime_api.get_user_data_dir then
    return nil
  end
  local dir = rime_api.get_user_data_dir()
  if not dir or dir == "" then
    return nil
  end
  return dir .. "/" .. name
end

return M
