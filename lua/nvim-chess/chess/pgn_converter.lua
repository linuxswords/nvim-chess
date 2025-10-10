local M = {}

local engine = require('nvim-chess.chess.engine')
local move_executor = require('nvim-chess.chess.move_executor')

-- Parse PGN string into list of SAN moves
-- Lichess returns space-separated SAN moves like: "c4 Nf6 d4 g6 Nc3 Bg7 e4 d6"
function M.parse_pgn_moves(pgn_string)
  if not pgn_string or pgn_string == "" then
    return {}
  end

  local moves = {}

  -- Split by whitespace
  for token in pgn_string:gmatch("%S+") do
    -- Skip move numbers (e.g., "1.", "23.", "100.")
    if not token:match("^%d+%.$") then
      -- Remove trailing dots from move numbers in formats like "1.e4"
      token = token:gsub("^%d+%.", "")

      -- Skip empty tokens
      if token ~= "" then
        table.insert(moves, token)
      end
    end
  end

  return moves
end

-- Convert PGN to FEN at a specific ply
-- ply is the number of half-moves (1 ply = one player's move)
function M.pgn_to_fen(pgn_string, target_ply, starting_fen)
  -- Default to standard starting position
  starting_fen = starting_fen or "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  -- Parse PGN into move list
  local moves = M.parse_pgn_moves(pgn_string)

  if target_ply > #moves then
    return nil, string.format("Target ply %d exceeds available moves (%d)", target_ply, #moves)
  end

  -- Create starting position
  local board_state, err = engine.create_board_from_fen(starting_fen)
  if not board_state then
    return nil, "Failed to parse starting FEN: " .. (err or "unknown error")
  end

  -- Execute moves up to target ply
  for i = 1, target_ply do
    local san_move = moves[i]
    board_state, err = move_executor.execute_move(board_state, san_move)

    if not board_state then
      return nil, string.format("Failed to execute move %d (%s): %s", i, san_move, err or "unknown error")
    end
  end

  -- Generate FEN from final position
  return engine.board_to_fen(board_state)
end

-- Validate a PGN string (check if it can be parsed and executed)
function M.validate_pgn(pgn_string, starting_fen)
  starting_fen = starting_fen or "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  local moves = M.parse_pgn_moves(pgn_string)

  if #moves == 0 then
    return false, "No moves found in PGN"
  end

  local board_state, err = engine.create_board_from_fen(starting_fen)
  if not board_state then
    return false, "Invalid starting FEN: " .. (err or "unknown error")
  end

  for i, san_move in ipairs(moves) do
    board_state, err = move_executor.execute_move(board_state, san_move)

    if not board_state then
      return false, string.format("Invalid move %d (%s): %s", i, san_move, err or "unknown error")
    end
  end

  return true
end

-- Get FEN positions for all plies in a PGN
-- Returns a list of FEN strings, one for each ply
function M.pgn_to_fen_list(pgn_string, starting_fen)
  starting_fen = starting_fen or "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  local moves = M.parse_pgn_moves(pgn_string)
  local fen_list = {starting_fen}

  local board_state, err = engine.create_board_from_fen(starting_fen)
  if not board_state then
    return nil, "Failed to parse starting FEN: " .. (err or "unknown error")
  end

  for i, san_move in ipairs(moves) do
    board_state, err = move_executor.execute_move(board_state, san_move)

    if not board_state then
      return nil, string.format("Failed to execute move %d (%s): %s", i, san_move, err or "unknown error")
    end

    table.insert(fen_list, engine.board_to_fen(board_state))
  end

  return fen_list
end

return M
