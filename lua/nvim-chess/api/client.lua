local M = {}

local auth = require('nvim-chess.auth.manager')
local config = require('nvim-chess.config')

local function get_headers()
  local headers = {
    ["Accept"] = "application/json",
  }

  if auth.is_authenticated() then
    headers["Authorization"] = "Bearer " .. auth.get_token()
  end

  return headers
end

local function make_request(method, endpoint, opts)
  local curl = require('plenary.curl')
  local lichess_config = config.get_lichess_config()

  opts = opts or {}
  opts.headers = opts.headers or get_headers()
  opts.timeout = opts.timeout or lichess_config.timeout

  local url = lichess_config.base_url .. endpoint

  local response
  if method == "GET" then
    response = curl.get(url, opts)
  elseif method == "POST" then
    response = curl.post(url, opts)
  else
    return nil, "Unsupported HTTP method: " .. method
  end

  if response.status >= 200 and response.status < 300 then
    local ok, data = pcall(vim.json.decode, response.body)
    if ok then
      return data, nil
    else
      return response.body, nil
    end
  else
    local error_msg = string.format("HTTP %d: %s", response.status, response.body or "Unknown error")
    return nil, error_msg
  end
end

-- Puzzle API endpoints
function M.get_daily_puzzle()
  return make_request("GET", "/puzzle/daily")
end

function M.get_next_puzzle()
  return make_request("GET", "/puzzle/next")
end

function M.get_puzzle(puzzle_id)
  return make_request("GET", "/puzzle/" .. puzzle_id)
end

function M.get_puzzle_activity(max, before)
  local query_params = {}
  if max then
    table.insert(query_params, "max=" .. max)
  end
  if before then
    table.insert(query_params, "before=" .. before)
  end

  local query_string = #query_params > 0 and ("?" .. table.concat(query_params, "&")) or ""
  return make_request("GET", "/puzzle/activity" .. query_string)
end

function M.get_puzzle_dashboard(days)
  local query_string = days and ("?days=" .. days) or ""
  return make_request("GET", "/puzzle/dashboard/" .. (days or 30) .. query_string)
end

-- Account API (for authentication validation)
function M.get_account()
  return make_request("GET", "/account")
end

return M
