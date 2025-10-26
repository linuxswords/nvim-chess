local M = {}

local defaults = {
  lichess = {
    token = nil,
    timeout = 30000,
    base_url = "https://lichess.org/api",
  },
  ui = {
    puzzle_window_mode = "reuse",  -- "reuse" to replace current buffer, "split" to always create new window
  },
}

local config = {}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get()
  return config
end

function M.get_lichess_config()
  return config.lichess
end

function M.get_ui_config()
  return config.ui or defaults.ui
end

return M
