local utils = require('nvim-chess.utils')

describe('nvim-chess utils', function()
  describe('square parsing', function()
    it('should parse valid squares', function()
      local coords = utils.parse_square('e4')
      assert.are.equal(5, coords.file)
      assert.are.equal(4, coords.rank)

      coords = utils.parse_square('a1')
      assert.are.equal(1, coords.file)
      assert.are.equal(1, coords.rank)

      coords = utils.parse_square('h8')
      assert.are.equal(8, coords.file)
      assert.are.equal(8, coords.rank)
    end)

    it('should return nil for invalid squares', function()
      assert.is_nil(utils.parse_square('i1'))  -- invalid file
      assert.is_nil(utils.parse_square('a9'))  -- invalid rank
      assert.is_nil(utils.parse_square(''))    -- empty
      assert.is_nil(utils.parse_square('e'))   -- incomplete
      assert.is_nil(utils.parse_square('ee4')) -- too long
    end)
  end)

  describe('coordinate conversion', function()
    it('should convert squares to coordinates', function()
      local file, rank = utils.square_to_coords('e4')
      assert.are.equal(5, file)
      assert.are.equal(4, rank)
    end)

    it('should convert coordinates to squares', function()
      local square = utils.coords_to_square(5, 4)
      assert.are.equal('e4', square)

      square = utils.coords_to_square(1, 1)
      assert.are.equal('a1', square)

      square = utils.coords_to_square(8, 8)
      assert.are.equal('h8', square)
    end)

    it('should return nil for invalid coordinates', function()
      assert.is_nil(utils.coords_to_square(0, 4))  -- invalid file
      assert.is_nil(utils.coords_to_square(9, 4))  -- invalid file
      assert.is_nil(utils.coords_to_square(4, 0))  -- invalid rank
      assert.is_nil(utils.coords_to_square(4, 9))  -- invalid rank
    end)
  end)

  describe('move validation', function()
    it('should validate UCI move format', function()
      assert.is_true(utils.is_valid_move_format('e2e4'))
      assert.is_true(utils.is_valid_move_format('a7a8q'))  -- promotion
      assert.is_true(utils.is_valid_move_format('e1g1'))   -- castling
      assert.is_true(utils.is_valid_move_format('h7h8r'))  -- rook promotion
    end)

    it('should reject invalid move formats', function()
      assert.is_false(utils.is_valid_move_format('e2e9'))   -- invalid rank
      assert.is_false(utils.is_valid_move_format('i2e4'))   -- invalid file
      assert.is_false(utils.is_valid_move_format('e2'))     -- incomplete
      assert.is_false(utils.is_valid_move_format('e2e4x'))  -- invalid promotion
      assert.is_false(utils.is_valid_move_format(''))       -- empty
    end)
  end)

  describe('UCI move parsing', function()
    it('should parse valid UCI moves', function()
      local move = utils.parse_uci_move('e2e4')
      assert.are.equal('e2', move.from.square)
      assert.are.equal('e4', move.to.square)
      assert.are.equal(5, move.from.file)
      assert.are.equal(2, move.from.rank)
      assert.are.equal(5, move.to.file)
      assert.are.equal(4, move.to.rank)
      assert.is_nil(move.promotion)
    end)

    it('should parse promotion moves', function()
      local move = utils.parse_uci_move('a7a8q')
      assert.are.equal('a7', move.from.square)
      assert.are.equal('a8', move.to.square)
      assert.are.equal('q', move.promotion)
    end)

    it('should return nil for invalid moves', function()
      assert.is_nil(utils.parse_uci_move('e2e9'))
      assert.is_nil(utils.parse_uci_move('invalid'))
      assert.is_nil(utils.parse_uci_move(''))
    end)
  end)

  describe('time formatting', function()
    it('should format seconds correctly', function()
      assert.are.equal('0:30', utils.format_time(30))
      assert.are.equal('1:00', utils.format_time(60))
      assert.are.equal('5:30', utils.format_time(330))
      assert.are.equal('1:05:30', utils.format_time(3930))
    end)

    it('should handle nil input', function()
      assert.are.equal('N/A', utils.format_time(nil))
    end)
  end)

  describe('JSON parsing', function()
    it('should parse valid nd-json lines', function()
      local json = utils.parse_ndjson_line('{"type":"test","data":"value"}')
      assert.are.equal('test', json.type)
      assert.are.equal('value', json.data)
    end)

    it('should return nil for invalid JSON', function()
      assert.is_nil(utils.parse_ndjson_line('invalid json'))
      assert.is_nil(utils.parse_ndjson_line(''))
      assert.is_nil(utils.parse_ndjson_line(nil))
    end)

    it('should split nd-json text', function()
      local text = '{"type":"event1"}\n{"type":"event2"}\n{"type":"event3"}'
      local events = utils.split_ndjson(text)
      assert.are.equal(3, #events)
      assert.are.equal('event1', events[1].type)
      assert.are.equal('event2', events[2].type)
      assert.are.equal('event3', events[3].type)
    end)
  end)
end)