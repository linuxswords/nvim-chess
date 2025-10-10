describe("Chess Engine", function()
  local engine

  before_each(function()
    package.loaded['nvim-chess.chess.engine'] = nil
    engine = require('nvim-chess.chess.engine')
  end)

  describe("Board state creation", function()
    it("should create starting position", function()
      local board = engine.create_starting_position()

      assert.is_not_nil(board)
      assert.equals("white", board.to_move)
      assert.equals(1, board.fullmove)
      assert.equals(0, board.halfmove)
    end)

    it("should create board from FEN", function()
      local fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      local board = engine.create_board_from_fen(fen)

      assert.is_not_nil(board)
      assert.equals("white", board.to_move)

      -- Check some pieces
      local white_rook = board.position[1][1]
      assert.is_not_nil(white_rook)
      assert.equals("white", white_rook.color)
      assert.equals("rook", white_rook.type)

      local black_king = board.position[8][5]
      assert.is_not_nil(black_king)
      assert.equals("black", black_king.color)
      assert.equals("king", black_king.type)
    end)

    it("should parse castling rights from FEN", function()
      local fen = "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"
      local board = engine.create_board_from_fen(fen)

      assert.is_true(board.castling.white_kingside)
      assert.is_true(board.castling.white_queenside)
      assert.is_true(board.castling.black_kingside)
      assert.is_true(board.castling.black_queenside)
    end)

    it("should parse partial castling rights", function()
      local fen = "r3k2r/8/8/8/8/8/8/R3K2R w Kq - 0 1"
      local board = engine.create_board_from_fen(fen)

      assert.is_true(board.castling.white_kingside)
      assert.is_false(board.castling.white_queenside)
      assert.is_false(board.castling.black_kingside)
      assert.is_true(board.castling.black_queenside)
    end)

    it("should parse en passant target square", function()
      local fen = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
      local board = engine.create_board_from_fen(fen)

      assert.equals("e6", board.en_passant)
    end)
  end)

  describe("FEN generation", function()
    it("should generate starting position FEN", function()
      local board = engine.create_starting_position()
      local fen = engine.board_to_fen(board)

      assert.equals("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", fen)
    end)

    it("should generate FEN with pieces removed", function()
      local board = engine.create_starting_position()
      -- Remove white e2 pawn
      board.position[2][5] = nil

      local fen = engine.board_to_fen(board)

      assert.is_true(fen:find("PPPP1PPP") ~= nil)
    end)

    it("should generate FEN with correct to_move", function()
      local board = engine.create_starting_position()
      board.to_move = "black"

      local fen = engine.board_to_fen(board)

      assert.is_true(fen:find(" b ") ~= nil)
    end)

    it("should generate FEN with no castling rights", function()
      local board = engine.create_starting_position()
      board.castling = {
        white_kingside = false,
        white_queenside = false,
        black_kingside = false,
        black_queenside = false
      }

      local fen = engine.board_to_fen(board)

      assert.is_true(fen:find(" %- ") ~= nil)
    end)
  end)

  describe("Helper functions", function()
    it("should convert file to letter", function()
      assert.equals("a", engine.file_to_letter(1))
      assert.equals("h", engine.file_to_letter(8))
      assert.equals("e", engine.file_to_letter(5))
    end)

    it("should convert letter to file", function()
      assert.equals(1, engine.letter_to_file("a"))
      assert.equals(8, engine.letter_to_file("h"))
      assert.equals(5, engine.letter_to_file("e"))
    end)

    it("should convert indices to square", function()
      assert.equals("e4", engine.indices_to_square(4, 5))
      assert.equals("a1", engine.indices_to_square(1, 1))
      assert.equals("h8", engine.indices_to_square(8, 8))
    end)

    it("should find pieces by type and color", function()
      local board = engine.create_starting_position()
      local white_pawns = engine.find_pieces(board, "pawn", "white")

      assert.equals(8, #white_pawns)
    end)

    it("should get piece at square", function()
      local board = engine.create_starting_position()
      local piece = engine.get_piece_at(board, "e2")

      assert.is_not_nil(piece)
      assert.equals("white", piece.color)
      assert.equals("pawn", piece.type)
    end)

    it("should set piece at square", function()
      local board = engine.create_starting_position()
      local success = engine.set_piece_at(board, "e4", {color = "white", type = "queen"})

      assert.is_true(success)

      local piece = engine.get_piece_at(board, "e4")
      assert.equals("queen", piece.type)
    end)
  end)

  describe("Board copying", function()
    it("should deep copy board state", function()
      local board = engine.create_starting_position()
      local copy = engine.copy_board_state(board)

      -- Modify copy
      copy.position[2][5] = nil
      copy.to_move = "black"

      -- Original should be unchanged
      assert.is_not_nil(board.position[2][5])
      assert.equals("white", board.to_move)
    end)
  end)
end)
