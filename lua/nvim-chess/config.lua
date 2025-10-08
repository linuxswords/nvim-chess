local M = {}

local defaults = {
  lichess = {
    token = nil,
    timeout = 30000,
    base_url = "https://lichess.org/api",
  },
  ui = {
    board_style = "unicode", -- "unicode" or "ascii"
    auto_refresh = true,
    show_coordinates = true,
    highlight_last_move = true,
  },
  game = {
    auto_accept_challenges = false,
    default_time_control = "10+0", -- 10 minutes + 0 increment
  }
}

local config = {}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Validate configuration
  if config.ui.board_style ~= "unicode" and config.ui.board_style ~= "ascii" then
    vim.notify("Invalid board_style. Using 'unicode'", vim.log.levels.WARN)
    config.ui.board_style = "unicode"
  end
end

function M.get()
  return config
end

function M.get_lichess_config()
  return config.lichess
end

function M.get_ui_config()
  return config.ui
end

function M.get_game_config()
  return config.game
end

return M