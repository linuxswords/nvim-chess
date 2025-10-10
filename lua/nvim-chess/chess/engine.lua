local M = {}

-- Create an empty 8x8 board
local function create_empty_board()
  local board = {}
  for rank = 1, 8 do
    board[rank] = {}
    for file = 1, 8 do
      board[rank][file] = nil
    end
  end
  return board
end

-- Create initial board state structure
local function create_board_state()
  return {
    position = create_empty_board(),
    to_move = "white",
    castling = {
      white_kingside = true,
      white_queenside = true,
      black_kingside = true,
      black_queenside = true
    },
    en_passant = nil,
    halfmove = 0,
    fullmove = 1
  }
end

-- Parse FEN string into board state
function M.create_board_from_fen(fen)
  local board_state = create_board_state()

  -- Split FEN into components
  local parts = {}
  for part in fen:gmatch("%S+") do
    table.insert(parts, part)
  end

  if #parts < 1 then
    return nil, "Invalid FEN: no position data"
  end

  -- Parse position (part 1)
  local position = parts[1]
  local rank = 8
  local file = 1

  for char in position:gmatch(".") do
    if char == "/" then
      rank = rank - 1
      file = 1
    elseif char:match("%d") then
      file = file + tonumber(char)
    else
      local piece_map = {
        K = {color = "white", type = "king"},
        Q = {color = "white", type = "queen"},
        R = {color = "white", type = "rook"},
        B = {color = "white", type = "bishop"},
        N = {color = "white", type = "knight"},
        P = {color = "white", type = "pawn"},
        k = {color = "black", type = "king"},
        q = {color = "black", type = "queen"},
        r = {color = "black", type = "rook"},
        b = {color = "black", type = "bishop"},
        n = {color = "black", type = "knight"},
        p = {color = "black", type = "pawn"},
      }

      if piece_map[char] then
        board_state.position[rank][file] = piece_map[char]
      end
      file = file + 1
    end
  end

  -- Parse to move (part 2)
  if parts[2] then
    board_state.to_move = parts[2] == "w" and "white" or "black"
  end

  -- Parse castling rights (part 3)
  if parts[3] and parts[3] ~= "-" then
    board_state.castling.white_kingside = parts[3]:find("K") ~= nil
    board_state.castling.white_queenside = parts[3]:find("Q") ~= nil
    board_state.castling.black_kingside = parts[3]:find("k") ~= nil
    board_state.castling.black_queenside = parts[3]:find("q") ~= nil
  else
    board_state.castling = {
      white_kingside = false,
      white_queenside = false,
      black_kingside = false,
      black_queenside = false
    }
  end

  -- Parse en passant (part 4)
  if parts[4] and parts[4] ~= "-" then
    board_state.en_passant = parts[4]
  end

  -- Parse halfmove clock (part 5)
  if parts[5] then
    board_state.halfmove = tonumber(parts[5]) or 0
  end

  -- Parse fullmove number (part 6)
  if parts[6] then
    board_state.fullmove = tonumber(parts[6]) or 1
  end

  return board_state
end

-- Create starting position
function M.create_starting_position()
  return M.create_board_from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
end

-- Convert board state to FEN string
function M.board_to_fen(board_state)
  if not board_state then
    return nil, "Invalid board state"
  end

  -- Encode position
  local position_parts = {}
  for rank = 8, 1, -1 do
    local rank_str = ""
    local empty_count = 0

    for file = 1, 8 do
      local piece = board_state.position[rank][file]

      if piece then
        -- Output any accumulated empty squares
        if empty_count > 0 then
          rank_str = rank_str .. tostring(empty_count)
          empty_count = 0
        end

        -- Add piece character
        local piece_chars = {
          white = {king = "K", queen = "Q", rook = "R", bishop = "B", knight = "N", pawn = "P"},
          black = {king = "k", queen = "q", rook = "r", bishop = "b", knight = "n", pawn = "p"}
        }
        rank_str = rank_str .. piece_chars[piece.color][piece.type]
      else
        empty_count = empty_count + 1
      end
    end

    -- Output any trailing empty squares
    if empty_count > 0 then
      rank_str = rank_str .. tostring(empty_count)
    end

    table.insert(position_parts, rank_str)
  end

  local position = table.concat(position_parts, "/")

  -- Encode to move
  local to_move = board_state.to_move == "white" and "w" or "b"

  -- Encode castling rights
  local castling = ""
  if board_state.castling.white_kingside then castling = castling .. "K" end
  if board_state.castling.white_queenside then castling = castling .. "Q" end
  if board_state.castling.black_kingside then castling = castling .. "k" end
  if board_state.castling.black_queenside then castling = castling .. "q" end
  if castling == "" then castling = "-" end

  -- Encode en passant
  local en_passant = board_state.en_passant or "-"

  -- Encode move counters
  local halfmove = tostring(board_state.halfmove)
  local fullmove = tostring(board_state.fullmove)

  return string.format("%s %s %s %s %s %s",
    position, to_move, castling, en_passant, halfmove, fullmove)
end

-- Get piece at specific square (algebraic notation like "e4")
function M.get_piece_at(board_state, square)
  local file = string.byte(square:sub(1, 1)) - string.byte('a') + 1
  local rank = tonumber(square:sub(2, 2))

  if rank < 1 or rank > 8 or file < 1 or file > 8 then
    return nil
  end

  return board_state.position[rank][file]
end

-- Set piece at specific square
function M.set_piece_at(board_state, square, piece)
  local file = string.byte(square:sub(1, 1)) - string.byte('a') + 1
  local rank = tonumber(square:sub(2, 2))

  if rank < 1 or rank > 8 or file < 1 or file > 8 then
    return false
  end

  board_state.position[rank][file] = piece
  return true
end

-- Convert file index (1-8) to letter (a-h)
function M.file_to_letter(file)
  return string.char(string.byte('a') + file - 1)
end

-- Convert letter (a-h) to file index (1-8)
function M.letter_to_file(letter)
  return string.byte(letter) - string.byte('a') + 1
end

-- Convert rank/file indices to algebraic notation
function M.indices_to_square(rank, file)
  return M.file_to_letter(file) .. tostring(rank)
end

-- Find all pieces of a specific type and color
function M.find_pieces(board_state, piece_type, color)
  local pieces = {}

  for rank = 1, 8 do
    for file = 1, 8 do
      local piece = board_state.position[rank][file]
      if piece and piece.type == piece_type and piece.color == color then
        table.insert(pieces, {rank = rank, file = file})
      end
    end
  end

  return pieces
end

-- Deep copy board state
function M.copy_board_state(board_state)
  local new_state = {
    position = create_empty_board(),
    to_move = board_state.to_move,
    castling = {
      white_kingside = board_state.castling.white_kingside,
      white_queenside = board_state.castling.white_queenside,
      black_kingside = board_state.castling.black_kingside,
      black_queenside = board_state.castling.black_queenside
    },
    en_passant = board_state.en_passant,
    halfmove = board_state.halfmove,
    fullmove = board_state.fullmove
  }

  -- Copy position
  for rank = 1, 8 do
    for file = 1, 8 do
      if board_state.position[rank][file] then
        new_state.position[rank][file] = {
          color = board_state.position[rank][file].color,
          type = board_state.position[rank][file].type
        }
      end
    end
  end

  return new_state
end

return M
