-- Simple test to verify puzzle board rendering works
vim.opt.runtimepath:append(".")

print("========================================")
print("Puzzle Board Rendering Test")
print("========================================")
print("")

-- Load the puzzle manager
local ok, puzzle_manager = pcall(require, 'nvim-chess.puzzle.manager')
if not ok then
  print("✗ Failed to load puzzle manager:", puzzle_manager)
  os.exit(1)
end

print("✓ Puzzle manager loaded")

-- Test with a sample puzzle data
local sample_puzzle = {
  puzzle = {
    id = "test123",
    rating = 1500,
    plays = 1000,
    themes = {"middlegame", "advantage"},
    solution = {"h2h8", "g7h8", "g5h6"},
    initialPly = 33,
  },
  game = {
    id = "testgame",
    pgn = "d4 Nf6 c4 e6 Nf3 d5 Nc3 Be7 Bg5 h6 Bh4 O-O e3 b6 Bd3 Bb7 O-O Nbd7 Qe2 c5 Rfd1 Ne4 Bxe7 Qxe7 cxd5 Nxc3 bxc3 exd5 c4 Rfd8 cxd5 Qxe3 Qxe3 Bxd5 Bc4 Bxc4 Qxc4 cxd4 Nxd4",
  }
}

-- Create a mock puzzle using parse_puzzle logic
local pgn_converter = require('nvim-chess.chess.pgn_converter')
local fen = pgn_converter.pgn_to_fen(sample_puzzle.game.pgn, sample_puzzle.puzzle.initialPly)

if fen then
  print("✓ FEN generated from PGN:", fen)
else
  print("✗ Failed to generate FEN from PGN")
  os.exit(1)
end

-- Now test if we can parse it for board display
local function parse_fen_position(fen_string)
  if not fen_string then return nil end

  local parts = {}
  for part in fen_string:gmatch("%S+") do
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

local board = parse_fen_position(fen)
if not board then
  print("✗ Failed to parse FEN into board")
  os.exit(1)
end

print("✓ Board parsed successfully")

-- Verify board has pieces
local piece_count = 0
for rank = 1, 8 do
  if board[rank] then
    for file = 1, 8 do
      if board[rank][file] then
        piece_count = piece_count + 1
      end
    end
  end
end

print("✓ Board has " .. piece_count .. " pieces")

if piece_count > 0 then
  print("")
  print("========================================")
  print("✓ Puzzle board rendering test PASSED")
  print("========================================")
else
  print("")
  print("✗ Board has no pieces - FAILED")
  os.exit(1)
end
