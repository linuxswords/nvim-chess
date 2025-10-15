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

	-- Board square highlights (classic wood style)
	-- Light squares: cream/tan background
	vim.api.nvim_set_hl(0, "ChessLightSquare", { bg = "#F0D9B5", ctermbg = 223 })
	-- Dark squares: saddle brown background
	vim.api.nvim_set_hl(0, "ChessDarkSquare", { bg = "#8B4513", ctermbg = 94 })

	-- Last move highlighting (gold blended with square colors)
	-- Light squares with last move: cream + gold blend
	vim.api.nvim_set_hl(0, "ChessLastMoveLight", { bg = "#F4D9A7", ctermbg = 222 })
	-- Dark squares with last move: brown + gold blend
	vim.api.nvim_set_hl(0, "ChessLastMoveDark", { bg = "#B07B3F", ctermbg = 136 })
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

-- Convert algebraic notation (e.g., "e4") to rank and file numbers
-- @param square string: Algebraic notation like "e4"
-- @return number, number: rank (1-8), file (1-8)
local function parse_square(square)
	if not square or #square < 2 then
		return nil, nil
	end
	local file = string.byte(square, 1) - string.byte("a") + 1
	local rank = tonumber(square:sub(2, 2))
	return rank, file
end

-- Apply syntax highlighting to chess pieces in buffer
-- @param buf number: Buffer handle
-- @param board_data table: 2D array of pieces
-- @param should_flip boolean: Whether board is flipped
-- @param last_move table|nil: Optional last move { from = "e2", to = "e4" }
local function apply_board_highlights(buf, board_data, should_flip, last_move)
	-- Clear existing highlights
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

	-- Parse last move if provided
	local last_move_squares = {}
	if last_move then
		local from_rank, from_file = parse_square(last_move.from)
		local to_rank, to_file = parse_square(last_move.to)
		if from_rank and from_file then
			last_move_squares[from_rank .. "," .. from_file] = true
		end
		if to_rank and to_file then
			last_move_squares[to_rank .. "," .. to_file] = true
		end
	end

	-- Board structure (no border):
	-- Line 0: file labels
	-- Lines 1-8: ranks 1-8
	-- Line 9: file labels

	for rank_idx = 1, 8 do
		local actual_rank = should_flip and rank_idx or (9 - rank_idx)
		local line_num = rank_idx -- Lines 1-8 (0-indexed)

		for file_idx = 1, 8 do
			local file = should_flip and (9 - file_idx) or file_idx
			local piece = board_data[actual_rank] and board_data[actual_rank][file]

			-- Board format: "8 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜  8"
			-- Position: rank_num(1) + space(1) + squares...
			-- Each square: piece_char (3 bytes for UTF-8 or 1 space) + separator space
			-- UTF-8 byte lengths: chess pieces = 3 bytes, space = 1 byte

			-- Calculate byte position by counting bytes from start of line
			local byte_pos = 2 -- Start after "8 "

			-- Count bytes up to this file position
			for f = 1, file_idx - 1 do
				local prev_file = should_flip and (9 - f) or f
				local prev_piece = board_data[actual_rank] and board_data[actual_rank][prev_file]
				if prev_piece then
					byte_pos = byte_pos + 3 + 1 -- 3 bytes for UTF-8 chess piece + 1 space
				else
					byte_pos = byte_pos + 1 + 1 -- 1 byte for space + 1 separator space
				end
			end

			-- Check if this square was part of the last move
			local is_last_move = last_move_squares[actual_rank .. "," .. file]

			-- Determine square color for background
			local is_light = (actual_rank + file) % 2 == 0
			local bg_hl_group
			if is_last_move then
				bg_hl_group = is_light and "ChessLastMoveLight" or "ChessLastMoveDark"
			else
				bg_hl_group = is_light and "ChessLightSquare" or "ChessDarkSquare"
			end

			if piece then
				-- Highlight the piece character with both piece color and square background
				local piece_hl_group = piece.color == "white" and "ChessWhitePiece" or "ChessBlackPiece"
				-- Apply background to the entire square (piece + space after it)
				vim.api.nvim_buf_add_highlight(buf, -1, bg_hl_group, line_num, byte_pos, byte_pos + 4)
				-- Apply piece color on top
				vim.api.nvim_buf_add_highlight(buf, -1, piece_hl_group, line_num, byte_pos, byte_pos + 3)
			else
				-- Highlight empty square background (2 spaces)
				vim.api.nvim_buf_add_highlight(buf, -1, bg_hl_group, line_num, byte_pos, byte_pos + 2)
			end
		end
	end
end

-- Render a chess board from board position data
-- @param board_data table: 2D array of pieces
-- @param should_flip boolean: Whether to flip board (for black's perspective)
-- @return table: Array of rendered lines
local function render_board(board_data, should_flip)
	-- Using filled chess pieces - will be colored via foreground color
	local pieces = {
		white = { king = "♚", queen = "♛", rook = "♜", bishop = "♝", knight = "♞", pawn = "♟" },
		black = { king = "♚", queen = "♛", rook = "♜", bishop = "♝", knight = "♞", pawn = "♟" },
	}

	local lines = {}
	local file_labels = should_flip and "  h g f e d c b a" or "  a b c d e f g h"
	table.insert(lines, file_labels)

	for rank_idx = 1, 8 do
		local actual_rank = should_flip and rank_idx or (9 - rank_idx)
		local line = tostring(actual_rank) .. " "

		for file_idx = 1, 8 do
			local file = should_flip and (9 - file_idx) or file_idx
			local piece = board_data[actual_rank] and board_data[actual_rank][file]

			if piece then
				line = line .. pieces[piece.color][piece.type] .. " "
			else
				-- Empty square - use space, background color will distinguish light/dark
				line = line .. "  "
			end
		end

		line = line .. " " .. tostring(actual_rank)
		table.insert(lines, line)
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
	local target_width = 20 -- Visual width of board (including rank labels)

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
-- @param board_state table: Board state with position, should_flip, and optional last_move
function M.apply_puzzle_highlights(buf, board_state)
	if board_state and board_state.position then
		apply_board_highlights(buf, board_state.position, board_state.should_flip, board_state.last_move)
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
