-- lua/codereview/mr/addressed.lua
-- Local persistence for "addressed" comment flags.
-- Stores which review discussions the author has already fixed locally,
-- keyed by project:mr_id:disc_id in stdpath("data")/codereview_addressed.json.

local M = {}

local _data = nil -- lazy-loaded cache

local function data_path()
  return vim.fn.stdpath("data") .. "/codereview_addressed.json"
end

local function load()
  if _data then
    return _data
  end
  local path = data_path()
  local f = io.open(path, "r")
  if not f then
    _data = {}
    return _data
  end
  local raw = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.fn.json_decode, raw)
  _data = (ok and type(decoded) == "table") and decoded or {}
  return _data
end

local function save()
  local path = data_path()
  local ok, encoded = pcall(vim.fn.json_encode, _data)
  if not ok then
    vim.notify("[codereview] Failed to encode addressed flags: " .. tostring(encoded), vim.log.levels.WARN)
    return false
  end
  local f = io.open(path, "w")
  if not f then
    vim.notify("[codereview] Failed to write addressed flags to " .. path, vim.log.levels.WARN)
    return false
  end
  f:write(encoded)
  f:close()
  return true
end

--- Build the storage key for a discussion.
--- Includes base_url to avoid collisions between different GitHub/GitLab instances.
--- @param ctx table  provider context (ctx.project = "owner/repo", ctx.base_url = API URL)
--- @param review table  the MR/PR object (review.id = number)
--- @param disc_id any  discussion id
--- @return string
local function make_key(ctx, review, disc_id)
  local host = (ctx.base_url or ""):gsub("https?://", ""):gsub("/+$", "")
  return host .. ":" .. (ctx.project or "") .. ":" .. tostring(review.id) .. ":" .. tostring(disc_id)
end

--- Return true if the given discussion is marked as addressed.
--- @param ctx table
--- @param review table
--- @param disc_id any
--- @return boolean
function M.is_addressed(ctx, review, disc_id)
  local d = load()
  return d[make_key(ctx, review, disc_id)] == true
end

--- Toggle the addressed state for a discussion.
--- @param ctx table
--- @param review table
--- @param disc_id any
--- @return boolean  new addressed state
function M.toggle(ctx, review, disc_id)
  local d = load()
  local key = make_key(ctx, review, disc_id)
  local new_state = not (d[key] == true)
  d[key] = new_state or nil -- nil removes the key when un-marking
  save()
  return new_state
end

--- Return a set table { [disc_id_str] = true } of addressed discussions for this MR.
--- @param ctx table
--- @param review table
--- @return table
function M.get_set(ctx, review)
  local d = load()
  local host = (ctx.base_url or ""):gsub("https?://", ""):gsub("/+$", "")
  local prefix = host .. ":" .. (ctx.project or "") .. ":" .. tostring(review.id) .. ":"
  local result = {}
  for key, val in pairs(d) do
    if val == true and key:sub(1, #prefix) == prefix then
      local disc_id = key:sub(#prefix + 1)
      result[disc_id] = true
    end
  end
  return result
end

return M
