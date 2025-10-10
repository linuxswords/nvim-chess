local M = {}

local config = require('nvim-chess.config')
local auth = require('nvim-chess.auth.manager')

M.setup = function(opts)
  config.setup(opts or {})

  -- Initialize authentication with configured token
  if config.get().lichess.token then
    auth.set_token(config.get().lichess.token)
  end
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