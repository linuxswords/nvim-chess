-- Puzzle manager - Coordinates puzzle modules
-- Handles API interactions and delegates to specialized modules
local M = {}

local api = require("nvim-chess.api.client")
local auth = require("nvim-chess.auth.manager")
local pgn_converter = require("nvim-chess.chess.pgn_converter")
local buffer = require("nvim-chess.utils.buffer")
local state = require("nvim-chess.puzzle.state")
local solver = require("nvim-chess.puzzle.solver")
local renderer = require("nvim-chess.puzzle.renderer")

-- Helper function to get FEN from game PGN
local function get_fen_from_game(game_data, initial_ply)
	if not game_data or not game_data.pgn then
		return nil
	end

	local target_ply = (initial_ply or 0) + 1
	local fen, err = pgn_converter.pgn_to_fen(game_data.pgn, target_ply)

	if not fen then
		vim.notify("Warning: Could not generate FEN from PGN: " .. (err or "unknown error"), vim.log.levels.WARN)
		return nil
	end

	return fen
end

-- Parse puzzle data from API response
local function parse_puzzle(puzzle_data, game_data)
	if not puzzle_data then
		return nil
	end

	-- Get FEN
	local fen = puzzle_data.fen or get_fen_from_game(game_data, puzzle_data.initialPly)

	-- Determine player color from FEN
	local player_color = "White"
	if fen then
		local parts = {}
		for part in fen:gmatch("%S+") do
			table.insert(parts, part)
		end
		if #parts >= 2 then
			player_color = parts[2] == "w" and "White" or "Black"
		end
	end

	return {
		id = puzzle_data.id,
		fen = fen,
		rating = puzzle_data.rating,
		plays = puzzle_data.plays,
		themes = puzzle_data.themes or {},
		solution = puzzle_data.solution or {},
		initial_ply = puzzle_data.initialPly or 0,
		current_move_index = 0,
		moves_made = {},
		completed = false,
		success = nil,
		pgn = game_data and game_data.pgn,
		game_id = game_data and game_data.id,
		player_color = player_color,
	}
end

-- Get daily puzzle
function M.get_daily_puzzle()
	local puzzle_data, error = api.get_daily_puzzle()

	if error then
		vim.notify("✗ Failed to get daily puzzle: " .. error, vim.log.levels.ERROR)
		return false
	end

	if puzzle_data and puzzle_data.puzzle then
		local puzzle = parse_puzzle(puzzle_data.puzzle, puzzle_data.game)
		state.set_current(puzzle)

		vim.notify(string.format("🧩 Daily Puzzle (Rating: %d)", puzzle.rating), vim.log.levels.INFO)
		M.show_puzzle()
		return true
	end

	return false
end

-- Get next training puzzle
function M.get_next_puzzle(skip_confirmation)
	local current = state.get_current()

	-- Check if there's an unsolved puzzle
	if current and not current.completed and not skip_confirmation then
		local response = vim.fn.input("Current puzzle is not solved. Skip and mark as failed locally? (y/N): ")
		if response:lower() ~= "y" then
			vim.notify("📌 Staying on current puzzle", vim.log.levels.INFO)
			return false
		end

		-- Mark as failed
		current.completed = true
		current.success = false
		state.add_to_history({
			id = current.id,
			success = false,
			moves = vim.deepcopy(current.moves_made),
			skipped = true,
		})
		vim.notify("⏭️  Puzzle skipped (tracked locally only)", vim.log.levels.WARN)
	end

	local puzzle_data, error = api.get_next_puzzle()

	if error then
		vim.notify("✗ Failed to get puzzle: " .. error, vim.log.levels.ERROR)
		return false
	end

	if puzzle_data and puzzle_data.puzzle then
		local puzzle = parse_puzzle(puzzle_data.puzzle, puzzle_data.game)
		state.set_current(puzzle)

		vim.notify(string.format("🧩 New Puzzle (Rating: %d)", puzzle.rating), vim.log.levels.INFO)
		M.show_puzzle()
		return true
	end

	return false
end

-- Get specific puzzle by ID
function M.get_puzzle(puzzle_id)
	local puzzle_data, error = api.get_puzzle(puzzle_id)

	if error then
		vim.notify("✗ Failed to get puzzle: " .. error, vim.log.levels.ERROR)
		return false
	end

	if puzzle_data and puzzle_data.puzzle then
		local puzzle = parse_puzzle(puzzle_data.puzzle, puzzle_data.game)
		state.set_current(puzzle)

		vim.notify(string.format("🧩 Puzzle %s (Rating: %d)", puzzle_id, puzzle.rating), vim.log.levels.INFO)
		M.show_puzzle()
		return true
	end

	return false
end

-- Show puzzle board
function M.show_puzzle()
	local current_puzzle = state.get_current()
	if not current_puzzle then
		vim.notify("No active puzzle", vim.log.levels.ERROR)
		return false
	end

	-- Create buffer and render
	local buf = renderer.create_puzzle_buffer(current_puzzle.id)
	local display_lines = renderer.render_puzzle(current_puzzle, buf)
	buffer.set_lines(buf, display_lines)

	-- Setup keymaps
	renderer.setup_keymaps(buf, {
		on_move = M.attempt_move,
		on_hint = M.show_hint,
		on_solution = M.show_solution,
		on_next = M.get_next_puzzle,
		on_refresh = M.show_puzzle,
	})

	-- Show in window
	local old_buf = current_puzzle.buffer
	renderer.show_in_window(buf, old_buf)

	current_puzzle.buffer = buf
	return buf
end

-- Attempt a move on the puzzle
function M.attempt_move(move)
	local current_puzzle = state.get_current()
	if not current_puzzle then
		vim.notify("✗ No active puzzle", vim.log.levels.ERROR)
		return false
	end

	-- Validate move format
	if not move:match("^[a-h][1-8][a-h][1-8][qrbn]?$") then
		vim.notify("✗ Invalid move format. Use format like 'e2e4'", vim.log.levels.ERROR)
		return false
	end

	-- Apply move
	local updated_puzzle, success, message = solver.apply_move(current_puzzle, move)
	state.set_current(updated_puzzle)

	if not success then
		-- Wrong move or error
		state.add_to_history({
			id = updated_puzzle.id,
			success = false,
			moves = vim.deepcopy(updated_puzzle.moves_made),
		})

		local expected = updated_puzzle.solution[#updated_puzzle.moves_made + 1]
		vim.notify("✗ Wrong move! Expected: " .. expected .. ". Press 's' for solution.", vim.log.levels.ERROR)
		return false
	end

	-- Correct move
	M.show_puzzle() -- Refresh display

	if updated_puzzle.completed then
		-- Puzzle solved!
		state.add_to_history({
			id = updated_puzzle.id,
			success = true,
			moves = vim.deepcopy(updated_puzzle.moves_made),
		})
		vim.notify("🎉 Puzzle solved! Press '>' for next puzzle.", vim.log.levels.INFO)
	else
		vim.notify("✓ Correct! Continue...", vim.log.levels.INFO)

		-- Auto-play opponent's response
		local opponent_puzzle, opponent_move, err = solver.apply_opponent_move(updated_puzzle)
		if opponent_move then
			state.set_current(opponent_puzzle)
			vim.notify("🤖 Opponent plays: " .. opponent_move, vim.log.levels.INFO)
			M.show_puzzle() -- Refresh with opponent's move
		elseif err then
			vim.notify("⚠️  Could not apply opponent move: " .. err, vim.log.levels.WARN)
		end
	end

	return true
end

-- Show hint
function M.show_hint()
	local current_puzzle = state.get_current()
	if not current_puzzle then
		vim.notify("✗ No active puzzle", vim.log.levels.ERROR)
		return
	end

	if current_puzzle.completed then
		vim.notify("⚠️  Puzzle already completed", vim.log.levels.WARN)
		return
	end

	local from, to, err = solver.get_hint(current_puzzle)
	if err then
		vim.notify("⚠️  " .. err, vim.log.levels.WARN)
	elseif from and to then
		vim.notify(string.format("💡 Hint: Move from %s to %s", from, to), vim.log.levels.INFO)
	end
end

-- Show full solution
function M.show_solution()
	local current_puzzle = state.get_current()
	if not current_puzzle then
		vim.notify("✗ No active puzzle", vim.log.levels.ERROR)
		return
	end

	local solution_str = solver.get_solution_string(current_puzzle)
	vim.notify("📖 Solution: " .. solution_str, vim.log.levels.INFO)

	solver.mark_given_up(current_puzzle)
	state.set_current(current_puzzle)
end

-- Submit solution to Lichess (placeholder)
function M.submit_solution()
	if not auth.is_authenticated() then
		return false
	end

	if not state.has_current() then
		return false
	end

	-- This would call API if implemented
	return true
end

-- Get puzzle activity/history
function M.get_puzzle_activity()
	if not auth.is_authenticated() then
		vim.notify("🔒 Authentication required for puzzle activity", vim.log.levels.ERROR)
		return false
	end

	local activity, error = api.get_puzzle_activity()

	if error then
		vim.notify("✗ Failed to get puzzle activity: " .. error, vim.log.levels.ERROR)
		return false
	end

	if activity then
		local buf = buffer.create_or_get("puzzle-activity")
		local lines = { "Puzzle Activity:", "================", "" }

		for _, entry in ipairs(activity) do
			table.insert(
				lines,
				string.format("Puzzle #%s - %s - Rating: %d", entry.id, entry.win and "Solved" or "Failed", entry.rating or 0)
			)
		end

		buffer.set_lines(buf, lines)
		buffer.show_in_window(buf)
		return true
	end

	return false
end

-- Get current puzzle
function M.get_current_puzzle()
	return state.get_current()
end

-- Get puzzle history
function M.get_history()
	return state.get_history()
end

return M
