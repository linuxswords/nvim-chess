-- Integration test for puzzle manager with PGN-to-FEN conversion
-- Run with: nvim --headless -c "luafile test/puzzle_integration_test.lua" -c "quit"

-- Add plugin to path
vim.opt.runtimepath:append(".")

-- Mock the API to return real puzzle data
package.loaded['nvim-chess.api.client'] = {
  get_daily_puzzle = function()
    return {
      game = {
        id = "hJvbjXOZ",
        pgn = "c4 Nf6 d4 g6 Nc3 Bg7 e4 d6 f4 O-O e5 Ne8 h4 b6 h5 Bb7 hxg6 fxg6 Bd3 Bxg2 Rh2 Bb7 Qg4 dxe5 Bxg6 hxg6 Qxg6 exf4 Nh3 Rf6 Qb1 f3 Ng5 Qxd4"
      },
      puzzle = {
        id = "YoTyb",
        rating = 1976,
        plays = 117085,
        solution = {"h2h8", "g7h8", "b1h7", "g8f8", "h7h8"},
        themes = {"exposedKing", "deflection"},
        initialPly = 33
      }
    }, nil
  end
}

-- Mock auth module
package.loaded['nvim-chess.auth.manager'] = {
  is_authenticated = function() return false end
}

-- Mock UI to not actually display
package.loaded['nvim-chess.ui.board'] = {
  parse_fen_position = function(fen)
    -- Just verify FEN is valid by parsing first part
    local position = fen:match("^([^%s]+)")
    if position then
      return {}  -- Return empty board for test
    end
    return nil
  end
}

-- Reload puzzle manager with mocks
package.loaded['nvim-chess.puzzle.manager'] = nil
local puzzle_manager = require('nvim-chess.puzzle.manager')

print("========================================")
print("Puzzle Manager Integration Test")
print("========================================")
print("")
print("Testing puzzle retrieval and FEN generation...")
print("")

-- Get daily puzzle (uses mocked API)
local success = puzzle_manager.get_daily_puzzle()

if success then
  print("✓ Puzzle retrieved successfully")
  print("")

  -- Get the puzzle data
  local puzzle = puzzle_manager.get_current_puzzle()

  if puzzle then
    print("Puzzle details:")
    print("  ID: " .. puzzle.id)
    print("  Rating: " .. puzzle.rating)
    print("  Plays: " .. puzzle.plays)
    print("  Themes: " .. table.concat(puzzle.themes, ", "))
    print("  Solution length: " .. #puzzle.solution)
    print("")

    -- Most importantly, check if FEN was generated
    if puzzle.fen then
      print("✓ FEN successfully generated from PGN!")
      print("")
      print("FEN: " .. puzzle.fen)
      print("")

      -- Verify FEN format
      local parts = {}
      for part in puzzle.fen:gmatch("%S+") do
        table.insert(parts, part)
      end

      if #parts >= 6 then
        print("FEN structure:")
        print("  Position: " .. parts[1])
        print("  To move: " .. parts[2])
        print("  Castling: " .. parts[3])
        print("  En passant: " .. parts[4])
        print("  Halfmove: " .. parts[5])
        print("  Fullmove: " .. parts[6])
        print("")
        print("========================================")
        print("✓ Integration test PASSED!")
        print("========================================")
      else
        print("✗ ERROR: FEN format invalid")
      end
    else
      print("✗ ERROR: No FEN generated")
      print("  PGN: " .. (puzzle.pgn or "nil"))
      print("  Game ID: " .. (puzzle.game_id or "nil"))
    end
  else
    print("✗ ERROR: No puzzle data available")
  end
else
  print("✗ ERROR: Failed to retrieve puzzle")
end
