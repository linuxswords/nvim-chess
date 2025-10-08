local M = {}

local mock = require('nvim-chess.test-utils.mock')

-- Demo scenarios for testing the plugin
function M.run_basic_demo()
  vim.notify("Starting nvim-chess basic demo...", vim.log.levels.INFO)

  -- Enable mock mode
  mock.enable()

  -- Setup the plugin with mock token
  require('nvim-chess').setup({
    lichess = {
      token = "demo_token_123"
    }
  })

  -- Wait a bit for setup
  vim.defer_fn(function()
    -- Test profile
    vim.notify("Demo: Testing profile...", vim.log.levels.INFO)
    require('nvim-chess').get_profile()

    vim.defer_fn(function()
      -- Test creating a game
      vim.notify("Demo: Creating a game...", vim.log.levels.INFO)
      require('nvim-chess').new_game("5+3")

      vim.defer_fn(function()
        -- Test showing board
        vim.notify("Demo: Showing board...", vim.log.levels.INFO)
        require('nvim-chess').show_board("demo_game")

        vim.defer_fn(function()
          -- Test making a move
          vim.notify("Demo: Making a move...", vim.log.levels.INFO)
          require('nvim-chess.game.manager').make_move("e2e4")

          vim.notify("Demo completed! Check the buffers that were created.", vim.log.levels.INFO)
        end, 1000)
      end, 1000)
    end, 1000)
  end, 500)
end

function M.test_error_scenarios()
  vim.notify("Testing error scenarios...", vim.log.levels.INFO)

  mock.enable()

  -- Test without authentication
  local auth = require('nvim-chess.auth.manager')
  auth.clear_session()
  vim.notify("Testing without auth...", vim.log.levels.INFO)
  require('nvim-chess').get_profile()

  vim.defer_fn(function()
    -- Test API errors
    mock.simulate_api_error("profile", "Network error")
    auth.set_token("test_token")

    vim.notify("Testing API error...", vim.log.levels.INFO)
    require('nvim-chess').get_profile()

    vim.defer_fn(function()
      vim.notify("Error scenario testing completed.", vim.log.levels.INFO)
    end, 1000)
  end, 1000)
end

function M.test_game_flow()
  vim.notify("Testing complete game flow...", vim.log.levels.INFO)

  mock.enable()
  require('nvim-chess').setup({
    lichess = { token = "demo_token" }
  })

  vim.defer_fn(function()
    -- Create and join a game
    local game_id = "test_game_789"
    mock.set_game_state(game_id, "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")

    require('nvim-chess.game.manager').join_game(game_id)

    vim.defer_fn(function()
      -- Make some moves
      require('nvim-chess.game.manager').make_move("e7e5")

      vim.defer_fn(function()
        require('nvim-chess.game.manager').make_move("g1f3")
        vim.notify("Game flow test completed!", vim.log.levels.INFO)
      end, 1000)
    end, 1000)
  end, 500)
end

function M.benchmark_board_rendering()
  vim.notify("Benchmarking board rendering...", vim.log.levels.INFO)

  mock.enable()
  local ui = require('nvim-chess.ui.board')

  local start_time = vim.loop.hrtime()
  local iterations = 100

  for i = 1, iterations do
    local buf = ui.show_board("bench_" .. i)
    if buf then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local end_time = vim.loop.hrtime()
  local duration = (end_time - start_time) / 1000000  -- Convert to milliseconds

  vim.notify(string.format("Rendered %d boards in %.2fms (%.2fms per board)",
    iterations, duration, duration / iterations), vim.log.levels.INFO)
end

function M.interactive_test()
  vim.notify("Starting interactive test mode...", vim.log.levels.INFO)

  mock.enable()
  require('nvim-chess').setup({
    lichess = { token = "interactive_token" }
  })

  -- Show available commands
  local commands = {
    ":ChessProfile - View profile",
    ":ChessNewGame 5+3 - Create a game",
    ":ChessSeekGame 10+0 - Seek a game",
    ":ChessShowBoard - Show board",
    ":ChessMove e2e4 - Make a move",
    ":lua require('nvim-chess.test-utils.demo').stop_interactive() - Stop test mode"
  }

  vim.notify("Interactive test mode active. Try these commands:", vim.log.levels.INFO)
  for _, cmd in ipairs(commands) do
    vim.notify("  " .. cmd, vim.log.levels.INFO)
  end
end

function M.stop_interactive()
  mock.disable()
  vim.notify("Interactive test mode stopped.", vim.log.levels.INFO)
end

-- Quick test function that can be called from command line
function M.quick_test()
  M.run_basic_demo()
end

return M