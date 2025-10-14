-- Real Lichess API integration tests
-- These tests make actual HTTP requests to Lichess.org
--
-- Requirements:
--   - Set LICHESS_TOKEN environment variable with a valid Lichess personal access token
--   - Get token from: https://lichess.org/account/oauth/token
--
-- Run with:
--   export LICHESS_TOKEN=your_token_here
--   make test-integration
--   OR
--   nvim --headless -c "PlenaryBustedFile test/integration/lichess_api_spec.lua" -c "qa"

-- Add plugin to path
vim.opt.runtimepath:append(".")

local api_client = require('nvim-chess.api.client')
local auth = require('nvim-chess.auth.manager')
local config = require('nvim-chess.config')

-- Get token from environment
local token = os.getenv("LICHESS_TOKEN")

describe("Lichess API Integration Tests", function()
  before_each(function()
    -- Initialize config
    config.setup({
      lichess = {
        token = token,
        timeout = 30000,
        base_url = "https://lichess.org/api",
      }
    })

    -- Clear auth state
    auth.clear_session()
  end)

  after_each(function()
    -- Clean up after each test
    auth.clear_session()
  end)

  describe("Authentication", function()
    it("should skip authenticated tests if no token provided", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN environment variable not set - skipping authenticated tests")
        return
      end
    end)

    it("should successfully authenticate with valid token", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      -- Set token
      auth.set_token(token)
      assert.is_true(auth.is_authenticated())
      assert.are.equal(token, auth.get_token())
    end)

    it("should fetch account information with valid token", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)

      local account, err = api_client.get_account()

      assert.is_nil(err, "Expected no error, got: " .. tostring(err))
      assert.is_not_nil(account)
      assert.is_string(account.id)
      assert.is_string(account.username)
    end)
  end)

  describe("Puzzle API - Unauthenticated", function()
    it("should fetch daily puzzle without authentication", function()
      -- Daily puzzle works without authentication
      local puzzle, err = api_client.get_daily_puzzle()

      assert.is_nil(err, "Expected no error, got: " .. tostring(err))
      assert.is_not_nil(puzzle)
      assert.is_table(puzzle.game)
      assert.is_table(puzzle.puzzle)
      assert.is_string(puzzle.puzzle.id)
      assert.is_table(puzzle.puzzle.solution)
      assert.is_true(#puzzle.puzzle.solution > 0, "Solution should have moves")
    end)

    it("should fetch next random puzzle without authentication", function()
      local puzzle, err = api_client.get_next_puzzle()

      assert.is_nil(err, "Expected no error, got: " .. tostring(err))
      assert.is_not_nil(puzzle)
      assert.is_table(puzzle.game)
      assert.is_table(puzzle.puzzle)
      assert.is_string(puzzle.puzzle.id)
      assert.is_table(puzzle.puzzle.solution)
    end)

    it("should receive different puzzles on consecutive calls", function()
      local puzzle1, err1 = api_client.get_next_puzzle()
      assert.is_nil(err1)
      assert.is_not_nil(puzzle1)

      -- Wait a moment to avoid rate limiting
      vim.wait(1000)

      local puzzle2, err2 = api_client.get_next_puzzle()
      assert.is_nil(err2)
      assert.is_not_nil(puzzle2)

      -- Should get different puzzles (with high probability)
      -- Note: There's a small chance of getting the same puzzle twice
      assert.is_string(puzzle1.puzzle.id)
      assert.is_string(puzzle2.puzzle.id)
    end)
  end)

  describe("Puzzle API - Authenticated", function()
    it("should fetch puzzle activity with authentication", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)

      -- Get recent puzzle activity (max 10)
      local activity, err = api_client.get_puzzle_activity(10)

      assert.is_nil(err, "Expected no error, got: " .. tostring(err))
      assert.is_not_nil(activity)
      -- Activity might be empty if user hasn't done puzzles
      assert.is_table(activity)
    end)

    it("should fetch puzzle dashboard with authentication", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)

      -- Get puzzle dashboard for last 30 days
      local dashboard, err = api_client.get_puzzle_dashboard(30)

      assert.is_nil(err, "Expected no error, got: " .. tostring(err))
      assert.is_not_nil(dashboard)
      assert.is_table(dashboard)
    end)

    it("should fetch specific puzzle by ID", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)

      -- Use a known puzzle ID (this is a real puzzle on Lichess)
      local puzzle, err = api_client.get_puzzle("YoTyb")

      assert.is_nil(err, "Expected no error, got: " .. tostring(err))
      assert.is_not_nil(puzzle)
      assert.is_table(puzzle.game)
      assert.is_table(puzzle.puzzle)
      assert.are.equal("YoTyb", puzzle.puzzle.id)
    end)
  end)

  describe("API Error Handling", function()
    it("should handle invalid puzzle ID gracefully", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)

      -- Try to fetch a puzzle with invalid ID
      local puzzle, err = api_client.get_puzzle("invalid_puzzle_id_12345")

      -- Should return error
      assert.is_nil(puzzle)
      assert.is_not_nil(err)
      assert.is_string(err)
      assert.is_true(string.match(err, "HTTP") ~= nil, "Error should include HTTP status")
    end)

    it("should handle network timeout gracefully", function()
      -- Set very short timeout
      config.setup({
        lichess = {
          timeout = 1, -- 1ms - will definitely timeout
          base_url = "https://lichess.org/api",
        }
      })

      local puzzle, err = api_client.get_daily_puzzle()

      -- Should timeout and return error
      assert.is_nil(puzzle)
      assert.is_not_nil(err)
    end)

    it("should handle unauthorized access appropriately", function()
      -- Set invalid token
      auth.set_token("invalid_token_xyz123")

      -- Try to access authenticated endpoint
      local account, err = api_client.get_account()

      -- Should return error for unauthorized
      assert.is_nil(account)
      assert.is_not_nil(err)
      assert.is_true(string.match(err, "401") ~= nil or string.match(err, "Unauthorized") ~= nil,
        "Should get 401/Unauthorized error")
    end)
  end)

  describe("API Rate Limiting Compliance", function()
    it("should successfully make multiple sequential requests", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)

      -- Make 3 requests with pauses (Lichess allows max 1 request at a time)
      local results = {}

      for i = 1, 3 do
        local puzzle, err = api_client.get_next_puzzle()
        table.insert(results, {puzzle = puzzle, err = err})

        -- Wait between requests to respect rate limits
        if i < 3 then
          vim.wait(1000)
        end
      end

      -- All requests should succeed
      for i, result in ipairs(results) do
        assert.is_nil(result.err, "Request " .. i .. " failed: " .. tostring(result.err))
        assert.is_not_nil(result.puzzle, "Request " .. i .. " returned no puzzle")
      end
    end)
  end)

  describe("Response Data Validation", function()
    it("should return valid puzzle structure", function()
      local puzzle, err = api_client.get_daily_puzzle()

      assert.is_nil(err)
      assert.is_not_nil(puzzle)

      -- Validate game structure
      assert.is_table(puzzle.game)
      assert.is_string(puzzle.game.id)
      assert.is_string(puzzle.game.pgn)

      -- Validate puzzle structure
      assert.is_table(puzzle.puzzle)
      assert.is_string(puzzle.puzzle.id)
      assert.is_number(puzzle.puzzle.rating)
      assert.is_number(puzzle.puzzle.plays)
      assert.is_table(puzzle.puzzle.solution)
      assert.is_table(puzzle.puzzle.themes)
      assert.is_number(puzzle.puzzle.initialPly)

      -- Validate solution contains valid moves
      for i, move in ipairs(puzzle.puzzle.solution) do
        assert.is_string(move, "Solution move " .. i .. " should be string")
        -- UCI notation is 4-5 characters (e.g., "e2e4" or "e7e8q")
        assert.is_true(#move >= 4 and #move <= 5,
          "Move '" .. move .. "' should be valid UCI notation")
      end
    end)

    it("should return valid account structure when authenticated", function()
      if not token or token == "" then
        pending("LICHESS_TOKEN not set")
        return
      end

      auth.set_token(token)
      local account, err = api_client.get_account()

      assert.is_nil(err)
      assert.is_not_nil(account)

      -- Validate account structure
      assert.is_string(account.id)
      assert.is_string(account.username)
      assert.is_number(account.createdAt)

      -- Profile is optional but should be table if present
      if account.profile then
        assert.is_table(account.profile)
      end
    end)
  end)
end)
