-- Buffer management utilities for nvim-chess
local M = {}

-- Create or get an existing buffer by name
-- @param name string: The buffer name
-- @param opts table: Optional buffer options
--   - buftype: string (default: "nofile")
--   - bufhidden: string (default: "hide")
--   - swapfile: boolean (default: false)
--   - modifiable: boolean (default: nil, not set)
-- @return number: Buffer handle
function M.create_or_get(name, opts)
	opts = opts or {}

	local existing_buf = vim.fn.bufnr(name)

	local buf
	if existing_buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, name)
	else
		buf = existing_buf
	end

	-- Set buffer options
	vim.api.nvim_set_option_value("buftype", opts.buftype or "nofile", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", opts.bufhidden or "hide", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", opts.swapfile ~= nil and opts.swapfile or false, { buf = buf })

	if opts.modifiable ~= nil then
		vim.api.nvim_set_option_value("modifiable", opts.modifiable, { buf = buf })
	end

	return buf
end

-- Set buffer content (handles modifiable state automatically)
-- @param buf number: Buffer handle
-- @param lines table: Array of lines to set
function M.set_lines(buf, lines)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

-- Show buffer in a window (create new split if not visible)
-- @param buf number: Buffer handle
-- @return number: Window handle
function M.show_in_window(buf)
	local win = vim.fn.bufwinid(buf)

	if win == -1 then
		-- Buffer not visible, create new split
		vim.cmd("split")
		vim.api.nvim_win_set_buf(0, buf)
		return vim.api.nvim_get_current_win()
	else
		-- Buffer already visible, switch to it
		vim.api.nvim_set_current_win(win)
		return win
	end
end

return M
