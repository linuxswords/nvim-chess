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

  -- IMPORTANT: Don't send authentication for /puzzle/next
  -- Reason: Authenticated requests return the same puzzle until completion is submitted
  -- via web UI. The API doesn't support submitting completions, so authenticated mode
  -- gets stuck. Unauthenticated mode gives random puzzles each time.
  local opts = {
    headers = {
      ["Accept"] = "application/json",
    },
  }

  return make_request("GET", endpoint, opts)
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

-- NOTE: Currently only used in integration tests
-- TODO: Implement dashboard UI feature to display puzzle statistics
function M.get_puzzle_dashboard(days)
  local query_string = days and ("?days=" .. days) or ""
  return make_request("GET", "/puzzle/dashboard/" .. (days or 30) .. query_string)
end

-- Submit puzzle round result
-- NOTE: Not currently used - Lichess API requires web UI for puzzle completion tracking
-- TODO: Implement if Lichess adds API support for puzzle result submission
-- Params:
--   puzzle_id: The puzzle ID
--   win: boolean - true if solved correctly, false if failed
--   theme: string - puzzle theme (default: "mix" for general training)
function M.submit_puzzle_round(puzzle_id, win, theme)
  if not puzzle_id then
    return nil, "puzzle_id is required"
  end

  theme = theme or "mix"
  local endpoint = string.format("/api/training/complete/%s/%s", theme, puzzle_id)

  -- The endpoint expects a POST with win parameter in the body
  local body = string.format("win=%s", win and "true" or "false")
  local opts = {
    body = body,
    headers = get_headers(),
  }
  opts.headers["Content-Type"] = "application/x-www-form-urlencoded"

  return make_request("POST", endpoint, opts)
end

-- Account API (for authentication validation)
function M.get_account()
  return make_request("GET", "/account")
end

return M
