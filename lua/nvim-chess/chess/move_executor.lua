local M = {}

local engine = require('nvim-chess.chess.engine')
local san_parser = require('nvim-chess.chess.san_parser')

-- Execute a SAN move on the board state (modifies in place)
function M.execute_move(board_state, san_move)
  -- Parse the SAN move
  local move_data, err = san_parser.parse_san(san_move, board_state)
  if not move_data then
    return nil, "Failed to parse move: " .. (err or "unknown error")
  end

  -- Handle castling separately
  if move_data.castling then
    return M.execute_castling(board_state, move_data.castling)
  end

  -- Find source square
  local from_pos, find_err = san_parser.find_source_square(board_state, move_data)
  if not from_pos then
    return nil, "Failed to find source square: " .. (find_err or "unknown error")
  end

  move_data.from = engine.indices_to_square(from_pos.rank, from_pos.file)

  -- Execute the move
  return M.apply_move(board_state, move_data)
end

-- Apply a move to the board (internal function)
function M.apply_move(board_state, move_data)
  local from_file = engine.letter_to_file(move_data.from:sub(1, 1))
  local from_rank = tonumber(move_data.from:sub(2, 2))
  local to_file = engine.letter_to_file(move_data.to:sub(1, 1))
  local to_rank = tonumber(move_data.to:sub(2, 2))

  local piece = board_state.position[from_rank][from_file]
  if not piece then
    return nil, "No piece at source square " .. move_data.from
  end

  -- Handle en passant capture
  local en_passant_capture = false
  if piece.type == "pawn" and move_data.to == board_state.en_passant then
    en_passant_capture = true
    local capture_rank = piece.color == "white" and to_rank - 1 or to_rank + 1
    board_state.position[capture_rank][to_file] = nil
  end

  -- Move the piece
  board_state.position[to_rank][to_file] = piece
  board_state.position[from_rank][from_file] = nil

  -- Handle pawn promotion
  if move_data.promotion then
    board_state.position[to_rank][to_file].type = move_data.promotion
  end

  -- Update en passant target square
  local old_en_passant = board_state.en_passant
  board_state.en_passant = nil

  if piece.type == "pawn" and math.abs(to_rank - from_rank) == 2 then
    -- Pawn moved two squares, set en passant target
    local ep_rank = piece.color == "white" and from_rank + 1 or from_rank - 1
    board_state.en_passant = engine.indices_to_square(ep_rank, from_file)
  end

  -- Update castling rights
  M.update_castling_rights(board_state, piece, from_rank, from_file)

  -- Update halfmove clock (reset on pawn move or capture)
  if piece.type == "pawn" or move_data.capture or en_passant_capture then
    board_state.halfmove = 0
  else
    board_state.halfmove = board_state.halfmove + 1
  end

  -- Update fullmove number (increment after black's move)
  if board_state.to_move == "black" then
    board_state.fullmove = board_state.fullmove + 1
  end

  -- Switch turn
  board_state.to_move = board_state.to_move == "white" and "black" or "white"

  return board_state
end

-- Execute castling move
function M.execute_castling(board_state, castling_side)
  local color = board_state.to_move
  local rank = color == "white" and 1 or 8

  if castling_side == "kingside" then
    -- Check castling rights
    if color == "white" and not board_state.castling.white_kingside then
      return nil, "White cannot castle kingside"
    end
    if color == "black" and not board_state.castling.black_kingside then
      return nil, "Black cannot castle kingside"
    end

    -- Move king from e to g
    local king = board_state.position[rank][5]  -- e-file
    board_state.position[rank][7] = king  -- g-file
    board_state.position[rank][5] = nil

    -- Move rook from h to f
    local rook = board_state.position[rank][8]  -- h-file
    board_state.position[rank][6] = rook  -- f-file
    board_state.position[rank][8] = nil

  elseif castling_side == "queenside" then
    -- Check castling rights
    if color == "white" and not board_state.castling.white_queenside then
      return nil, "White cannot castle queenside"
    end
    if color == "black" and not board_state.castling.black_queenside then
      return nil, "Black cannot castle queenside"
    end

    -- Move king from e to c
    local king = board_state.position[rank][5]  -- e-file
    board_state.position[rank][3] = king  -- c-file
    board_state.position[rank][5] = nil

    -- Move rook from a to d
    local rook = board_state.position[rank][1]  -- a-file
    board_state.position[rank][4] = rook  -- d-file
    board_state.position[rank][1] = nil
  end

  -- Remove all castling rights for this color
  if color == "white" then
    board_state.castling.white_kingside = false
    board_state.castling.white_queenside = false
  else
    board_state.castling.black_kingside = false
    board_state.castling.black_queenside = false
  end

  -- Reset en passant
  board_state.en_passant = nil

  -- Update move counters
  board_state.halfmove = board_state.halfmove + 1
  if board_state.to_move == "black" then
    board_state.fullmove = board_state.fullmove + 1
  end

  -- Switch turn
  board_state.to_move = board_state.to_move == "white" and "black" or "white"

  return board_state
end

-- Update castling rights based on piece movement
function M.update_castling_rights(board_state, piece, from_rank, from_file)
  -- King moves remove all castling rights
  if piece.type == "king" then
    if piece.color == "white" then
      board_state.castling.white_kingside = false
      board_state.castling.white_queenside = false
    else
      board_state.castling.black_kingside = false
      board_state.castling.black_queenside = false
    end
  end

  -- Rook moves remove castling on that side
  if piece.type == "rook" then
    if piece.color == "white" and from_rank == 1 then
      if from_file == 1 then  -- a1 rook
        board_state.castling.white_queenside = false
      elseif from_file == 8 then  -- h1 rook
        board_state.castling.white_kingside = false
      end
    elseif piece.color == "black" and from_rank == 8 then
      if from_file == 1 then  -- a8 rook
        board_state.castling.black_queenside = false
      elseif from_file == 8 then  -- h8 rook
        board_state.castling.black_kingside = false
      end
    end
  end
end

return M
