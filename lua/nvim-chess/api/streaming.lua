local M = {}

local utils = require('nvim-chess.utils')
local game_manager = require('nvim-chess.game.manager')

-- Active streams
local active_streams = {}

local function handle_event_stream_data(data)
  if not data or data == "" then
    return
  end

  local events = utils.split_ndjson(data)
  for _, event in ipairs(events) do
    if event.type == "challenge" then
      M.handle_challenge_event(event.challenge)
    elseif event.type == "gameStart" then
      M.handle_game_start_event(event.game)
    elseif event.type == "gameFinish" then
      M.handle_game_finish_event(event.game)
    end
  end
end

local function handle_game_stream_data(game_id, data)
  if not data or data == "" then
    return
  end

  local events = utils.split_ndjson(data)
  for _, event in ipairs(events) do
    if event.type == "gameState" then
      game_manager.update_game_state(game_id, event)
    elseif event.type == "gameFull" then
      -- Initial game state
      game_manager.update_game_state(game_id, event.state or event)
    elseif event.type == "chatLine" then
      M.handle_chat_message(game_id, event)
    end
  end
end

function M.start_event_stream()
  if active_streams.events then
    return false, "Event stream already active"
  end

  local api = require('nvim-chess.api.client')
  local response = api.stream_incoming_events()

  if not response then
    return false, "Failed to start event stream"
  end

  active_streams.events = {
    response = response,
    buffer = ""
  }

  -- Set up timer to read stream data
  local timer = vim.loop.new_timer()
  timer:start(0, 1000, vim.schedule_wrap(function()
    if not active_streams.events then
      timer:stop()
      timer:close()
      return
    end

    local stream = active_streams.events
    if stream.response and stream.response.body then
      local new_data = stream.response.body
      if new_data and new_data ~= stream.buffer then
        local chunk = new_data:sub(#stream.buffer + 1)
        stream.buffer = new_data
        handle_event_stream_data(chunk)
      end
    end
  end))

  active_streams.events.timer = timer
  return true
end

function M.start_game_stream(game_id)
  if active_streams["game_" .. game_id] then
    return false, "Game stream already active for " .. game_id
  end

  local api = require('nvim-chess.api.client')
  local response = api.stream_game_state(game_id)

  if not response then
    return false, "Failed to start game stream"
  end

  active_streams["game_" .. game_id] = {
    response = response,
    buffer = "",
    game_id = game_id
  }

  -- Set up timer to read stream data
  local timer = vim.loop.new_timer()
  timer:start(0, 500, vim.schedule_wrap(function()
    local stream_key = "game_" .. game_id
    if not active_streams[stream_key] then
      timer:stop()
      timer:close()
      return
    end

    local stream = active_streams[stream_key]
    if stream.response and stream.response.body then
      local new_data = stream.response.body
      if new_data and new_data ~= stream.buffer then
        local chunk = new_data:sub(#stream.buffer + 1)
        stream.buffer = new_data
        handle_game_stream_data(game_id, chunk)
      end
    end
  end))

  active_streams["game_" .. game_id].timer = timer
  return true
end

function M.stop_event_stream()
  if active_streams.events then
    if active_streams.events.timer then
      active_streams.events.timer:stop()
      active_streams.events.timer:close()
    end
    if active_streams.events.response then
      -- Note: plenary curl doesn't have a direct close method
      -- The stream will be cleaned up when the response object is garbage collected
    end
    active_streams.events = nil
    return true
  end
  return false
end

function M.stop_game_stream(game_id)
  local stream_key = "game_" .. game_id
  if active_streams[stream_key] then
    if active_streams[stream_key].timer then
      active_streams[stream_key].timer:stop()
      active_streams[stream_key].timer:close()
    end
    active_streams[stream_key] = nil
    return true
  end
  return false
end

function M.stop_all_streams()
  M.stop_event_stream()
  for key, _ in pairs(active_streams) do
    if key:match("^game_") then
      local game_id = key:sub(6) -- Remove "game_" prefix
      M.stop_game_stream(game_id)
    end
  end
end

-- Event handlers
function M.handle_challenge_event(challenge)
  if not challenge then
    return
  end

  local challenger = challenge.challenger
  local time_control = ""

  if challenge.timeControl then
    if challenge.timeControl.limit then
      time_control = math.floor(challenge.timeControl.limit / 60) .. "+"
      time_control = time_control .. (challenge.timeControl.increment or 0)
    else
      time_control = challenge.timeControl.type or "unlimited"
    end
  end

  local message = string.format(
    "Challenge from %s (%s) - %s - %s",
    challenger.name or "Unknown",
    challenger.title or "",
    time_control,
    challenge.rated and "Rated" or "Casual"
  )

  vim.notify(message, vim.log.levels.INFO)

  -- Auto-accept if configured
  local config = require('nvim-chess.config')
  if config.get_game_config().auto_accept_challenges then
    local api = require('nvim-chess.api.client')
    api.accept_challenge(challenge.id)
  end
end

function M.handle_game_start_event(game)
  if not game then
    return
  end

  local message = "Game started: " .. game.id
  vim.notify(message, vim.log.levels.INFO)

  -- Auto-join the game
  game_manager.join_game(game.id)
  M.start_game_stream(game.id)
end

function M.handle_game_finish_event(game)
  if not game then
    return
  end

  local message = "Game finished: " .. game.id
  vim.notify(message, vim.log.levels.INFO)

  M.stop_game_stream(game.id)
end

function M.handle_chat_message(game_id, chat)
  if not chat or not chat.text then
    return
  end

  local username = chat.username or "System"
  local message = string.format("[%s] %s: %s", game_id, username, chat.text)
  vim.notify(message, vim.log.levels.INFO)
end

function M.get_active_streams()
  return active_streams
end

return M