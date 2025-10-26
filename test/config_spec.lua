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
      assert.are.equal('reuse', cfg.ui.puzzle_window_mode)
    end)
  end)

  describe('configuration setup', function()
    it('should merge user config with defaults', function()
      config.setup({
        lichess = {
          token = 'test_token',
          timeout = 15000
        }
      })

      local cfg = config.get()
      assert.are.equal('test_token', cfg.lichess.token)
      assert.are.equal(15000, cfg.lichess.timeout)
      assert.are.equal('https://lichess.org/api', cfg.lichess.base_url) -- should keep default
    end)
  end)

  describe('config getters', function()
    it('should return specific config sections', function()
      config.setup({
        lichess = { token = 'test' }
      })

      local lichess_cfg = config.get_lichess_config()
      assert.are.equal('test', lichess_cfg.token)
    end)

    it('should return ui config section', function()
      config.setup({
        ui = { puzzle_window_mode = 'split' }
      })

      local ui_cfg = config.get_ui_config()
      assert.are.equal('split', ui_cfg.puzzle_window_mode)
    end)

    it('should return default ui config when not specified', function()
      config.setup({})

      local ui_cfg = config.get_ui_config()
      assert.are.equal('reuse', ui_cfg.puzzle_window_mode)
    end)
  end)
end)
