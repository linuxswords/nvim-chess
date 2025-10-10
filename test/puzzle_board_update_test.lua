-- Test that puzzle board updates with moves
-- Run with: nvim --headless -c "luafile test/puzzle_board_update_test.lua" -c "quit"

vim.opt.runtimepath:append(".")

local engine = require('nvim-chess.chess.engine')

print("========================================")
print("Puzzle Board Update Test")
print("========================================")
print("")

-- Test the UCI move application function
local function apply_uci_move_to_fen(fen, uci_move)
  if not fen or not uci_move then
    return nil
  end

  local board_state, err = engine.create_board_from_fen(fen)
  if not board_state then
    return nil, "Failed to parse FEN: " .. (err or "unknown error")
  end

  local from_square = uci_move:sub(1, 2)
  local to_square = uci_move:sub(3, 4)
  local promotion = uci_move:sub(5, 5)

  local from_file = engine.letter_to_file(from_square:sub(1, 1))
  local from_rank = tonumber(from_square:sub(2, 2))
  local to_file = engine.letter_to_file(to_square:sub(1, 1))
  local to_rank = tonumber(to_square:sub(2, 2))

  local piece = board_state.position[from_rank][from_file]
  if not piece then
    return nil, "No piece at " .. from_square
  end

  -- Check for en passant
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
    if to_file > from_file then
      local rook = board_state.position[from_rank][8]
      board_state.position[from_rank][6] = rook
      board_state.position[from_rank][8] = nil
    else
      local rook = board_state.position[from_rank][1]
      board_state.position[from_rank][4] = rook
      board_state.position[from_rank][1] = nil
    end
  end

  -- Update en passant
  board_state.en_passant = nil
  if piece.type == "pawn" and math.abs(to_rank - from_rank) == 2 then
    local ep_rank = piece.color == "white" and from_rank + 1 or from_rank - 1
    board_state.en_passant = engine.indices_to_square(ep_rank, from_file)
  end

  -- Switch turn
  board_state.to_move = board_state.to_move == "white" and "black" or "white"

  return engine.board_to_fen(board_state)
end

-- Test with a real puzzle position
local starting_fen = "rn1qn1k1/pbp1p1b1/1p3r2/6N1/2PP4/2N2p2/PP5R/RQB1K3 b Q - 1 17"
print("Starting FEN:")
print(starting_fen)
print("")

-- Apply the first solution move: h2h8
local move1 = "h2h8"
print("Applying move: " .. move1)
local fen1, err1 = apply_uci_move_to_fen(starting_fen, move1)

if fen1 then
  print("✓ Move applied successfully")
  print("New FEN: " .. fen1)
  print("")

  -- Apply opponent response: g7h8
  local move2 = "g7h8"
  print("Applying move: " .. move2)
  local fen2, err2 = apply_uci_move_to_fen(fen1, move2)

  if fen2 then
    print("✓ Move applied successfully")
    print("New FEN: " .. fen2)
    print("")

    -- Verify the board state changed
    if starting_fen ~= fen1 and fen1 ~= fen2 then
      print("========================================")
      print("✓ Board update test PASSED!")
      print("========================================")
    else
      print("✗ ERROR: FEN did not change after moves")
    end
  else
    print("✗ ERROR: Failed to apply second move: " .. (err2 or "unknown error"))
  end
else
  print("✗ ERROR: Failed to apply first move: " .. (err1 or "unknown error"))
end
