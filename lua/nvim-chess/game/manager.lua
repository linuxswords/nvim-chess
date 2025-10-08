local M = {}

local api = require('nvim-chess.api.client')
local auth = require('nvim-chess.auth.manager')
local ui = require('nvim-chess.ui.board')
local config = require('nvim-chess.config')

-- Active games storage
local active_games = {}
local current_game_id = nil

local function parse_time_control(time_str)
  if not time_str then
    return nil
  end

  local limit, increment = time_str:match("(%d+)%+(%d+)")
  if limit and increment then
    return {
      limit = tonumber(limit) * 60, -- Convert minutes to seconds
      increment = tonumber(increment)
    }
  end

  -- Try just limit without increment
  local limit_only = time_str:match("^(%d+)$")
  if limit_only then
    return {
      limit = tonumber(limit_only) * 60,
      increment = 0
    }
  end

  return nil
end

function M.new_game(time_control)
  if not auth.is_authenticated() then
    vim.notify("Not authenticated. Please set your Lichess token.", vim.log.levels.ERROR)
    return false
  end

  local challenge_opts = {}

  -- Parse time control
  local game_config = config.get_game_config()
  local tc_str = time_control or game_config.default_time_control
  local clock = parse_time_control(tc_str)

  if clock then
    challenge_opts.clock = clock
  end

  local result, error = api.create_challenge(challenge_opts)

  if error then
    vim.notify("Failed to create game: " .. error, vim.log.levels.ERROR)
    return false
  end

  if result and result.challenge then
    local challenge_id = result.challenge.id
    local challenge_url = result.challenge.url
    vim.notify("Challenge created: " .. challenge_url, vim.log.levels.INFO)

    -- TODO: Start monitoring for challenge acceptance
    return challenge_id
  end

  vim.notify("Unexpected response when creating challenge", vim.log.levels.ERROR)
  return false
end

function M.join_game(game_id)
  if not auth.is_authenticated() then
    vim.notify("Not authenticated. Please set your Lichess token.", vim.log.levels.ERROR)
    return false
  end

  local game_data, error = api.get_game(game_id)

  if error then
    vim.notify("Failed to get game: " .. error, vim.log.levels.ERROR)
    return false
  end

  if game_data then
    active_games[game_id] = {
      id = game_id,
      state = game_data,
      buffer = nil
    }
    current_game_id = game_id

    -- Show the board
    local buf = ui.show_board(game_id)
    active_games[game_id].buffer = buf

    -- Update board with current position
    if game_data.fen then
      ui.update_board(buf, game_data.fen)
    end

    -- Start streaming updates for this game
    local streaming = require('nvim-chess.api.streaming')
    streaming.start_game_stream(game_id)

    vim.notify("Joined game: " .. game_id, vim.log.levels.INFO)
    return true
  end

  return false
end

function M.make_move(move, game_id)
  game_id = game_id or current_game_id

  if not game_id then
    vim.notify("No active game", vim.log.levels.ERROR)
    return false
  end

  if not auth.is_authenticated() then
    vim.notify("Not authenticated", vim.log.levels.ERROR)
    return false
  end

  -- Validate move format (basic check)
  if not move:match("^[a-h][1-8][a-h][1-8][qrbn]?$") then
    vim.notify("Invalid move format. Use format like 'e2e4'", vim.log.levels.ERROR)
    return false
  end

  local result, error = api.make_move(game_id, move)

  if error then
    vim.notify("Move failed: " .. error, vim.log.levels.ERROR)
    return false
  end

  vim.notify("Move made: " .. move, vim.log.levels.INFO)
  return true
end

function M.resign_game(game_id)
  game_id = game_id or current_game_id

  if not game_id then
    vim.notify("No active game", vim.log.levels.ERROR)
    return false
  end

  local result, error = api.resign_game(game_id)

  if error then
    vim.notify("Failed to resign: " .. error, vim.log.levels.ERROR)
    return false
  end

  vim.notify("Game resigned", vim.log.levels.INFO)
  M.close_game(game_id)
  return true
end

function M.abort_game(game_id)
  game_id = game_id or current_game_id

  if not game_id then
    vim.notify("No active game", vim.log.levels.ERROR)
    return false
  end

  local result, error = api.abort_game(game_id)

  if error then
    vim.notify("Failed to abort: " .. error, vim.log.levels.ERROR)
    return false
  end

  vim.notify("Game aborted", vim.log.levels.INFO)
  M.close_game(game_id)
  return true
end

function M.close_game(game_id)
  if active_games[game_id] then
    local game = active_games[game_id]
    if game.buffer and vim.api.nvim_buf_is_valid(game.buffer) then
      vim.api.nvim_buf_delete(game.buffer, { force = true })
    end
    active_games[game_id] = nil

    if current_game_id == game_id then
      current_game_id = nil
    end
  end
end

function M.get_active_games()
  return active_games
end

function M.get_current_game()
  return current_game_id and active_games[current_game_id] or nil
end

function M.set_current_game(game_id)
  if active_games[game_id] then
    current_game_id = game_id
    return true
  end
  return false
end

-- Update game state (called from streaming updates)
function M.update_game_state(game_id, state)
  if active_games[game_id] then
    local game = active_games[game_id]
    game.state = vim.tbl_deep_extend("force", game.state or {}, state)

    -- Update board if buffer exists and position changed
    if game.buffer and state.fen then
      ui.update_board(game.buffer, state.fen)
    end

    -- Handle game end
    if state.status and state.status ~= "started" then
      local status_messages = {
        mate = "Checkmate",
        resign = "Resignation",
        stalemate = "Stalemate",
        timeout = "Timeout",
        draw = "Draw",
        aborted = "Game aborted"
      }

      local message = status_messages[state.status] or ("Game ended: " .. state.status)
      if state.winner then
        message = message .. " - " .. state.winner .. " wins"
      end

      vim.notify(message, vim.log.levels.INFO)
    end

    return true
  end
  return false
end

return M