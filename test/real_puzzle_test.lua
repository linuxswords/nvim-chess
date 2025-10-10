-- Manual test with real Lichess puzzle data
-- Run with: nvim --headless -c "luafile test/real_puzzle_test.lua" -c "quit"

-- Add plugin to path
vim.opt.runtimepath:append(".")

local pgn_converter = require('nvim-chess.chess.pgn_converter')
local engine = require('nvim-chess.chess.engine')

-- Real Lichess daily puzzle data (2025-01-10)
local puzzle_data = {
  game = {
    id = "hJvbjXOZ",
    pgn = "c4 Nf6 d4 g6 Nc3 Bg7 e4 d6 f4 O-O e5 Ne8 h4 b6 h5 Bb7 hxg6 fxg6 Bd3 Bxg2 Rh2 Bb7 Qg4 dxe5 Bxg6 hxg6 Qxg6 exf4 Nh3 Rf6 Qb1 f3 Ng5 Qxd4"
  },
  puzzle = {
    id = "YoTyb",
    rating = 1976,
    plays = 117085,
    solution = {"h2h8", "g7h8", "b1h7", "g8f8", "h7h8"},
    themes = {"exposedKing", "deflection", "middlegame", "long", "mateIn3", "sacrifice", "kingsideAttack"},
    initialPly = 33
  }
}

print("========================================")
print("Real Lichess Puzzle Test")
print("========================================")
print("")
print("Puzzle ID: " .. puzzle_data.puzzle.id)
print("Rating: " .. puzzle_data.puzzle.rating)
print("Initial Ply: " .. puzzle_data.puzzle.initialPly)
print("")
print("Converting PGN to FEN...")
print("")

-- Convert PGN to FEN at puzzle position
local fen, err = pgn_converter.pgn_to_fen(puzzle_data.game.pgn, puzzle_data.puzzle.initialPly)

if fen then
  print("✓ SUCCESS!")
  print("")
  print("Generated FEN:")
  print(fen)
  print("")

  -- Parse the FEN to verify it's valid
  local board = engine.create_board_from_fen(fen)
  if board then
    print("✓ FEN is valid and parseable")
    print("")
    print("Board state:")
    print("  To move: " .. board.to_move)
    print("  Fullmove: " .. board.fullmove)
    print("  Halfmove: " .. board.halfmove)
    print("")

    -- Verify we can render a simple representation
    print("Position check:")
    local pieces_found = 0
    for rank = 1, 8 do
      for file = 1, 8 do
        if board.position[rank][file] then
          pieces_found = pieces_found + 1
        end
      end
    end
    print("  Total pieces on board: " .. pieces_found)
    print("")
    print("========================================")
    print("✓ All checks passed!")
    print("========================================")
  else
    print("✗ ERROR: Failed to parse generated FEN")
  end
else
  print("✗ ERROR: Failed to convert PGN to FEN")
  print("Error: " .. (err or "unknown error"))
end
