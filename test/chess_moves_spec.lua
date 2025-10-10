describe("Chess Moves", function()
  local engine, san_parser, move_executor

  before_each(function()
    package.loaded['nvim-chess.chess.engine'] = nil
    package.loaded['nvim-chess.chess.san_parser'] = nil
    package.loaded['nvim-chess.chess.move_executor'] = nil

    engine = require('nvim-chess.chess.engine')
    san_parser = require('nvim-chess.chess.san_parser')
    move_executor = require('nvim-chess.chess.move_executor')
  end)

  describe("SAN parsing", function()
    it("should parse simple pawn moves", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("e4", board)

      assert.is_not_nil(move_data)
      assert.equals("pawn", move_data.piece)
      assert.equals("e4", move_data.to)
      assert.is_false(move_data.capture)
    end)

    it("should parse piece moves", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("Nf3", board)

      assert.equals("knight", move_data.piece)
      assert.equals("f3", move_data.to)
    end)

    it("should parse captures", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("exd5", board)

      assert.equals("pawn", move_data.piece)
      assert.equals("d5", move_data.to)
      assert.is_true(move_data.capture)
    end)

    it("should parse kingside castling", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("O-O", board)

      assert.equals("kingside", move_data.castling)
      assert.equals("king", move_data.piece)
    end)

    it("should parse queenside castling", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("O-O-O", board)

      assert.equals("queenside", move_data.castling)
      assert.equals("king", move_data.piece)
    end)

    it("should parse promotion", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("e8=Q", board)

      assert.equals("pawn", move_data.piece)
      assert.equals("e8", move_data.to)
      assert.equals("queen", move_data.promotion)
    end)

    it("should parse promotion with capture", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("exd8=Q", board)

      assert.equals("pawn", move_data.piece)
      assert.equals("d8", move_data.to)
      assert.equals("queen", move_data.promotion)
      assert.is_true(move_data.capture)
    end)

    it("should parse disambiguation by file", function()
      local board = engine.create_starting_position()
      local move_data = san_parser.parse_san("Nbd2", board)

      assert.equals("knight", move_data.piece)
      assert.equals("d2", move_data.to)
      assert.equals(2, move_data.file_hint)  -- b-file = 2
    end)

    it("should strip check and checkmate symbols", function()
      local board = engine.create_starting_position()
      local move_data1 = san_parser.parse_san("Nf3+", board)
      local move_data2 = san_parser.parse_san("Qh7#", board)

      assert.equals("f3", move_data1.to)
      assert.equals("h7", move_data2.to)
    end)
  end)

  describe("Move execution", function()
    it("should execute pawn move", function()
      local board = engine.create_starting_position()
      board = move_executor.execute_move(board, "e4")

      assert.is_nil(board.position[2][5])  -- e2 is empty
      assert.is_not_nil(board.position[4][5])  -- e4 has pawn
      assert.equals("pawn", board.position[4][5].type)
      assert.equals("black", board.to_move)
    end)

    it("should execute knight move", function()
      local board = engine.create_starting_position()
      board = move_executor.execute_move(board, "Nf3")

      assert.is_nil(board.position[1][7])  -- g1 is empty
      assert.is_not_nil(board.position[3][6])  -- f3 has knight
      assert.equals("knight", board.position[3][6].type)
    end)

    it("should update turn after move", function()
      local board = engine.create_starting_position()

      assert.equals("white", board.to_move)
      board = move_executor.execute_move(board, "e4")
      assert.equals("black", board.to_move)
      board = move_executor.execute_move(board, "e5")
      assert.equals("white", board.to_move)
    end)

    it("should update fullmove counter", function()
      local board = engine.create_starting_position()

      assert.equals(1, board.fullmove)
      board = move_executor.execute_move(board, "e4")
      assert.equals(1, board.fullmove)  -- Still move 1 after white moves
      board = move_executor.execute_move(board, "e5")
      assert.equals(2, board.fullmove)  -- Move 2 after black moves
    end)

    it("should set en passant target after two-square pawn move", function()
      local board = engine.create_starting_position()
      board = move_executor.execute_move(board, "e4")

      assert.equals("e3", board.en_passant)
    end)

    it("should clear en passant target after other moves", function()
      local board = engine.create_starting_position()
      board = move_executor.execute_move(board, "e4")
      assert.equals("e3", board.en_passant)

      board = move_executor.execute_move(board, "Nf6")
      assert.is_nil(board.en_passant)
    end)

    it("should execute kingside castling", function()
      -- Setup position where white can castle kingside
      local fen = "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"
      local board = engine.create_board_from_fen(fen)

      board = move_executor.execute_move(board, "O-O")

      -- King should be on g1
      assert.is_not_nil(board.position[1][7])
      assert.equals("king", board.position[1][7].type)

      -- Rook should be on f1
      assert.is_not_nil(board.position[1][6])
      assert.equals("rook", board.position[1][6].type)

      -- e1 and h1 should be empty
      assert.is_nil(board.position[1][5])
      assert.is_nil(board.position[1][8])

      -- Castling rights should be removed
      assert.is_false(board.castling.white_kingside)
      assert.is_false(board.castling.white_queenside)
    end)

    it("should execute queenside castling", function()
      local fen = "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"
      local board = engine.create_board_from_fen(fen)

      board = move_executor.execute_move(board, "O-O-O")

      -- King should be on c1
      assert.is_not_nil(board.position[1][3])
      assert.equals("king", board.position[1][3].type)

      -- Rook should be on d1
      assert.is_not_nil(board.position[1][4])
      assert.equals("rook", board.position[1][4].type)

      -- e1 and a1 should be empty
      assert.is_nil(board.position[1][5])
      assert.is_nil(board.position[1][1])
    end)

    it("should remove castling rights after king moves", function()
      local board = engine.create_starting_position()

      assert.is_true(board.castling.white_kingside)
      assert.is_true(board.castling.white_queenside)

      -- Move king
      local fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R w KQkq - 0 1"
      board = engine.create_board_from_fen(fen)
      board = move_executor.execute_move(board, "Kf1")

      assert.is_false(board.castling.white_kingside)
      assert.is_false(board.castling.white_queenside)
    end)

    it("should remove castling rights after rook moves", function()
      local fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKB1R w KQkq - 0 1"
      local board = engine.create_board_from_fen(fen)

      assert.is_true(board.castling.white_kingside)

      board = move_executor.execute_move(board, "Rg1")

      assert.is_false(board.castling.white_kingside)
      assert.is_true(board.castling.white_queenside)  -- Still can castle queenside
    end)

    it("should handle pawn promotion", function()
      -- Setup position where white pawn can promote
      local fen = "8/P7/8/8/8/8/8/8 w - - 0 1"
      local board = engine.create_board_from_fen(fen)

      board = move_executor.execute_move(board, "a8=Q")

      -- a8 should have a queen
      assert.is_not_nil(board.position[8][1])
      assert.equals("queen", board.position[8][1].type)
      assert.equals("white", board.position[8][1].color)
    end)

    it("should reset halfmove clock on pawn move", function()
      local board = engine.create_starting_position()
      board.halfmove = 5

      board = move_executor.execute_move(board, "e4")

      assert.equals(0, board.halfmove)
    end)

    it("should increment halfmove clock on piece move", function()
      local board = engine.create_starting_position()
      board.halfmove = 0

      board = move_executor.execute_move(board, "Nf3")

      assert.equals(1, board.halfmove)
    end)
  end)

  describe("Complex sequences", function()
    it("should execute Scholar's Mate sequence", function()
      local board = engine.create_starting_position()

      board = move_executor.execute_move(board, "e4")
      board = move_executor.execute_move(board, "e5")
      board = move_executor.execute_move(board, "Bc4")
      board = move_executor.execute_move(board, "Nc6")
      board = move_executor.execute_move(board, "Qh5")
      board = move_executor.execute_move(board, "Nf6")
      board = move_executor.execute_move(board, "Qxf7")

      -- Queen should be on f7
      assert.is_not_nil(board.position[7][6])
      assert.equals("queen", board.position[7][6].type)
      assert.equals("white", board.position[7][6].color)
    end)

    it("should execute Italian Game opening", function()
      local board = engine.create_starting_position()

      board = move_executor.execute_move(board, "e4")
      board = move_executor.execute_move(board, "e5")
      board = move_executor.execute_move(board, "Nf3")
      board = move_executor.execute_move(board, "Nc6")
      board = move_executor.execute_move(board, "Bc4")

      assert.is_not_nil(board.position[4][3])
      assert.equals("bishop", board.position[4][3].type)
    end)
  end)
end)
