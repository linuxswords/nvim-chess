-- Puzzle solving logic
-- Handles move validation, puzzle progression, and solution checking
local M = {}

local engine = require("nvim-chess.chess.engine")
local move_executor = require("nvim-chess.chess.move_executor")

-- Helper function to apply a UCI move to a FEN position
-- Returns updated FEN or nil on error
local function apply_uci_move_to_fen(fen, uci_move)
	if not fen or not uci_move then
		return nil, "Invalid parameters"
	end

	local board_state, err = engine.create_board_from_fen(fen)
	if not board_state then
		return nil, "Failed to parse FEN: " .. (err or "unknown error")
	end

	local updated_state, move_err = move_executor.execute_uci_move(board_state, uci_move)
	if not updated_state then
		return nil, "Failed to execute move: " .. (move_err or "unknown error")
	end

	return engine.board_to_fen(updated_state)
end

-- Validate if a move is the expected move in the solution
function M.is_correct_move(puzzle, move)
	local expected = puzzle.solution[puzzle.current_move_index + 1]
	return move == expected
end

-- Check if puzzle is complete
function M.is_complete(puzzle)
	return puzzle.current_move_index >= #puzzle.solution
end

-- Apply a player move to the puzzle
-- Returns updated puzzle and success flag
function M.apply_move(puzzle, move)
	if puzzle.completed then
		return puzzle, false, "Puzzle already completed"
	end

	if not M.is_correct_move(puzzle, move) then
		puzzle.completed = true
		puzzle.success = false
		return puzzle, false, "Incorrect move"
	end

	-- Correct move - update puzzle state
	puzzle.current_move_index = puzzle.current_move_index + 1
	table.insert(puzzle.moves_made, move)

	-- Update FEN
	local new_fen, err = apply_uci_move_to_fen(puzzle.fen, move)
	if new_fen then
		puzzle.fen = new_fen
	else
		return puzzle, false, err
	end

	-- Check if puzzle is complete
	if M.is_complete(puzzle) then
		puzzle.completed = true
		puzzle.success = true
		return puzzle, true, "Puzzle solved!"
	end

	return puzzle, true, nil
end

-- Apply opponent's response move
-- Returns updated puzzle or nil on error
function M.apply_opponent_move(puzzle)
	if puzzle.current_move_index >= #puzzle.solution then
		return puzzle, nil -- No more moves
	end

	local opponent_move = puzzle.solution[puzzle.current_move_index + 1]
	puzzle.current_move_index = puzzle.current_move_index + 1

	-- Update FEN
	local new_fen, err = apply_uci_move_to_fen(puzzle.fen, opponent_move)
	if new_fen then
		puzzle.fen = new_fen
		return puzzle, opponent_move
	else
		return puzzle, nil, err
	end
end

-- Get hint for next move
-- Returns from and to squares
function M.get_hint(puzzle)
	if puzzle.completed then
		return nil, nil, "Puzzle already completed"
	end

	local next_move = puzzle.solution[puzzle.current_move_index + 1]
	if not next_move then
		return nil, nil, "No moves available"
	end

	local from = next_move:sub(1, 2)
	local to = next_move:sub(3, 4)
	return from, to
end

-- Get full solution as string
function M.get_solution_string(puzzle)
	return table.concat(puzzle.solution, " → ")
end

-- Mark puzzle as given up (shown solution)
function M.mark_given_up(puzzle)
	puzzle.completed = true
	puzzle.success = false
	return puzzle
end

return M
