local M = {}

local api = require('nvim-chess.api.client')
local ui = require('nvim-chess.ui.board')
local auth = require('nvim-chess.auth.manager')

-- Active puzzle storage
local current_puzzle = nil
local puzzle_history = {}

-- Helper function to get FEN from game PGN
-- Since Lichess API doesn't provide FEN directly, we construct it from the game
local function get_fen_from_game(game_data, initial_ply)
  -- For now, we'll use a workaround: fetch FEN from Lichess game viewer
  -- The game ID and ply can be used to construct a URL
  if game_data and game_data.id then
    -- Try to use the game export API with FEN
    local game_url = string.format("https://lichess.org/%s?ply=%d", game_data.id, initial_ply or 0)
    -- Note: This is a simplified approach. In production, you'd want to:
    -- 1. Parse the PGN moves
    -- 2. Play them out on a board representation
    -- 3. Generate FEN from that position
    -- For now, we'll return nil and handle it gracefully
    return nil
  end
  return nil
end

-- Parse puzzle data and prepare for display
local function parse_puzzle(puzzle_data, game_data)
  if not puzzle_data then
    return nil
  end

  -- Get FEN - try from puzzle data first, then from game
  local fen = puzzle_data.fen or get_fen_from_game(game_data, puzzle_data.initialPly)

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
    game_id = game_data and game_data.id
  }
end

-- Get daily puzzle
function M.get_daily_puzzle()
  local puzzle_data, error = api.get_daily_puzzle()

  if error then
    vim.notify("Failed to get daily puzzle: " .. error, vim.log.levels.ERROR)
    return false
  end

  if puzzle_data and puzzle_data.puzzle then
    current_puzzle = parse_puzzle(puzzle_data.puzzle, puzzle_data.game)

    vim.notify(string.format("Daily Puzzle (Rating: %d)", current_puzzle.rating), vim.log.levels.INFO)
    M.show_puzzle()
    return true
  end

  return false
end

-- Get next training puzzle
function M.get_next_puzzle()
  -- Note: /api/puzzle/next works without authentication,
  -- but authenticated users get puzzles matched to their rating
  if not auth.is_authenticated() then
    vim.notify("Getting random puzzle (authenticate for rating-matched puzzles)", vim.log.levels.WARN)
  end

  local puzzle_data, error = api.get_next_puzzle()

  if error then
    vim.notify("Failed to get puzzle: " .. error, vim.log.levels.ERROR)
    return false
  end

  if puzzle_data and puzzle_data.puzzle then
    current_puzzle = parse_puzzle(puzzle_data.puzzle, puzzle_data.game)

    local themes_str = table.concat(current_puzzle.themes, ", ")
    vim.notify(string.format("Puzzle (Rating: %d) - Themes: %s",
      current_puzzle.rating, themes_str), vim.log.levels.INFO)

    M.show_puzzle()
    return true
  end

  return false
end

-- Get specific puzzle by ID
function M.get_puzzle(puzzle_id)
  local puzzle_data, error = api.get_puzzle(puzzle_id)

  if error then
    vim.notify("Failed to get puzzle: " .. error, vim.log.levels.ERROR)
    return false
  end

  if puzzle_data and puzzle_data.puzzle then
    current_puzzle = parse_puzzle(puzzle_data.puzzle, puzzle_data.game)

    vim.notify(string.format("Puzzle %s (Rating: %d)", puzzle_id, current_puzzle.rating), vim.log.levels.INFO)
    M.show_puzzle()
    return true
  end

  return false
end

-- Show puzzle board
function M.show_puzzle()
  if not current_puzzle then
    vim.notify("No active puzzle", vim.log.levels.ERROR)
    return false
  end

  -- Create or focus puzzle buffer
  local buf_name = "puzzle-" .. current_puzzle.id
  local existing_buf = vim.fn.bufnr(buf_name)

  local buf
  if existing_buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, buf_name)
  else
    buf = existing_buf
  end

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)

  -- Display puzzle info and board
  local info_lines = {
    "═══════════════════════════════════════",
    "         🧩 LICHESS PUZZLE",
    "═══════════════════════════════════════",
    "",
    "Puzzle ID:  " .. current_puzzle.id,
    "Rating:     " .. current_puzzle.rating,
    "Themes:     " .. (table.concat(current_puzzle.themes, ", ") ~= "" and table.concat(current_puzzle.themes, ", ") or "None"),
    "Plays:      " .. (current_puzzle.plays or "N/A"),
    "",
    "Task: Find the best move for " .. (current_puzzle.initial_ply % 2 == 0 and "White" or "Black"),
    "",
    "Controls: (m)ove | (h)int | (s)olution | (n)ext | (q)uit",
    "═══════════════════════════════════════",
    "",
  }

  -- Render board using existing UI module
  local board_fen = current_puzzle.fen
  local board = board_fen and ui.parse_fen_position(board_fen)

  if board then
    -- Render board - flip if black to move
    local flip = current_puzzle.initial_ply % 2 == 1
    local render_board = function(board_data, should_flip)
      local pieces = {
        white = { king = "♔", queen = "♕", rook = "♖", bishop = "♗", knight = "♘", pawn = "♙" },
        black = { king = "♚", queen = "♛", rook = "♜", bishop = "♝", knight = "♞", pawn = "♟" }
      }

      local lines = {}
      table.insert(lines, "  a b c d e f g h")

      for rank_idx = 1, 8 do
        local rank = should_flip and rank_idx or (9 - rank_idx)
        local line = tostring(rank) .. " "

        for file_idx = 1, 8 do
          local file = should_flip and (9 - file_idx) or file_idx
          local piece = board_data[rank] and board_data[rank][file]

          if piece then
            line = line .. pieces[piece.color][piece.type] .. " "
          else
            local is_light = (rank + file) % 2 == 0
            line = line .. (is_light and "·" or " ") .. " "
          end
        end

        line = line .. " " .. tostring(rank)
        table.insert(lines, line)
      end

      table.insert(lines, "  a b c d e f g h")
      return lines
    end

    local board_lines = render_board(board, flip)
    for _, line in ipairs(board_lines) do
      table.insert(info_lines, line)
    end
  else
    -- FEN not available - show link to puzzle on Lichess
    table.insert(info_lines, "")
    table.insert(info_lines, "⚠ Board display not available")
    table.insert(info_lines, "")
    if current_puzzle.game_id then
      table.insert(info_lines, "View puzzle on Lichess:")
      table.insert(info_lines, string.format("https://lichess.org/training/%s", current_puzzle.id))
      table.insert(info_lines, "")
      if current_puzzle.pgn then
        table.insert(info_lines, "PGN: " .. current_puzzle.pgn)
      end
    else
      table.insert(info_lines, "FEN not available from API")
    end
  end

  table.insert(info_lines, "")
  if #current_puzzle.moves_made > 0 then
    table.insert(info_lines, "Moves: " .. table.concat(current_puzzle.moves_made, ", "))
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, info_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Open in new window if not already visible
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
  else
    vim.api.nvim_set_current_win(win)
  end

  -- Set up buffer-local keymaps for puzzle solving
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set('n', 'q', '<cmd>q<cr>', opts)

  vim.keymap.set('n', 'm', function()
    local move = vim.fn.input("Enter move (e.g., e2e4): ")
    if move and move ~= "" then
      M.attempt_move(move)
    end
  end, opts)

  vim.keymap.set('n', 'h', function()
    M.show_hint()
  end, opts)

  vim.keymap.set('n', 's', function()
    M.show_solution()
  end, opts)

  vim.keymap.set('n', 'n', function()
    M.get_next_puzzle()
  end, opts)

  vim.keymap.set('n', '<C-r>', function()
    M.show_puzzle()
  end, opts)

  current_puzzle.buffer = buf
  return buf
end

-- Attempt a move on the puzzle
function M.attempt_move(move)
  if not current_puzzle then
    vim.notify("No active puzzle", vim.log.levels.ERROR)
    return false
  end

  if current_puzzle.completed then
    vim.notify("Puzzle already completed", vim.log.levels.WARN)
    return false
  end

  -- Validate move format
  if not move:match("^[a-h][1-8][a-h][1-8][qrbn]?$") then
    vim.notify("Invalid move format. Use format like 'e2e4'", vim.log.levels.ERROR)
    return false
  end

  local expected_move = current_puzzle.solution[current_puzzle.current_move_index + 1]

  if move == expected_move then
    -- Correct move
    current_puzzle.current_move_index = current_puzzle.current_move_index + 1
    table.insert(current_puzzle.moves_made, move)

    if current_puzzle.current_move_index >= #current_puzzle.solution then
      -- Puzzle solved!
      current_puzzle.completed = true
      current_puzzle.success = true
      table.insert(puzzle_history, {
        id = current_puzzle.id,
        success = true,
        moves = vim.deepcopy(current_puzzle.moves_made)
      })

      vim.notify("✓ Puzzle solved! Press 'n' for next puzzle.", vim.log.levels.INFO)

      -- Submit solution if authenticated
      if auth.is_authenticated() then
        M.submit_solution(true)
      end
    else
      vim.notify("✓ Correct! Continue...", vim.log.levels.INFO)
      -- Auto-play opponent's response if available
      if current_puzzle.current_move_index < #current_puzzle.solution then
        vim.notify("Opponent plays: " .. current_puzzle.solution[current_puzzle.current_move_index + 1], vim.log.levels.INFO)
        current_puzzle.current_move_index = current_puzzle.current_move_index + 1
      end
    end
  else
    -- Wrong move
    current_puzzle.completed = true
    current_puzzle.success = false
    table.insert(puzzle_history, {
      id = current_puzzle.id,
      success = false,
      moves = vim.deepcopy(current_puzzle.moves_made)
    })

    vim.notify("✗ Wrong move! Expected: " .. expected_move .. ". Press 's' for solution.", vim.log.levels.ERROR)

    -- Submit failed solution if authenticated
    if auth.is_authenticated() then
      M.submit_solution(false)
    end
  end

  return true
end

-- Show hint (first move of solution)
function M.show_hint()
  if not current_puzzle then
    vim.notify("No active puzzle", vim.log.levels.ERROR)
    return
  end

  if current_puzzle.completed then
    vim.notify("Puzzle already completed", vim.log.levels.WARN)
    return
  end

  local next_move = current_puzzle.solution[current_puzzle.current_move_index + 1]
  if next_move then
    local from = next_move:sub(1, 2)
    local to = next_move:sub(3, 4)
    vim.notify(string.format("Hint: Move from %s to %s", from, to), vim.log.levels.INFO)
  end
end

-- Show full solution
function M.show_solution()
  if not current_puzzle then
    vim.notify("No active puzzle", vim.log.levels.ERROR)
    return
  end

  local solution_str = table.concat(current_puzzle.solution, " → ")
  vim.notify("Solution: " .. solution_str, vim.log.levels.INFO)

  current_puzzle.completed = true
  current_puzzle.success = false
end

-- Submit solution to Lichess (requires authentication)
function M.submit_solution(success)
  if not auth.is_authenticated() then
    return false
  end

  if not current_puzzle then
    return false
  end

  -- This would call api.submit_puzzle_solution if implemented
  -- For now, just track locally
  return true
end

-- Get puzzle activity/history
function M.get_puzzle_activity()
  if not auth.is_authenticated() then
    vim.notify("Authentication required for puzzle activity", vim.log.levels.ERROR)
    return false
  end

  local activity, error = api.get_puzzle_activity()

  if error then
    vim.notify("Failed to get puzzle activity: " .. error, vim.log.levels.ERROR)
    return false
  end

  if activity then
    -- Display activity in a buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "puzzle-activity")

    local lines = {"Puzzle Activity:", "================", ""}

    for _, entry in ipairs(activity) do
      table.insert(lines, string.format("Puzzle #%s - %s - Rating: %d",
        entry.id, entry.win and "Solved" or "Failed", entry.rating or 0))
    end

    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
    return true
  end

  return false
end

-- Get current puzzle
function M.get_current_puzzle()
  return current_puzzle
end

-- Get puzzle history
function M.get_history()
  return puzzle_history
end

return M
