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
  -- Add cache-busting query parameter
  local timestamp = os.time() .. math.random(1000, 9999)
  local endpoint = "/puzzle/next?t=" .. timestamp

  local result, err = make_request("GET", endpoint)

  -- Debug logging
  local log = io.open("/tmp/nvim-chess-debug.log", "a")
  if log then
    log:write(string.format("[%s] API get_next_puzzle called with endpoint: %s\n", os.date("%Y-%m-%d %H:%M:%S"), endpoint))
    if result and result.puzzle then
      log:write(string.format("[%s] API returned puzzle: %s (rating: %d)\n", os.date("%Y-%m-%d %H:%M:%S"), result.puzzle.id, result.puzzle.rating or 0))
    elseif err then
      log:write(string.format("[%s] API error: %s\n", os.date("%Y-%m-%d %H:%M:%S"), err))
    else
      log:write(string.format("[%s] API returned unexpected response\n", os.date("%Y-%m-%d %H:%M:%S")))
    end
    log:close()
  end

  return result, err
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
