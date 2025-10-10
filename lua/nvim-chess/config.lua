local M = {}

local defaults = {
  lichess = {
    token = nil,
    timeout = 30000,
    base_url = "https://lichess.org/api",
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

return M
