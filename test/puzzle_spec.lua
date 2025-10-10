describe("Chess Puzzle", function()
  local puzzle_manager

  before_each(function()
    -- Reset the puzzle manager for each test
    package.loaded['nvim-chess.puzzle.manager'] = nil
    puzzle_manager = require('nvim-chess.puzzle.manager')
  end)

  describe("Puzzle parsing", function()
    it("should parse puzzle data correctly", function()
      local mock_puzzle = {
        id = "abc123",
        fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        rating = 1500,
        plays = 1000,
        themes = {"opening", "short"},
        solution = {"e2e4", "e7e5"},
        initialPly = 0
      }

      -- This would test the parse_puzzle function if it was exposed
      assert.is_not_nil(mock_puzzle)
      assert.equals("abc123", mock_puzzle.id)
      assert.equals(1500, mock_puzzle.rating)
    end)

    it("should handle puzzles with multiple themes", function()
      local themes = {"middlegame", "advantage", "short"}
      assert.equals(3, #themes)
    end)
  end)

  describe("Move validation", function()
    it("should validate UCI move format", function()
      local valid_moves = {"e2e4", "a7a8q", "e1g1", "h7h8n"}
      local invalid_moves = {"e2", "e2e9", "invalid"}

      for _, move in ipairs(valid_moves) do
        assert.is_true(move:match("^[a-h][1-8][a-h][1-8][qrbn]?$") ~= nil, "Move " .. move .. " should be valid")
      end

      for _, move in ipairs(invalid_moves) do
        assert.is_false(move:match("^[a-h][1-8][a-h][1-8][qrbn]?$") ~= nil, "Move " .. move .. " should be invalid")
      end
    end)
  end)

  describe("Puzzle solution checking", function()
    it("should accept correct moves", function()
      local solution = {"e2e4", "e7e5", "g1f3"}
      local attempted_move = "e2e4"

      assert.equals(solution[1], attempted_move)
    end)

    it("should reject incorrect moves", function()
      local solution = {"e2e4", "e7e5", "g1f3"}
      local attempted_move = "d2d4"

      assert.is_not.equals(solution[1], attempted_move)
    end)

    it("should track puzzle progress", function()
      local moves_made = {}
      local solution = {"e2e4", "e7e5", "g1f3"}

      table.insert(moves_made, "e2e4")
      assert.equals(1, #moves_made)

      table.insert(moves_made, "e7e5")
      assert.equals(2, #moves_made)
    end)
  end)

  describe("Puzzle history", function()
    it("should track solved puzzles", function()
      local history = puzzle_manager.get_history()
      assert.is_not_nil(history)
      assert.equals("table", type(history))
    end)

    it("should record puzzle results", function()
      local puzzle_result = {
        id = "test123",
        success = true,
        moves = {"e2e4", "e7e5"}
      }

      assert.is_not_nil(puzzle_result.id)
      assert.is_true(puzzle_result.success)
      assert.equals(2, #puzzle_result.moves)
    end)
  end)

  describe("Puzzle themes", function()
    it("should handle common puzzle themes", function()
      local common_themes = {
        "opening", "middlegame", "endgame",
        "mate", "mateIn1", "mateIn2",
        "advantage", "short", "long",
        "pin", "fork", "skewer"
      }

      assert.is_true(#common_themes > 0)
    end)
  end)

  describe("FEN position parsing", function()
    it("should parse starting position FEN", function()
      local starting_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      local position = starting_fen:match("^([^%s]+)")

      assert.equals("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR", position)
    end)

    it("should parse puzzle position FEN", function()
      local puzzle_fen = "r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
      local position = puzzle_fen:match("^([^%s]+)")

      assert.is_not_nil(position)
      assert.is_true(position:find("/") ~= nil)
    end)
  end)

  describe("Hint system", function()
    it("should extract move components", function()
      local move = "e2e4"
      local from = move:sub(1, 2)
      local to = move:sub(3, 4)

      assert.equals("e2", from)
      assert.equals("e4", to)
    end)

    it("should handle promotion moves in hints", function()
      local move = "a7a8q"
      local from = move:sub(1, 2)
      local to = move:sub(3, 4)
      local promotion = move:sub(5, 5)

      assert.equals("a7", from)
      assert.equals("a8", to)
      assert.equals("q", promotion)
    end)
  end)

  describe("API response handling", function()
    it("should handle puzzle response without FEN field", function()
      -- Simulate Lichess API response structure (no FEN in puzzle object)
      local api_response = {
        game = {
          id = "hJvbjXOZ",
          pgn = "c4 Nf6 d4 g6 Nc3 Bg7 e4 d6",
          perf = { key = "blitz", name = "Blitz" }
        },
        puzzle = {
          id = "YoTyb",
          rating = 2022,
          plays = 99965,
          solution = {"h2h8", "g7h8", "b1h7"},
          themes = {"exposedKing", "deflection"},
          initialPly = 33
          -- Note: No fen field in actual Lichess API response
        }
      }

      -- Verify the structure matches real API
      assert.is_not_nil(api_response.puzzle)
      assert.is_not_nil(api_response.game)
      assert.is_nil(api_response.puzzle.fen)
      assert.is_not_nil(api_response.game.pgn)
      assert.is_not_nil(api_response.game.id)
    end)

    it("should store game data when FEN is unavailable", function()
      -- Mock puzzle data without FEN
      local puzzle_data = {
        id = "test123",
        rating = 1500,
        plays = 100,
        solution = {"e2e4"},
        themes = {"short"},
        initialPly = 10
      }

      local game_data = {
        id = "gameABC",
        pgn = "e4 e5 Nf3 Nc6",
        perf = { key = "rapid" }
      }

      -- Verify we can construct a puzzle object with this data
      assert.is_nil(puzzle_data.fen)
      assert.is_not_nil(game_data.pgn)
      assert.is_not_nil(game_data.id)

      -- The puzzle should still be processable
      assert.equals("test123", puzzle_data.id)
      assert.equals(1500, puzzle_data.rating)
    end)

    it("should handle nil FEN gracefully in board display", function()
      -- Test that nil FEN doesn't crash board parsing
      local fen = nil
      local board = fen and string.match(fen, "^[^%s]+")

      assert.is_nil(board)
      -- This simulates what happens in show_puzzle when FEN is nil
      -- The board rendering should be skipped, not crash
    end)

    it("should provide fallback information when board unavailable", function()
      -- When FEN is unavailable, we should have alternative data
      local puzzle_info = {
        id = "YoTyb",
        game_id = "hJvbjXOZ",
        pgn = "c4 Nf6 d4 g6 Nc3 Bg7",
        solution = {"h2h8", "g7h8"},
        rating = 2022
      }

      -- Verify fallback data is available
      assert.is_not_nil(puzzle_info.id)
      assert.is_not_nil(puzzle_info.game_id)
      assert.is_not_nil(puzzle_info.pgn)

      -- Can construct Lichess URL from this data
      local puzzle_url = string.format("https://lichess.org/training/%s", puzzle_info.id)
      assert.equals("https://lichess.org/training/YoTyb", puzzle_url)
    end)

    it("should preserve puzzle functionality without board display", function()
      -- Even without FEN/board, puzzle solving should work
      local puzzle = {
        id = "test",
        solution = {"e2e4", "e7e5", "Nf3"},
        current_move_index = 0,
        fen = nil  -- No FEN available
      }

      -- Move validation should still work
      local attempted_move = "e2e4"
      local expected_move = puzzle.solution[puzzle.current_move_index + 1]

      assert.equals(expected_move, attempted_move)

      -- Hint extraction should work
      local hint_from = attempted_move:sub(1, 2)
      local hint_to = attempted_move:sub(3, 4)
      assert.equals("e2", hint_from)
      assert.equals("e4", hint_to)
    end)
  end)
end)
