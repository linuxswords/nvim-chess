if vim.g.loaded_nvim_chess then
  return
end
vim.g.loaded_nvim_chess = 1

-- Check dependencies
if not pcall(require, 'plenary') then
  vim.notify("nvim-chess requires plenary.nvim", vim.log.levels.ERROR)
  return
end

-- Puzzle commands
vim.api.nvim_create_user_command("ChessDailyPuzzle", function()
  require('nvim-chess').daily_puzzle()
end, {
  desc = "Get the daily puzzle from Lichess"
})

vim.api.nvim_create_user_command("ChessNextPuzzle", function()
  require('nvim-chess').next_puzzle()
end, {
  desc = "Get next puzzle (random, or rating-matched with auth)"
})

vim.api.nvim_create_user_command("ChessGetPuzzle", function(opts)
  if opts.args == "" then
    vim.notify("Puzzle ID required", vim.log.levels.ERROR)
    return
  end
  require('nvim-chess').get_puzzle(opts.args)
end, {
  nargs = 1,
  desc = "Get a specific puzzle by ID"
})

vim.api.nvim_create_user_command("ChessPuzzleActivity", function()
  require('nvim-chess').puzzle_activity()
end, {
  desc = "View your puzzle activity history (requires authentication)"
})

-- Version commands
vim.api.nvim_create_user_command("ChessVersion", function()
  require('nvim-chess.version').show_version()
end, {
  desc = "Show nvim-chess version"
})

vim.api.nvim_create_user_command("ChessInfo", function()
  require('nvim-chess.version').show_info()
end, {
  desc = "Show detailed nvim-chess information"
})

-- Authentication commands
vim.api.nvim_create_user_command("ChessAuthenticate", function(opts)
  local token = opts.args ~= "" and opts.args or nil
  require('nvim-chess').authenticate(token)
end, {
  nargs = "?",
  desc = "Authenticate with Lichess (provide token or will prompt)"
})

vim.api.nvim_create_user_command("ChessLogout", function()
  require('nvim-chess').logout()
end, {
  desc = "Logout from Lichess"
})

vim.api.nvim_create_user_command("ChessStatus", function()
  require('nvim-chess').status()
end, {
  desc = "Show authentication status"
})