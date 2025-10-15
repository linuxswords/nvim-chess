-- Puzzle board rendering and display
-- Handles visual representation of puzzles
local M = {}

local engine = require("nvim-chess.chess.engine")
local buffer = require("nvim-chess.utils.buffer")

-- Define highlight groups for chess pieces and squares
local function setup_highlights()
	-- Chess piece highlights
	-- Using both GUI colors (true color) and cterm colors (256-color fallback)
	vim.api.nvim_set_hl(0, "ChessWhitePiece", { fg = "#FFFFFF", ctermfg = 15, bold = true })
	vim.api.nvim_set_hl(0, "ChessBlackPiece", { fg = "#000000", ctermfg = 0, bold = true })

	-- Board square highlights (subtle background)
	-- Light squares: lighter green background
	vim.api.nvim_set_hl(0, "ChessLightSquare", { bg = "#6BCD6B", ctermbg = 77 })
	-- Dark squares: pure black background
	vim.api.nvim_set_hl(0, "ChessDarkSquare", { bg = "#000000", ctermbg = 0 })
end

-- Initialize highlights when module loads
setup_highlights()

-- Re-apply highlights when colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("NvimChessHighlights", { clear = true }),
	callback = function()
		setup_highlights()
	end,
})

-- Apply syntax highlighting to chess pieces in buffer
-- @param buf number: Buffer handle
-- @param board_data table: 2D array of pieces
-- @param should_flip boolean: Whether board is flipped
local function apply_board_highlights(buf, board_data, should_flip)
	-- Clear existing highlights
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

	-- Board structure with square tiles:
	-- Line 0: file labels
	-- Lines 1, 3, 5, 7, 9, 11, 13, 15: ranks 8-1 (with pieces)
	-- Lines 2, 4, 6, 8, 10, 12, 14: empty spacing lines
	-- Line 16: file labels

	for rank_idx = 1, 8 do
		local actual_rank = should_flip and rank_idx or (9 - rank_idx)
		-- Each rank now takes 2 lines (piece line + empty line), except last rank
		local line_num = (rank_idx - 1) * 2 + 1 -- Lines 1, 3, 5, 7, 9, 11, 13, 15
		local spacing_line_num = line_num + 1 -- Lines 2, 4, 6, 8, 10, 12, 14

		for file_idx = 1, 8 do
			local file = should_flip and (9 - file_idx) or file_idx
			local piece = board_data[actual_rank] and board_data[actual_rank][file]

			-- Calculate byte position by counting bytes from start of line
			local byte_pos = 2 -- Start after "8 "

			-- Count bytes up to this file position
			for f = 1, file_idx - 1 do
				local prev_file = should_flip and (9 - f) or f
				local prev_piece = board_data[actual_rank] and board_data[actual_rank][prev_file]
				if prev_piece then
					byte_pos = byte_pos + 1 + 3 + 2 -- space + 3 bytes UTF-8 piece + 2 spaces
				else
					byte_pos = byte_pos + 4 -- 4 spaces
				end
			end

			-- Determine square color for background
			local is_light = (actual_rank + file) % 2 == 0
			local bg_hl_group = is_light and "ChessLightSquare" or "ChessDarkSquare"

			-- Highlight piece line
			if piece then
				-- Highlight the entire 4-character tile
				vim.api.nvim_buf_add_highlight(buf, -1, bg_hl_group, line_num, byte_pos, byte_pos + 6)
				-- Highlight piece character (skip first space, highlight the 3-byte piece)
				local piece_hl_group = piece.color == "white" and "ChessWhitePiece" or "ChessBlackPiece"
				vim.api.nvim_buf_add_highlight(buf, -1, piece_hl_group, line_num, byte_pos + 1, byte_pos + 4)
			else
				-- Highlight empty square (4 spaces)
				vim.api.nvim_buf_add_highlight(buf, -1, bg_hl_group, line_num, byte_pos, byte_pos + 4)
			end

			-- Highlight spacing line (if not last rank)
			if rank_idx < 8 then
				vim.api.nvim_buf_add_highlight(buf, -1, bg_hl_group, spacing_line_num, byte_pos, byte_pos + 4)
			end
		end
	end
end

-- Render a chess board from board position data
-- @param board_data table: 2D array of pieces
-- @param should_flip boolean: Whether to flip board (for black's perspective)
-- @return table: Array of rendered lines
local function render_board(board_data, should_flip)
	local pieces = {
		white = { king = "♚", queen = "♛", rook = "♜", bishop = "♝", knight = "♞", pawn = "♟" },
		black = { king = "♔", queen = "♕", rook = "♖", bishop = "♗", knight = "♘", pawn = "♙" },
	}

	local lines = {}
	local file_labels = should_flip and "   h   g   f   e   d   c   b   a  " or "   a   b   c   d   e   f   g   h  "
	table.insert(lines, file_labels)

	for rank_idx = 1, 8 do
		local actual_rank = should_flip and rank_idx or (9 - rank_idx)
		local line = tostring(actual_rank) .. " "

		for file_idx = 1, 8 do
			local file = should_flip and (9 - file_idx) or file_idx
			local piece = board_data[actual_rank] and board_data[actual_rank][file]

			if piece then
				-- Center piece in 4-character tile: space + piece + space + space
				line = line .. " " .. pieces[piece.color][piece.type] .. "  "
			else
				-- Empty square - 4 spaces for consistent tile width
				line = line .. "    "
			end
		end

		line = line .. " " .. tostring(actual_rank)
		table.insert(lines, line)

		-- Add empty line after each rank (except last) to make tiles square
		if rank_idx < 8 then
			table.insert(lines, "  " .. string.rep("    ", 8))
		end
	end

	table.insert(lines, file_labels)
	return lines
end

-- Pad string to specific visual width
-- @param str string: String to pad
-- @param width number: Target visual width
-- @return string: Padded string
local function pad_to_width(str, width)
	local current_width = vim.fn.strdisplaywidth(str)
	local padding = string.rep(" ", math.max(0, width - current_width))
	return str .. padding
end

-- Create info panel for puzzle
-- @param puzzle table: Puzzle data
-- @return table: Array of info panel lines
local function create_info_panel(puzzle)
	local info_panel = {
		"┌─ 🧩 LICHESS PUZZLE ─────────┐",
		"│                             │",
		"│ ID:     " .. pad_to_width(puzzle.id, 20) .. "│",
		"│ Rating: " .. pad_to_width(tostring(puzzle.rating), 20) .. "│",
		"│ Plays:  " .. pad_to_width(tostring(puzzle.plays or "N/A"), 20) .. "│",
		"│                             │",
		"│ Task: " .. pad_to_width("Find best move", 22) .. "│",
		"│       " .. pad_to_width("for " .. puzzle.player_color, 22) .. "│",
		"│                             │",
		"├─ CONTROLS ──────────────────┤",
		"│ (m) Make move               │",
		"│ (h) Show hint               │",
		"│ (s) Show solution           │",
		"│ (>) Next puzzle             │",
		"│ (q) Quit                    │",
		"└─────────────────────────────┘",
	}

	-- Add moves if any
	if #puzzle.moves_made > 0 then
		table.insert(info_panel, "")
		table.insert(info_panel, "Moves made:")
		table.insert(info_panel, table.concat(puzzle.moves_made, " → "))
	end

	return info_panel
end

-- Combine board and info panel side by side
local function combine_side_by_side(board_lines, info_panel)
	local display_lines = {}
	local target_width = 36 -- Visual width of board (including rank labels)
	-- 2 (rank) + 32 (8 tiles * 4 chars) + 2 (trailing rank + space) = 36

	for i = 1, math.max(#board_lines, #info_panel) do
		local board_part = board_lines[i] or ""
		local info_part = info_panel[i] or ""

		-- Calculate visual width and pad to consistent width
		local visual_width = vim.fn.strdisplaywidth(board_part)
		local padding_needed = target_width - visual_width
		local padding = string.rep(" ", math.max(0, padding_needed))

		table.insert(display_lines, board_part .. padding .. "   " .. info_part)
	end
	return display_lines
end

-- Create fallback display when FEN is unavailable
local function create_fallback_display(puzzle)
	local lines = {
		"⚠ Board display not available",
		"",
	}

	if puzzle.game_id then
		table.insert(lines, "View puzzle on Lichess:")
		table.insert(lines, string.format("https://lichess.org/training/%s", puzzle.id))
		table.insert(lines, "")
		if puzzle.pgn then
			table.insert(lines, "PGN: " .. puzzle.pgn)
		end
	else
		table.insert(lines, "FEN not available from API")
	end

	return lines
end

-- Render complete puzzle display
-- @param puzzle table: Puzzle data
-- @return table: Array of display lines
-- @return table|nil: Board state for highlighting (position and should_flip)
function M.render_puzzle(puzzle)
	if not puzzle.fen then
		return create_fallback_display(puzzle), nil
	end

	local board_state = engine.create_board_from_fen(puzzle.fen)
	if not board_state or not board_state.position then
		return create_fallback_display(puzzle), nil
	end

	local player_color = puzzle.player_color or "White"
	local should_flip = player_color == "Black"

	local board_lines = render_board(board_state.position, should_flip)
	local info_panel = create_info_panel(puzzle)

	local display_lines = combine_side_by_side(board_lines, info_panel)

	-- Return display lines and board state for highlighting
	return display_lines, { position = board_state.position, should_flip = should_flip }
end

-- Apply highlights to a puzzle buffer
-- @param buf number: Buffer handle
-- @param board_state table: Board state with position and should_flip
function M.apply_puzzle_highlights(buf, board_state)
	if board_state and board_state.position then
		apply_board_highlights(buf, board_state.position, board_state.should_flip)
	end
end

-- Create or get puzzle buffer
-- @param puzzle_id string: Puzzle ID
-- @return number: Buffer handle
function M.create_puzzle_buffer(puzzle_id)
	return buffer.create_or_get("puzzle-" .. puzzle_id)
end

-- Setup keymaps for puzzle buffer
-- @param buf number: Buffer handle
-- @param callbacks table: Map of callback functions {on_move, on_hint, on_solution, on_next}
function M.setup_keymaps(buf, callbacks)
	local opts = { buffer = buf, noremap = true, silent = true }

	vim.keymap.set("n", "q", "<cmd>q<cr>", opts)

	vim.keymap.set("n", "m", function()
		local move = vim.fn.input("Enter move (e.g., e2e4): ")
		if move and move ~= "" then
			callbacks.on_move(move)
		end
	end, opts)

	vim.keymap.set("n", "h", callbacks.on_hint, opts)
	vim.keymap.set("n", "s", callbacks.on_solution, opts)
	vim.keymap.set("n", ">", callbacks.on_next, opts)

	vim.keymap.set("n", "<C-r>", function()
		callbacks.on_refresh()
	end, opts)
end

-- Show puzzle in window with smart reuse
-- @param buf number: Buffer handle
-- @param old_puzzle_buf number|nil: Previous puzzle buffer to potentially delete
function M.show_in_window(buf, old_puzzle_buf)
	-- Check if we're already in a puzzle buffer and reuse that window
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_win_get_buf(current_win)
	local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
	local in_puzzle_buffer = current_buf_name:match("puzzle%-")

	local win = vim.fn.bufwinid(buf)

	if win == -1 then
		-- Buffer not visible anywhere
		if in_puzzle_buffer then
			-- Reuse current window
			vim.api.nvim_win_set_buf(current_win, buf)
			vim.api.nvim_set_current_win(current_win)

			-- Delete old puzzle buffer if different
			if old_puzzle_buf and vim.api.nvim_buf_is_valid(old_puzzle_buf) and old_puzzle_buf ~= buf then
				vim.api.nvim_buf_delete(old_puzzle_buf, { force = true })
			end
		else
			-- Create new split
			vim.cmd("split")
			vim.api.nvim_win_set_buf(0, buf)
		end
	else
		-- Buffer already visible, switch to it
		vim.api.nvim_set_current_win(win)
	end
end

return M
