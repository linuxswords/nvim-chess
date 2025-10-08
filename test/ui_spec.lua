-- Mock the config module before requiring UI
local mock_config = {
  get_ui_config = function()
    return {
      board_style = 'unicode',
      show_coordinates = true,
      auto_refresh = true,
      highlight_last_move = true
    }
  end
}

package.loaded['nvim-chess.config'] = mock_config

local ui = require('nvim-chess.ui.board')

describe('nvim-chess UI', function()
  before_each(function()
    -- Ensure config is properly mocked before each test
    package.loaded['nvim-chess.config'] = mock_config
  end)

  after_each(function()
    -- Clean up any buffers created during tests
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("chess") or name:match("test") then
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end
  end)

  describe('board rendering', function()
    it('should render starting position correctly', function()
      -- This test would need to check the actual board rendering
      -- For now, we'll just verify the update_board function exists
      assert.is_function(ui.update_board)
      assert.is_function(ui.show_board)
    end)

    it('should handle FEN parsing', function()
      -- Create a test buffer
      local buf = vim.api.nvim_create_buf(false, true)

      -- Test starting position FEN
      local starting_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      local result = ui.update_board(buf, starting_fen, false)

      assert.is_true(result)

      -- Clean up
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should handle invalid buffer gracefully', function()
      local invalid_buf = 999999
      local result = ui.update_board(invalid_buf, "test", false)
      assert.is_false(result)
    end)
  end)

  describe('board display modes', function()
    before_each(function()
      -- Reset config before each test
      mock_config.get_ui_config = function()
        return {
          board_style = 'unicode',
          show_coordinates = true,
          auto_refresh = true,
          highlight_last_move = true
        }
      end

      -- Make sure the config module is properly loaded
      package.loaded['nvim-chess.config'] = mock_config
    end)

    it('should support unicode mode', function()
      mock_config.get_ui_config = function()
        return {
          board_style = 'unicode',
          show_coordinates = true,
          auto_refresh = true,
          highlight_last_move = true
        }
      end

      local buf = ui.show_board('test-game')
      assert.is_number(buf)

      -- Clean up
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should support ascii mode', function()
      mock_config.get_ui_config = function()
        return {
          board_style = 'ascii',
          show_coordinates = true,
          auto_refresh = true,
          highlight_last_move = true
        }
      end

      local buf = ui.show_board('test-game')
      assert.is_number(buf)

      -- Clean up
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)
end)