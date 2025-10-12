local M = {}

local api = require('nvim-chess.api.client')
local auth = require('nvim-chess.auth.manager')
local pgn_converter = require('nvim-chess.chess.pgn_converter')
local engine = require('nvim-chess.chess.engine')
local move_executor = require('nvim-chess.chess.move_executor')

-- Constants for player colors based on ply
local PLY_WHITE = 0  -- Even ply numbers indicate white to move
local PLY_BLACK = 1  -- Odd ply numbers indicate black to move

-- Helper function to determine which player moves at a given ply
local function get_player_from_ply(ply)
  return (ply % 2 == PLY_WHITE) and "White" or "Black"
end

-- Helper function to determine if board should be flipped (black's perspective)
local function should_flip_board(ply)
  return (ply % 2 == PLY_BLACK)
end

-- Helper function to parse FEN position (replaces ui.board dependency)
local function parse_fen_position(fen)
  if not fen then return nil end

  local parts = {}
  for part in fen:gmatch("%S+") do
    table.insert(parts, part)
  end

  if #parts < 1 then return nil end

  local position = parts[1]
  local board = {}

  local rank = 8
  for rank_str in position:gmatch("[^/]+") do
    board[rank] = {}
    local file = 1

    for char in rank_str:gmatch(".") do
      if char:match("%d") then
        file = file + tonumber(char)
      else
        local color = char:match("[KQRBNP]") and "white" or "black"
        local piece_map = {
          K = "king", Q = "queen", R = "rook", B = "bishop", N = "knight", P = "pawn",
          k = "king", q = "queen", r = "rook", b = "bishop", n = "knight", p = "pawn"
        }
        board[rank][file] = { type = piece_map[char], color = color }
        file = file + 1
      end
    end

    rank = rank - 1
  end

  return board
end

-- Active puzzle storage
local current_puzzle = nil
local puzzle_history = {}

-- Helper function to get FEN from game PGN
-- Converts PGN moves to FEN at the puzzle's starting position
local function get_fen_from_game(game_data, initial_ply)
  if not game_data or not game_data.pgn then
    return nil
  end

  -- Convert PGN to FEN at the puzzle's starting position
  -- Lichess initialPly is 0-based, but our move array is 1-based, so add 1
  local target_ply = (initial_ply or 0) + 1
  local fen, err = pgn_converter.pgn_to_fen(game_data.pgn, target_ply)

  if not fen then
    vim.notify("Warning: Could not generate FEN from PGN: " .. (err or "unknown error"),
      vim.log.levels.WARN)
    return nil
  end

  return fen
end

-- Helper function to apply a UCI move to the current puzzle FEN
-- Returns updated FEN or nil on error
local function apply_uci_move_to_fen(fen, uci_move)
  if not fen or not uci_move then
    return nil
  end

  -- Parse current FEN into board state
  local board_state, err = engine.create_board_from_fen(fen)
  if not board_state then
    return nil, "Failed to parse FEN: " .. (err or "unknown error")
  end

  -- Convert UCI to SAN-like format for move executor
  -- UCI format: e2e4, e7e8q (source square + dest square + optional promotion)
  -- We need to convert this to SAN for the move executor

  -- For now, we'll use a simpler approach: directly manipulate the board
  local from_square = uci_move:sub(1, 2)
  local to_square = uci_move:sub(3, 4)
  local promotion = uci_move:sub(5, 5)

  local from_file = engine.letter_to_file(from_square:sub(1, 1))
  local from_rank = tonumber(from_square:sub(2, 2))
  local to_file = engine.letter_to_file(to_square:sub(1, 1))
  local to_rank = tonumber(to_square:sub(2, 2))

  -- Get the piece being moved
  local piece = board_state.position[from_rank][from_file]
  if not piece then
    return nil, "No piece at " .. from_square
  end

  -- Check for en passant capture
  local is_en_passant = false
  if piece.type == "pawn" and to_square == board_state.en_passant then
    is_en_passant = true
    local capture_rank = piece.color == "white" and to_rank - 1 or to_rank + 1
    board_state.position[capture_rank][to_file] = nil
  end

  -- Move the piece
  board_state.position[to_rank][to_file] = piece
  board_state.position[from_rank][from_file] = nil

  -- Handle promotion
  if promotion and promotion ~= "" then
    local promo_map = {q = "queen", r = "rook", b = "bishop", n = "knight"}
    board_state.position[to_rank][to_file].type = promo_map[promotion]
  end

  -- Handle castling
  if piece.type == "king" and math.abs(to_file - from_file) == 2 then
    -- Kingside castling
    if to_file > from_file then
      local rook = board_state.position[from_rank][8]
      board_state.position[from_rank][6] = rook
      board_state.position[from_rank][8] = nil
    else
      -- Queenside castling
      local rook = board_state.position[from_rank][1]
      board_state.position[from_rank][4] = rook
      board_state.position[from_rank][1] = nil
    end
  end

  -- Update castling rights
  if piece.type == "king" then
    if piece.color == "white" then
      board_state.castling.white_kingside = false
      board_state.castling.white_queenside = false
    else
      board_state.castling.black_kingside = false
      board_state.castling.black_queenside = false
    end
  elseif piece.type == "rook" then
    if piece.color == "white" and from_rank == 1 then
      if from_file == 1 then
        board_state.castling.white_queenside = false
      elseif from_file == 8 then
        board_state.castling.white_kingside = false
      end
    elseif piece.color == "black" and from_rank == 8 then
      if from_file == 1 then
        board_state.castling.black_queenside = false
      elseif from_file == 8 then
        board_state.castling.black_kingside = false
      end
    end
  end

  -- Update en passant target square
  board_state.en_passant = nil
  if piece.type == "pawn" and math.abs(to_rank - from_rank) == 2 then
    local ep_rank = piece.color == "white" and from_rank + 1 or from_rank - 1
    board_state.en_passant = engine.indices_to_square(ep_rank, from_file)
  end

  -- Update move counters
  if piece.type == "pawn" or is_en_passant then
    board_state.halfmove = 0
  else
    board_state.halfmove = board_state.halfmove + 1
  end

  -- Update fullmove number
  if board_state.to_move == "black" then
    board_state.fullmove = board_state.fullmove + 1
  end

  -- Switch turn
  board_state.to_move = board_state.to_move == "white" and "black" or "white"

  -- Generate new FEN
  return engine.board_to_fen(board_state)
end

-- Parse puzzle data and prepare for display
local function parse_puzzle(puzzle_data, game_data)
  if not puzzle_data then
    return nil
  end

  -- Get FEN - try from puzzle data first, then from game
  local fen = puzzle_data.fen or get_fen_from_game(game_data, puzzle_data.initialPly)

  -- Determine player color from initial FEN (the color to move at puzzle start)
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
    player_color = player_color  -- Track which color the player is playing as
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

    vim.notify(string.format("Puzzle (Rating: %d)", current_puzzle.rating), vim.log.levels.INFO)

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

  -- Determine whose turn it is from the FEN
  local function get_turn_from_fen(fen)
    if not fen then return "White" end
    local parts = {}
    for part in fen:gmatch("%S+") do
      table.insert(parts, part)
    end
    -- FEN part 2 is the active color: 'w' or 'b'
    if #parts >= 2 then
      return parts[2] == "w" and "White" or "Black"
    end
    return "White"
  end

  -- Render board
  local board_fen = current_puzzle.fen
  local board = board_fen and parse_fen_position(board_fen)
  local display_lines

  if board then
    -- Render board - flip if player is white so they see from their perspective
    local player_color = current_puzzle.player_color or "White"
    local flip = (player_color == "White")
    local render_board = function(board_data, should_flip)
      -- Note: Using filled symbols for white, outlined for black for better contrast
      local pieces = {
        white = { king = "♚", queen = "♛", rook = "♜", bishop = "♝", knight = "♞", pawn = "♟" },
        black = { king = "♔", queen = "♕", rook = "♖", bishop = "♗", knight = "♘", pawn = "♙" }
      }

      local lines = {}
      local file_labels = should_flip and "  h g f e d c b a" or "  a b c d e f g h"
      table.insert(lines, file_labels)

      for rank_idx = 1, 8 do
        -- When not flipped (white perspective): rank_idx 1→8 maps to rank 8→1 (top to bottom)
        -- When flipped (black perspective): rank_idx 1→8 maps to rank 1→8 (top to bottom)
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

    local board_lines = render_board(board, flip)

    -- Create info panel for right side
    local info_panel = {
      "┌─ 🧩 LICHESS PUZZLE ─────────┐",
      "│                             │",
      "│ ID:     " .. string.format("%-18s", current_puzzle.id) .. "│",
      "│ Rating: " .. string.format("%-18s", tostring(current_puzzle.rating)) .. "│",
      "│ Plays:  " .. string.format("%-18s", tostring(current_puzzle.plays or "N/A")) .. "│",
      "│                             │",
      "│ Task: " .. string.format("%-20s", "Find best move") .. "│",
      "│       " .. string.format("%-20s", "for " .. player_color) .. "│",
      "│                             │",
      "├─ CONTROLS ──────────────────┤",
      "│ (m) Make move               │",
      "│ (h) Show hint               │",
      "│ (s) Show solution           │",
      "│ (n) Next puzzle             │",
      "│ (q) Quit                    │",
      "└─────────────────────────────┘"
    }

    -- Add moves if any
    if #current_puzzle.moves_made > 0 then
      table.insert(info_panel, "")
      table.insert(info_panel, "Moves made:")
      table.insert(info_panel, table.concat(current_puzzle.moves_made, " → "))
    end

    -- Combine board and info side by side
    display_lines = {}
    for i = 1, math.max(#board_lines, #info_panel) do
      local board_part = board_lines[i] or string.rep(" ", 20)
      local info_part = info_panel[i] or ""
      table.insert(display_lines, board_part .. "   " .. info_part)
    end

  else
    -- FEN not available - show link to puzzle on Lichess
    display_lines = {
      "⚠ Board display not available",
      ""
    }
    if current_puzzle.game_id then
      table.insert(display_lines, "View puzzle on Lichess:")
      table.insert(display_lines, string.format("https://lichess.org/training/%s", current_puzzle.id))
      table.insert(display_lines, "")
      if current_puzzle.pgn then
        table.insert(display_lines, "PGN: " .. current_puzzle.pgn)
      end
    else
      table.insert(display_lines, "FEN not available from API")
    end
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Check if we're already in a puzzle buffer and reuse that window
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)
  local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
  local in_puzzle_buffer = current_buf_name:match("puzzle%-")

  -- Open in new window if not already visible, otherwise reuse current window if it's a puzzle
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    -- Buffer not visible anywhere
    if in_puzzle_buffer then
      -- We're in a puzzle buffer, reuse current window
      vim.api.nvim_win_set_buf(current_win, buf)
    else
      -- Not in a puzzle buffer, create new split
      vim.cmd('split')
      vim.api.nvim_win_set_buf(0, buf)
    end
  else
    -- Buffer is already visible, switch to it
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

    -- Update the FEN with the move
    local new_fen, err = apply_uci_move_to_fen(current_puzzle.fen, move)
    if new_fen then
      current_puzzle.fen = new_fen
    else
      vim.notify("Warning: Could not update board: " .. (err or "unknown error"), vim.log.levels.WARN)
    end

    -- Refresh the board display
    M.show_puzzle()

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
        local opponent_move = current_puzzle.solution[current_puzzle.current_move_index + 1]
        vim.notify("Opponent plays: " .. opponent_move, vim.log.levels.INFO)
        current_puzzle.current_move_index = current_puzzle.current_move_index + 1

        -- Update FEN with opponent's move
        local opponent_fen, opponent_err = apply_uci_move_to_fen(current_puzzle.fen, opponent_move)
        if opponent_fen then
          current_puzzle.fen = opponent_fen
        else
          vim.notify("Warning: Could not update board with opponent move: " .. (opponent_err or "unknown error"), vim.log.levels.WARN)
        end

        -- Refresh board to show opponent's move
        M.show_puzzle()
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
