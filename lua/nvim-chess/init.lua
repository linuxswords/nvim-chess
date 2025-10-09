local M = {}

local config = require('nvim-chess.config')
local api = require('nvim-chess.api.client')
local ui = require('nvim-chess.ui.board')
local auth = require('nvim-chess.auth.manager')

M.setup = function(opts)
  config.setup(opts or {})

  -- Initialize authentication with configured token
  if config.get().lichess.token then
    auth.set_token(config.get().lichess.token)

    -- Optionally validate token on setup
    -- Uncomment to validate immediately:
    -- auth.validate_token()
  end
end

M.new_game = function(time_control)
  return require('nvim-chess.game.manager').new_game(time_control)
end

M.seek_game = function(time_control)
  return require('nvim-chess.game.manager').seek_game(time_control)
end

M.join_game = function(game_id)
  return require('nvim-chess.game.manager').join_game(game_id)
end

M.show_board = function(game_id)
  ui.show_board(game_id)
end

M.make_move = function(move)
  return require('nvim-chess.game.manager').make_move(move)
end

M.get_profile = function()
  if not auth.is_authenticated() then
    vim.notify("Not authenticated. Please set your Lichess token.", vim.log.levels.ERROR)
    return false
  end

  local profile, error = api.get_profile()
  if error then
    vim.notify("Failed to get profile: " .. error, vim.log.levels.ERROR)
    return false
  end

  if profile then
    -- Display profile information
    local lines = {
      "Lichess Profile:",
      "================",
      "Username: " .. (profile.username or "N/A"),
      "Title: " .. (profile.title or "None"),
      "Online: " .. (profile.online and "Yes" or "No"),
      ""
    }

    if profile.perfs then
      table.insert(lines, "Ratings:")
      for variant, perf in pairs(profile.perfs) do
        if perf.rating then
          table.insert(lines, "  " .. variant .. ": " .. perf.rating .. " (" .. (perf.games or 0) .. " games)")
        end
      end
    end

    if profile.count then
      table.insert(lines, "")
      table.insert(lines, "Game Counts:")
      table.insert(lines, "  Total: " .. (profile.count.all or 0))
      table.insert(lines, "  Rated: " .. (profile.count.rated or 0))
      table.insert(lines, "  Wins: " .. (profile.count.win or 0))
      table.insert(lines, "  Losses: " .. (profile.count.loss or 0))
      table.insert(lines, "  Draws: " .. (profile.count.draw or 0))
    end

    -- Create/update profile buffer
    local buf_name = "lichess-profile"
    local existing_buf = vim.fn.bufnr(buf_name)

    local buf
    if existing_buf == -1 then
      buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, buf_name)
    else
      buf = existing_buf
    end

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

    -- Update buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Open in new window if not already visible
    local win = vim.fn.bufwinid(buf)
    if win == -1 then
      vim.cmd('split')
      vim.api.nvim_win_set_buf(0, buf)
    else
      vim.api.nvim_set_current_win(win)
    end

    return profile
  end

  return false
end

-- Puzzle functions
M.daily_puzzle = function()
  return require('nvim-chess.puzzle.manager').get_daily_puzzle()
end

M.next_puzzle = function()
  return require('nvim-chess.puzzle.manager').get_next_puzzle()
end

M.get_puzzle = function(puzzle_id)
  return require('nvim-chess.puzzle.manager').get_puzzle(puzzle_id)
end

M.puzzle_activity = function()
  return require('nvim-chess.puzzle.manager').get_puzzle_activity()
end

-- Authentication functions
M.authenticate = function(token)
  -- First, try to use configured token if no token provided
  if not token or token == "" then
    local configured_token = config.get().lichess.token

    if configured_token and configured_token ~= "" then
      -- Use configured token
      token = configured_token
      vim.notify("Using configured token...", vim.log.levels.INFO)
    else
      -- Prompt user for token
      local input_token = vim.fn.input({
        prompt = "Enter Lichess API token: ",
        cancelreturn = nil
      })

      if not input_token or input_token == "" then
        vim.notify("Authentication cancelled", vim.log.levels.WARN)
        return false
      end

      token = input_token
    end
  end

  -- Set the token
  auth.set_token(token)

  -- Validate token by fetching profile
  vim.notify("Validating token...", vim.log.levels.INFO)
  local valid, error = auth.validate_token()

  if valid then
    local profile = auth.get_user_profile()
    local username = profile and profile.username or "Unknown"
    vim.notify(string.format("✓ Authenticated as %s", username), vim.log.levels.INFO)
    return true
  else
    auth.clear_session()
    vim.notify(string.format("✗ Authentication failed: %s", error or "Invalid token"), vim.log.levels.ERROR)
    return false
  end
end

M.logout = function()
  auth.clear_session()
  vim.notify("Logged out from Lichess", vim.log.levels.INFO)
  return true
end

M.status = function()
  if auth.is_authenticated() then
    local profile = auth.get_user_profile()
    if profile then
      vim.notify(string.format("Authenticated as %s", profile.username), vim.log.levels.INFO)
    else
      vim.notify("Authenticated (profile not loaded)", vim.log.levels.INFO)
    end
    return true
  else
    vim.notify("Not authenticated. Use :ChessAuthenticate to login.", vim.log.levels.WARN)
    return false
  end
end

return M