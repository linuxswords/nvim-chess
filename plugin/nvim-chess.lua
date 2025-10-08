if vim.g.loaded_nvim_chess then
  return
end
vim.g.loaded_nvim_chess = 1

-- Check dependencies
if not pcall(require, 'plenary') then
  vim.notify("nvim-chess requires plenary.nvim", vim.log.levels.ERROR)
  return
end

-- Define user commands
vim.api.nvim_create_user_command("ChessNewGame", function(opts)
  local time_control = opts.args ~= "" and opts.args or nil
  require('nvim-chess').new_game(time_control)
end, {
  nargs = "?",
  desc = "Create a new chess game with optional time control (e.g., '10+0')"
})

vim.api.nvim_create_user_command("ChessJoinGame", function(opts)
  if opts.args == "" then
    vim.notify("Game ID required", vim.log.levels.ERROR)
    return
  end
  require('nvim-chess').join_game(opts.args)
end, {
  nargs = 1,
  desc = "Join an existing chess game by ID"
})

vim.api.nvim_create_user_command("ChessShowBoard", function(opts)
  local game_id = opts.args ~= "" and opts.args or nil
  require('nvim-chess').show_board(game_id)
end, {
  nargs = "?",
  desc = "Show chess board for current or specified game"
})

vim.api.nvim_create_user_command("ChessMove", function(opts)
  if opts.args == "" then
    vim.notify("Move required (e.g., 'e2e4')", vim.log.levels.ERROR)
    return
  end
  require('nvim-chess').make_move(opts.args)
end, {
  nargs = 1,
  desc = "Make a chess move (e.g., 'e2e4')"
})

vim.api.nvim_create_user_command("ChessProfile", function()
  require('nvim-chess').get_profile()
end, {
  desc = "Show Lichess profile information"
})

vim.api.nvim_create_user_command("ChessResign", function()
  require('nvim-chess.game.manager').resign_game()
end, {
  desc = "Resign the current game"
})

vim.api.nvim_create_user_command("ChessAbort", function()
  require('nvim-chess.game.manager').abort_game()
end, {
  desc = "Abort the current game"
})

vim.api.nvim_create_user_command("ChessStartStreaming", function()
  local streaming = require('nvim-chess.api.streaming')
  local success, error = streaming.start_event_stream()
  if not success then
    vim.notify("Failed to start streaming: " .. (error or "unknown"), vim.log.levels.ERROR)
  else
    vim.notify("Started event streaming", vim.log.levels.INFO)
  end
end, {
  desc = "Start streaming Lichess events"
})

vim.api.nvim_create_user_command("ChessStopStreaming", function()
  local streaming = require('nvim-chess.api.streaming')
  streaming.stop_all_streams()
  vim.notify("Stopped all streaming", vim.log.levels.INFO)
end, {
  desc = "Stop all streaming connections"
})