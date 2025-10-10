local M = {}

local engine = require('nvim-chess.chess.engine')

-- Parse a SAN move string into structured data
-- Examples: "e4", "Nf3", "Bxe5", "O-O", "e8=Q", "Nbd2"
function M.parse_san(san_move, board_state)
  if not san_move or san_move == "" then
    return nil, "Empty move"
  end

  -- Strip check and checkmate symbols
  local move = san_move:gsub("[+#!?]+$", "")

  local move_data = {
    original = san_move,
    piece = nil,
    from = nil,
    to = nil,
    capture = false,
    promotion = nil,
    castling = nil,
    file_hint = nil,
    rank_hint = nil
  }

  -- Check for castling
  if move == "O-O" or move == "0-0" then
    move_data.castling = "kingside"
    move_data.piece = "king"
    return move_data
  elseif move == "O-O-O" or move == "0-0-0" then
    move_data.castling = "queenside"
    move_data.piece = "king"
    return move_data
  end

  -- Check for capture
  if move:find("x") then
    move_data.capture = true
    move = move:gsub("x", "")
  end

  -- Check for promotion (e.g., "e8=Q" or "e8Q")
  local promotion_piece = move:match("[=]?([QRBN])$")
  if promotion_piece then
    local piece_map = {Q = "queen", R = "rook", B = "bishop", N = "knight"}
    move_data.promotion = piece_map[promotion_piece]
    move = move:gsub("[=]?[QRBN]$", "")
  end

  -- Extract destination square (last 2 characters after removing promotion)
  local dest_square = move:match("([a-h][1-8])$")
  if not dest_square then
    return nil, "Invalid move: no destination square"
  end
  move_data.to = dest_square

  -- Remove destination square from move string
  move = move:sub(1, #move - 2)

  -- Determine piece type
  local piece_letter = move:match("^([KQRBN])")
  if piece_letter then
    local piece_map = {K = "king", Q = "queen", R = "rook", B = "bishop", N = "knight"}
    move_data.piece = piece_map[piece_letter]
    move = move:sub(2)  -- Remove piece letter
  else
    -- No piece letter means pawn move
    move_data.piece = "pawn"
  end

  -- Parse disambiguation hints (remaining characters)
  -- Can be file (a-h), rank (1-8), or both (a1)
  if move ~= "" then
    local file_hint = move:match("([a-h])")
    local rank_hint = move:match("([1-8])")

    if file_hint then
      move_data.file_hint = engine.letter_to_file(file_hint)
    end

    if rank_hint then
      move_data.rank_hint = tonumber(rank_hint)
    end
  end

  return move_data
end

-- Find the source square for a piece move
-- Returns {rank, file} or nil if not found
function M.find_source_square(board_state, move_data)
  local color = board_state.to_move
  local pieces = engine.find_pieces(board_state, move_data.piece, color)

  if #pieces == 0 then
    return nil, "No " .. color .. " " .. move_data.piece .. " found"
  end

  -- If we have exact file and rank hints, use them
  if move_data.file_hint and move_data.rank_hint then
    return {rank = move_data.rank_hint, file = move_data.file_hint}
  end

  -- Filter by hints if provided
  local candidates = {}
  for _, pos in ipairs(pieces) do
    local matches = true

    if move_data.file_hint and pos.file ~= move_data.file_hint then
      matches = false
    end

    if move_data.rank_hint and pos.rank ~= move_data.rank_hint then
      matches = false
    end

    if matches and M.can_piece_move_to(board_state, pos, move_data) then
      table.insert(candidates, pos)
    end
  end

  if #candidates == 0 then
    return nil, "No valid source square found for " .. move_data.piece
  elseif #candidates > 1 then
    return nil, "Ambiguous move: multiple pieces can move to " .. move_data.to
  end

  return candidates[1]
end

-- Check if a piece at a given position can move to the destination
-- This is a simplified version - doesn't check for pins or check
function M.can_piece_move_to(board_state, from_pos, move_data)
  local dest_file = engine.letter_to_file(move_data.to:sub(1, 1))
  local dest_rank = tonumber(move_data.to:sub(2, 2))

  local piece = board_state.position[from_pos.rank][from_pos.file]
  if not piece then
    return false
  end

  local dest_piece = board_state.position[dest_rank][dest_file]

  -- Check if destination has our own piece
  if dest_piece and dest_piece.color == piece.color then
    return false
  end

  -- Check if capture flag matches reality
  if move_data.capture and not dest_piece then
    -- Could be en passant for pawns
    if piece.type ~= "pawn" then
      return false
    end
  end

  local file_diff = math.abs(dest_file - from_pos.file)
  local rank_diff = dest_rank - from_pos.rank
  local abs_rank_diff = math.abs(rank_diff)

  -- Check move legality based on piece type
  if piece.type == "pawn" then
    return M.is_valid_pawn_move(board_state, from_pos, dest_rank, dest_file, move_data)
  elseif piece.type == "knight" then
    return (file_diff == 2 and abs_rank_diff == 1) or (file_diff == 1 and abs_rank_diff == 2)
  elseif piece.type == "bishop" then
    return file_diff == abs_rank_diff and file_diff > 0 and M.is_diagonal_clear(board_state, from_pos, dest_rank, dest_file)
  elseif piece.type == "rook" then
    return (file_diff == 0 or abs_rank_diff == 0) and M.is_path_clear(board_state, from_pos, dest_rank, dest_file)
  elseif piece.type == "queen" then
    if file_diff == abs_rank_diff and file_diff > 0 then
      return M.is_diagonal_clear(board_state, from_pos, dest_rank, dest_file)
    elseif file_diff == 0 or abs_rank_diff == 0 then
      return M.is_path_clear(board_state, from_pos, dest_rank, dest_file)
    end
    return false
  elseif piece.type == "king" then
    return file_diff <= 1 and abs_rank_diff <= 1
  end

  return false
end

-- Check if pawn move is valid
function M.is_valid_pawn_move(board_state, from_pos, dest_rank, dest_file, move_data)
  local piece = board_state.position[from_pos.rank][from_pos.file]
  local direction = piece.color == "white" and 1 or -1
  local start_rank = piece.color == "white" and 2 or 7

  local file_diff = math.abs(dest_file - from_pos.file)
  local rank_diff = dest_rank - from_pos.rank

  -- Forward move
  if file_diff == 0 and not move_data.capture then
    if rank_diff == direction then
      -- One square forward
      return board_state.position[dest_rank][dest_file] == nil
    elseif rank_diff == 2 * direction and from_pos.rank == start_rank then
      -- Two squares forward from starting position
      local middle_rank = from_pos.rank + direction
      return board_state.position[middle_rank][dest_file] == nil
        and board_state.position[dest_rank][dest_file] == nil
    end
  end

  -- Capture move
  if file_diff == 1 and rank_diff == direction then
    local dest_piece = board_state.position[dest_rank][dest_file]
    if dest_piece then
      return dest_piece.color ~= piece.color
    end

    -- Check for en passant
    local en_passant_square = move_data.to
    if board_state.en_passant == en_passant_square then
      return true
    end
  end

  return false
end

-- Check if path is clear for rook/queen (horizontal/vertical)
function M.is_path_clear(board_state, from_pos, dest_rank, dest_file)
  local rank_step = dest_rank > from_pos.rank and 1 or (dest_rank < from_pos.rank and -1 or 0)
  local file_step = dest_file > from_pos.file and 1 or (dest_file < from_pos.file and -1 or 0)

  local rank = from_pos.rank + rank_step
  local file = from_pos.file + file_step

  while rank ~= dest_rank or file ~= dest_file do
    if board_state.position[rank][file] then
      return false
    end
    rank = rank + rank_step
    file = file + file_step
  end

  return true
end

-- Check if diagonal is clear for bishop/queen
function M.is_diagonal_clear(board_state, from_pos, dest_rank, dest_file)
  return M.is_path_clear(board_state, from_pos, dest_rank, dest_file)
end

return M
