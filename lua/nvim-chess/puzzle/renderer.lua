-- Puzzle board rendering and display
-- Handles visual representation of puzzles
local M = {}

local engine = require("nvim-chess.chess.engine")
local buffer = require("nvim-chess.utils.buffer")

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
				local is_light = (actual_rank + file) % 2 == 0
				line = line .. (is_light and "·" or " ") .. " "
			end
		end

		line = line .. " " .. tostring(actual_rank)
		table.insert(lines, line)
	end

	table.insert(lines, file_labels)
	return lines
end

-- Create info panel for puzzle
-- @param puzzle table: Puzzle data
-- @return table: Array of info panel lines
local function create_info_panel(puzzle)
	local info_panel = {
		"┌─ 🧩 LICHESS PUZZLE ─────────┐",
		"│                             │",
		"│ ID:     " .. string.format("%-18s", puzzle.id) .. "│",
		"│ Rating: " .. string.format("%-18s", tostring(puzzle.rating)) .. "│",
		"│ Plays:  " .. string.format("%-18s", tostring(puzzle.plays or "N/A")) .. "│",
		"│                             │",
		"│ Task: " .. string.format("%-20s", "Find best move") .. "│",
		"│       " .. string.format("%-20s", "for " .. puzzle.player_color) .. "│",
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
	for i = 1, math.max(#board_lines, #info_panel) do
		local board_part = board_lines[i] or string.rep(" ", 20)
		local info_part = info_panel[i] or ""
		table.insert(display_lines, board_part .. "   " .. info_part)
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
function M.render_puzzle(puzzle)
	if not puzzle.fen then
		return create_fallback_display(puzzle)
	end

	local board_state = engine.create_board_from_fen(puzzle.fen)
	if not board_state or not board_state.position then
		return create_fallback_display(puzzle)
	end

	local player_color = puzzle.player_color or "White"
	local should_flip = player_color == "Black"

	local board_lines = render_board(board_state.position, should_flip)
	local info_panel = create_info_panel(puzzle)

	return combine_side_by_side(board_lines, info_panel)
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
