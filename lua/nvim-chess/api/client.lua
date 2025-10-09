local M = {}

local curl = require('plenary.curl')
local config = require('nvim-chess.config')
local auth = require('nvim-chess.auth.manager')

local function get_headers()
  local headers = {
    ['User-Agent'] = 'nvim-chess/1.0.0',
    ['Accept'] = 'application/json',
  }

  local token = auth.get_token()
  if token then
    headers['Authorization'] = 'Bearer ' .. token
  end

  return headers
end

local function make_request(method, endpoint, opts)
  opts = opts or {}
  local lichess_config = config.get_lichess_config()
  local url = lichess_config.base_url .. endpoint

  local request_opts = {
    method = method,
    url = url,
    headers = get_headers(),
    timeout = lichess_config.timeout,
  }

  if opts.body then
    request_opts.body = opts.body
    request_opts.headers['Content-Type'] = 'application/json'
  end

  if opts.form then
    request_opts.body = opts.form
    request_opts.headers['Content-Type'] = 'application/x-www-form-urlencoded'
  end

  local response = curl.request(request_opts)

  -- Handle rate limiting
  if response.status == 429 then
    vim.notify("Rate limited by Lichess API. Please wait a moment.", vim.log.levels.WARN)
    return nil, "rate_limited"
  end

  if response.status >= 400 then
    local error_msg = "HTTP " .. response.status
    if response.body then
      local ok, json = pcall(vim.json.decode, response.body)
      if ok and json.error then
        error_msg = json.error
      end
    end
    return nil, error_msg
  end

  if response.body and response.body ~= "" then
    local ok, json = pcall(vim.json.decode, response.body)
    if ok then
      return json, nil
    else
      return response.body, nil
    end
  end

  return {}, nil
end

-- User profile and account
function M.get_profile()
  return make_request('GET', '/account')
end

function M.get_preferences()
  return make_request('GET', '/account/preferences')
end

-- Game creation and management
function M.create_challenge(opts)
  opts = opts or {}
  local form_data = {}

  if opts.username then
    form_data.username = opts.username
  end

  if opts.rated then
    form_data.rated = tostring(opts.rated)
  end

  if opts.clock then
    form_data['clock.limit'] = tostring(opts.clock.limit)
    form_data['clock.increment'] = tostring(opts.clock.increment)
  end

  if opts.color then
    form_data.color = opts.color
  end

  if opts.variant then
    form_data.variant = opts.variant
  end

  local form_string = ""
  for key, value in pairs(form_data) do
    if form_string ~= "" then
      form_string = form_string .. "&"
    end
    form_string = form_string .. key .. "=" .. vim.uri_encode(value)
  end

  -- Try the open challenge endpoint first
  local result, error = make_request('POST', '/challenge/open', { form = form_string })

  if error and error:match("404") then
    -- If that fails, try the regular challenge endpoint
    return make_request('POST', '/challenge', { form = form_string })
  end

  return result, error
end

-- Alternative function to seek a game (simpler approach)
function M.seek_game(opts)
  opts = opts or {}
  local form_data = {}

  if opts.rated ~= nil then
    form_data.rated = tostring(opts.rated)
  end

  if opts.time then
    form_data.time = tostring(opts.time)
  end

  if opts.increment then
    form_data.increment = tostring(opts.increment)
  end

  if opts.variant then
    form_data.variant = opts.variant
  end

  if opts.color then
    form_data.color = opts.color
  end

  local form_string = ""
  for key, value in pairs(form_data) do
    if form_string ~= "" then
      form_string = form_string .. "&"
    end
    form_string = form_string .. key .. "=" .. vim.uri_encode(value)
  end

  return make_request('POST', '/board/seek', { form = form_string })
end

function M.accept_challenge(challenge_id)
  return make_request('POST', '/challenge/' .. challenge_id .. '/accept')
end

function M.decline_challenge(challenge_id, reason)
  local form = reason and ('reason=' .. vim.uri_encode(reason)) or ""
  return make_request('POST', '/challenge/' .. challenge_id .. '/decline', { form = form })
end

-- Game operations
function M.get_game(game_id)
  return make_request('GET', '/game/' .. game_id)
end

function M.make_move(game_id, move, draw_offer)
  local form = 'move=' .. vim.uri_encode(move)
  if draw_offer then
    form = form .. '&offeringDraw=true'
  end
  return make_request('POST', '/board/game/' .. game_id .. '/move', { form = form })
end

function M.resign_game(game_id)
  return make_request('POST', '/board/game/' .. game_id .. '/resign')
end

function M.abort_game(game_id)
  return make_request('POST', '/board/game/' .. game_id .. '/abort')
end

-- Streaming endpoints (these return the curl object for manual handling)
function M.stream_incoming_events()
  local lichess_config = config.get_lichess_config()
  local url = lichess_config.base_url .. '/stream/event'

  return curl.request({
    method = 'GET',
    url = url,
    headers = get_headers(),
    stream = true,
    timeout = 0, -- No timeout for streaming
  })
end

function M.stream_game_state(game_id)
  local lichess_config = config.get_lichess_config()
  local url = lichess_config.base_url .. '/board/game/stream/' .. game_id

  return curl.request({
    method = 'GET',
    url = url,
    headers = get_headers(),
    stream = true,
    timeout = 0, -- No timeout for streaming
  })
end

-- Bot account operations (for bot accounts)
function M.get_ongoing_games()
  return make_request('GET', '/account/playing')
end

function M.upgrade_to_bot()
  return make_request('POST', '/bot/account/upgrade')
end

-- Puzzle operations
function M.get_daily_puzzle()
  return make_request('GET', '/api/puzzle/daily')
end

function M.get_next_puzzle()
  return make_request('GET', '/api/puzzle/next')
end

function M.get_puzzle(puzzle_id)
  return make_request('GET', '/api/puzzle/' .. puzzle_id)
end

function M.get_puzzle_activity(max, before)
  local params = {}
  if max then
    table.insert(params, 'max=' .. tostring(max))
  end
  if before then
    table.insert(params, 'before=' .. tostring(before))
  end
  local query = #params > 0 and ('?' .. table.concat(params, '&')) or ''
  return make_request('GET', '/api/puzzle/activity' .. query)
end

function M.get_puzzle_dashboard(days)
  local query = days and ('?days=' .. tostring(days)) or ''
  return make_request('GET', '/api/puzzle/dashboard' .. query)
end

return M