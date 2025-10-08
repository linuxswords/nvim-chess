local config = require('nvim-chess.config')

describe('nvim-chess config', function()
  before_each(function()
    -- Reset config before each test
    config.setup({})
  end)

  describe('default configuration', function()
    it('should have correct default values', function()
      local cfg = config.get()

      -- Lichess config
      assert.is_nil(cfg.lichess.token)
      assert.are.equal(30000, cfg.lichess.timeout)
      assert.are.equal('https://lichess.org/api', cfg.lichess.base_url)

      -- UI config
      assert.are.equal('unicode', cfg.ui.board_style)
      assert.is_true(cfg.ui.auto_refresh)
      assert.is_true(cfg.ui.show_coordinates)
      assert.is_true(cfg.ui.highlight_last_move)

      -- Game config
      assert.is_false(cfg.game.auto_accept_challenges)
      assert.are.equal('10+0', cfg.game.default_time_control)
    end)
  end)

  describe('configuration setup', function()
    it('should merge user config with defaults', function()
      config.setup({
        lichess = {
          token = 'test_token',
          timeout = 15000
        },
        ui = {
          board_style = 'ascii'
        }
      })

      local cfg = config.get()
      assert.are.equal('test_token', cfg.lichess.token)
      assert.are.equal(15000, cfg.lichess.timeout)
      assert.are.equal('https://lichess.org/api', cfg.lichess.base_url) -- should keep default
      assert.are.equal('ascii', cfg.ui.board_style)
      assert.is_true(cfg.ui.auto_refresh) -- should keep default
    end)

    it('should validate board_style', function()
      -- Mock vim.notify for testing
      local notify_called = false
      local notify_level = nil
      vim.notify = function(msg, level)
        notify_called = true
        notify_level = level
      end

      config.setup({
        ui = {
          board_style = 'invalid'
        }
      })

      local cfg = config.get()
      assert.are.equal('unicode', cfg.ui.board_style) -- should fallback to unicode
      assert.is_true(notify_called)
      assert.are.equal(vim.log.levels.WARN, notify_level)
    end)
  end)

  describe('config getters', function()
    it('should return specific config sections', function()
      config.setup({
        lichess = { token = 'test' },
        ui = { board_style = 'ascii' },
        game = { auto_accept_challenges = true }
      })

      local lichess_cfg = config.get_lichess_config()
      assert.are.equal('test', lichess_cfg.token)

      local ui_cfg = config.get_ui_config()
      assert.are.equal('ascii', ui_cfg.board_style)

      local game_cfg = config.get_game_config()
      assert.is_true(game_cfg.auto_accept_challenges)
    end)
  end)
end)