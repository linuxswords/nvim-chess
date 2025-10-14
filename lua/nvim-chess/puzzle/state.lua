-- Puzzle state management
-- Handles current puzzle and history tracking
local M = {}

-- Active puzzle storage
local current_puzzle = nil
local puzzle_history = {}

-- Set the current active puzzle
function M.set_current(puzzle)
	current_puzzle = puzzle
end

-- Get the current active puzzle
function M.get_current()
	return current_puzzle
end

-- Clear the current puzzle
function M.clear_current()
	current_puzzle = nil
end

-- Check if there's an active puzzle
function M.has_current()
	return current_puzzle ~= nil
end

-- Add a puzzle result to history
-- @param result table: {id, success, moves, skipped?, timestamp?}
function M.add_to_history(result)
	local entry = vim.tbl_extend("force", result, {
		timestamp = result.timestamp or os.time(),
	})
	table.insert(puzzle_history, entry)
end

-- Get puzzle history
function M.get_history()
	return puzzle_history
end

-- Clear puzzle history
function M.clear_history()
	puzzle_history = {}
end

-- Get history statistics
function M.get_stats()
	local stats = {
		total = #puzzle_history,
		solved = 0,
		failed = 0,
		skipped = 0,
	}

	for _, entry in ipairs(puzzle_history) do
		if entry.skipped then
			stats.skipped = stats.skipped + 1
		elseif entry.success then
			stats.solved = stats.solved + 1
		else
			stats.failed = stats.failed + 1
		end
	end

	return stats
end

return M
