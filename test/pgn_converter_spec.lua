describe("PGN Converter", function()
  local pgn_converter

  before_each(function()
    package.loaded['nvim-chess.chess.pgn_converter'] = nil
    package.loaded['nvim-chess.chess.engine'] = nil
    package.loaded['nvim-chess.chess.san_parser'] = nil
    package.loaded['nvim-chess.chess.move_executor'] = nil

    pgn_converter = require('nvim-chess.chess.pgn_converter')
  end)

  describe("PGN parsing", function()
    it("should parse space-separated moves", function()
      local pgn = "e4 e5 Nf3 Nc6"
      local moves = pgn_converter.parse_pgn_moves(pgn)

      assert.equals(4, #moves)
      assert.equals("e4", moves[1])
      assert.equals("e5", moves[2])
      assert.equals("Nf3", moves[3])
      assert.equals("Nc6", moves[4])
    end)

    it("should skip move numbers", function()
      local pgn = "1. e4 e5 2. Nf3 Nc6"
      local moves = pgn_converter.parse_pgn_moves(pgn)

      assert.equals(4, #moves)
      assert.equals("e4", moves[1])
      assert.equals("e5", moves[2])
    end)

    it("should handle empty PGN", function()
      local moves = pgn_converter.parse_pgn_moves("")

      assert.equals(0, #moves)
    end)

    it("should handle real Lichess PGN format", function()
      -- Actual format from Lichess API
      local pgn = "c4 Nf6 d4 g6 Nc3 Bg7 e4 d6"
      local moves = pgn_converter.parse_pgn_moves(pgn)

      assert.equals(8, #moves)
      assert.equals("c4", moves[1])
      assert.equals("d6", moves[8])
    end)
  end)

  describe("PGN to FEN conversion", function()
    it("should convert empty PGN (starting position)", function()
      local fen = pgn_converter.pgn_to_fen("", 0)

      assert.equals("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", fen)
    end)

    it("should convert after 1 move", function()
      local fen = pgn_converter.pgn_to_fen("e4", 1)

      assert.is_not_nil(fen)
      assert.is_true(fen:find("e3") ~= nil)  -- en passant target
      assert.is_true(fen:find(" b ") ~= nil)  -- black to move
    end)

    it("should convert after 2 moves", function()
      local fen = pgn_converter.pgn_to_fen("e4 e5", 2)

      assert.is_not_nil(fen)
      assert.is_true(fen:find(" w ") ~= nil)  -- white to move
    end)

    it("should convert opening sequence", function()
      local pgn = "e4 e5 Nf3 Nc6 Bc4"
      local fen = pgn_converter.pgn_to_fen(pgn, 5)

      assert.is_not_nil(fen)
      -- Italian Game position after 5 moves
      assert.is_true(fen:find(" b ") ~= nil)  -- black to move
    end)

    it("should handle ply beyond available moves", function()
      local fen, err = pgn_converter.pgn_to_fen("e4 e5", 10)

      assert.is_nil(fen)
      assert.is_not_nil(err)
      assert.is_true(err:find("exceeds") ~= nil)
    end)

    it("should convert real Lichess puzzle PGN", function()
      -- Example from actual Lichess puzzle
      local pgn = "c4 Nf6 d4 g6 Nc3 Bg7 e4 d6"
      local fen = pgn_converter.pgn_to_fen(pgn, 8)

      assert.is_not_nil(fen)
      -- Should be valid FEN
      assert.is_true(fen:match("^[%w/]+ %w [%w%-]+ [%w%-]+ %d+ %d+$") ~= nil)
    end)

    it("should handle castling in PGN", function()
      -- Setup a game where white castles
      local pgn = "e4 e5 Nf3 Nc6 Bc4 Bc5 O-O"
      local fen = pgn_converter.pgn_to_fen(pgn, 7)

      assert.is_not_nil(fen)
      -- After castling, white's castling rights should be removed
      -- Check castling rights section (4th field of FEN)
      local parts = {}
      for part in fen:gmatch("%S+") do table.insert(parts, part) end
      -- Castling rights should not contain 'K' or 'Q' for white
      assert.is_false(parts[3]:find("K") ~= nil)
      assert.is_false(parts[3]:find("Q") ~= nil)
    end)

    it("should handle promotion in PGN", function()
      -- Use a custom starting FEN where white pawn is on 7th rank, ready to promote
      local starting_fen = "8/P7/8/8/8/8/8/8 w - - 0 1"
      local pgn = "a8=Q"
      local fen = pgn_converter.pgn_to_fen(pgn, 1, starting_fen)

      assert.is_not_nil(fen)
      -- Should have a queen on a8
      local parts = {}
      for part in fen:gmatch("%S+") do table.insert(parts, part) end
      -- Check position part contains a Queen on rank 8
      assert.is_true(parts[1]:find("Q") ~= nil)
    end)
  end)

  describe("PGN validation", function()
    it("should validate correct PGN", function()
      local valid = pgn_converter.validate_pgn("e4 e5 Nf3 Nc6")

      assert.is_true(valid)
    end)

    it("should reject invalid PGN", function()
      local valid, err = pgn_converter.validate_pgn("xyz abc")

      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it("should reject empty PGN", function()
      local valid, err = pgn_converter.validate_pgn("")

      assert.is_false(valid)
      assert.is_not_nil(err)
    end)
  end)

  describe("FEN list generation", function()
    it("should generate FEN for each ply", function()
      local pgn = "e4 e5 Nf3"
      local fen_list = pgn_converter.pgn_to_fen_list(pgn)

      assert.is_not_nil(fen_list)
      assert.equals(4, #fen_list)  -- starting + 3 moves

      -- First should be starting position
      assert.equals("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", fen_list[1])

      -- Each subsequent should be different
      assert.is_not.equals(fen_list[1], fen_list[2])
      assert.is_not.equals(fen_list[2], fen_list[3])
    end)
  end)

  describe("Real puzzle scenarios", function()
    it("should handle puzzle with 33 plies", function()
      -- Simulating a real puzzle with many moves
      local pgn = "e4 e5 Nf3 Nc6 Bc4 Bc5 O-O Nf6 d3 d6 Bg5 h6 Bh4 g5 Bg3 h5 h3"
      local fen = pgn_converter.pgn_to_fen(pgn, 17)

      assert.is_not_nil(fen)
    end)

    it("should handle complex middlegame position", function()
      local pgn = "d4 d5 c4 e6 Nc3 Nf6 Bg5 Be7 e3 O-O Nf3 Nbd7"
      local fen = pgn_converter.pgn_to_fen(pgn, 12)

      assert.is_not_nil(fen)
      -- Should be valid FEN format
      assert.is_true(fen:match("^[%w/]+ %w") ~= nil)
    end)

    it("should handle capture sequences", function()
      local pgn = "e4 d5 exd5 Qxd5 Nc3 Qa5"
      local fen = pgn_converter.pgn_to_fen(pgn, 6)

      assert.is_not_nil(fen)
    end)

    it("should handle en passant scenario", function()
      local pgn = "e4 a6 e5 d5 exd6"
      local fen = pgn_converter.pgn_to_fen(pgn, 5)

      assert.is_not_nil(fen)
      -- d6 should have a white pawn (en passant capture)
    end)
  end)

  describe("Error handling", function()
    it("should handle illegal move gracefully", function()
      -- Trying to move a piece that doesn't exist or can't move there
      local fen, err = pgn_converter.pgn_to_fen("e4 e5 Nf7", 3)

      assert.is_nil(fen)
      assert.is_not_nil(err)
    end)

    it("should handle invalid starting FEN", function()
      local fen, err = pgn_converter.pgn_to_fen("e4", 1, "invalid_fen")

      assert.is_nil(fen)
      assert.is_not_nil(err)
    end)
  end)
end)
