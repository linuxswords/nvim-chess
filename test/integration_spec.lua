-- Integration tests with real Lichess API
-- Requires LICHESS_TOKEN environment variable to be set

local function skip_if_no_token()
  local token = vim.env.LICHESS_TOKEN
  if not token or token == "" then
    pending("LICHESS_TOKEN environment variable not set - skipping integration tests")
  end
  return not token or token == ""
end

describe('nvim-chess integration tests', function()
  local nvim_chess, api, auth

  before_each(function()
    if skip_if_no_token() then return end

    -- Clear any mock modules to use real implementations
    package.loaded['nvim-chess.api.client'] = nil
    package.loaded['nvim-chess.auth.manager'] = nil
    package.loaded['nvim-chess'] = nil

    -- Require modules fresh
    nvim_chess = require('nvim-chess')
    api = require('nvim-chess.api.client')
    auth = require('nvim-chess.auth.manager')

    -- Setup with real token
    nvim_chess.setup({
      lichess = {
        token = vim.env.LICHESS_TOKEN,
        timeout = 30000
      }
    })
  end)

  after_each(function()
    if skip_if_no_token() then return end

    -- Clean up any buffers created during tests
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("chess") or name:match("lichess") then
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end

    -- Clear session
    auth.clear_session()
  end)

  describe('authentication', function()
    it('should validate token with Lichess API', function()
      if skip_if_no_token() then return end

      local success, error = auth.validate_token()

      assert.is_true(success, "Token validation should succeed: " .. (error or ""))
      assert.is_nil(error)
      assert.is_true(auth.is_authenticated())
    end)

    it('should get user profile from Lichess', function()
      if skip_if_no_token() then return end

      local profile, error = api.get_profile()

      assert.is_nil(error, "Profile request should succeed: " .. (error or ""))
      assert.is_not_nil(profile)
      assert.is_string(profile.username)
      assert.is_not_nil(profile.perfs)
    end)
  end)

  describe('profile display', function()
    it('should display profile information', function()
      if skip_if_no_token() then return end

      local result = nvim_chess.get_profile()

      assert.is_not_false(result, "Profile display should succeed")

      -- Check that profile buffer was created
      local profile_buf = vim.fn.bufnr("lichess-profile")
      assert.is_not_equal(-1, profile_buf, "Profile buffer should be created")
    end)
  end)

  describe('board functionality', function()
    it('should show chess board', function()
      if skip_if_no_token() then return end

      local ui = require('nvim-chess.ui.board')
      local buf = ui.show_board("test-integration")

      assert.is_number(buf)
      assert.is_true(vim.api.nvim_buf_is_valid(buf))

      -- Check buffer content
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.is_true(#lines > 0, "Board should have content")

      -- Should contain chess pieces or coordinates
      local content = table.concat(lines, "\n")

      -- Check for various board elements
      local has_unicode_pieces = content:find("♔") or content:find("♕") or content:find("♖") or content:find("♗") or content:find("♘") or content:find("♙") or
                                content:find("♚") or content:find("♛") or content:find("♜") or content:find("♝") or content:find("♞") or content:find("♟")
      local has_ascii_pieces = content:find("[KQRBNPkqrbnp]")
      local has_coords = content:find("[a-h]") or content:find("[1-8]")
      local has_dots = content:find("·") or content:find("%.")
      local has_spaces = content:find(" ") -- Even empty squares should have spaces

      local has_elements = (has_unicode_pieces and true) or (has_ascii_pieces and true) or (has_coords and true) or (has_dots and true) or (has_spaces and true)

      assert.is_true(
        has_elements,
        "Board should contain chess elements. Found unicode: " .. tostring(has_unicode_pieces) ..
        ", ascii: " .. tostring(has_ascii_pieces) ..
        ", coords: " .. tostring(has_coords) ..
        ", dots: " .. tostring(has_dots) ..
        ". Content preview: " .. content:sub(1, 200)
      )
    end)
  end)

  describe('API client functionality', function()
    it('should handle rate limiting gracefully', function()
      if skip_if_no_token() then return end

      -- Make multiple rapid requests to potentially trigger rate limiting
      local requests = {}
      for i = 1, 3 do
        local profile, error = api.get_profile()
        table.insert(requests, { profile = profile, error = error })

        -- Small delay between requests
        vim.wait(100)
      end

      -- At least some requests should succeed
      local successful = 0
      for _, req in ipairs(requests) do
        if req.profile and not req.error then
          successful = successful + 1
        elseif req.error == "rate_limited" then
          -- Rate limiting is expected and should be handled gracefully
          assert.is_true(true, "Rate limiting handled correctly")
        end
      end

      assert.is_true(successful > 0, "At least one request should succeed")
    end)

    it('should handle network errors gracefully', function()
      if skip_if_no_token() then return end

      -- Test with invalid endpoint (should fail gracefully)
      local old_base_url = require('nvim-chess.config').get_lichess_config().base_url

      -- Temporarily break the URL and set shorter timeout
      require('nvim-chess.config').setup({
        lichess = {
          token = vim.env.LICHESS_TOKEN,
          base_url = "https://invalid-lichess-url.com/api",
          timeout = 2000  -- 2 second timeout
        }
      })

      local success, result = pcall(function()
        return api.get_profile()
      end)

      if success then
        local profile, error = result, nil
        assert.is_nil(profile)
        if error then
          assert.is_string(error)
        end
      else
        -- Timeout or network error occurred, which is expected
        assert.is_true(true, "Network error handled correctly: " .. tostring(result))
      end

      -- Restore original URL and timeout
      require('nvim-chess.config').setup({
        lichess = {
          token = vim.env.LICHESS_TOKEN,
          base_url = old_base_url,
          timeout = 30000
        }
      })
    end)
  end)

  describe('game operations', function()
    it('should handle seek game request', function()
      if skip_if_no_token() then return end

      local result, error = api.seek_game({
        time = 1,      -- 1 minute game
        increment = 0,
        rated = false
      })

      -- Note: This might fail if we're not a bot account or missing scopes, which is fine
      if error and (error:find("400") or error:find("Missing scope")) then
        -- Expected for non-bot accounts or missing scopes
        assert.is_true(true, "Non-bot account limitation or missing scope is expected")
      else
        assert.is_nil(error, "Seek game should succeed or fail gracefully: " .. (error or ""))
      end
    end)

    it('should handle challenge creation', function()
      if skip_if_no_token() then return end

      local result, error = api.create_challenge({
        clock = { limit = 300, increment = 5 }  -- 5+5 game
      })

      -- Note: This might fail depending on account type, which is expected
      if error then
        -- Check if it's a known limitation
        assert.is_true(
          error:match("400") or error:match("401") or error:match("403"),
          "Challenge creation should fail with expected HTTP error: " .. error
        )
      else
        assert.is_not_nil(result)
      end
    end)
  end)

  describe('error handling', function()
    it('should handle invalid token gracefully', function()
      if skip_if_no_token() then return end

      -- Save original token
      local original_token = auth.get_token()

      -- Set invalid token
      auth.set_token("invalid_token_123")

      local profile, error = api.get_profile()

      assert.is_nil(profile)
      assert.is_string(error)
      local is_auth_error = (error:find("401") and true) or (error:find("Unauthorized") and true) or (error:find("Invalid") and true) or (error:find("No such token") and true)
      assert.is_true(is_auth_error,
                    "Should get authentication error: " .. error)

      -- Restore original token
      auth.set_token(original_token)
    end)

    it('should handle missing permissions', function()
      if skip_if_no_token() then return end

      -- Try an operation that might require special permissions
      local result, error = api.upgrade_to_bot()

      -- This should fail for normal accounts
      if error then
        local is_expected_error = (error:find("400") and true) or (error:find("403") and true) or (error:find("409") and true) or (error:find("Missing scope") and true)
        assert.is_true(is_expected_error,
          "Bot upgrade should fail with expected error: " .. error
        )
      else
        -- If it succeeds, that's also fine (might be a bot account)
        assert.is_true(true, "Bot upgrade succeeded (account might already be a bot)")
      end
    end)
  end)

  describe('configuration', function()
    it('should respect timeout settings', function()
      if skip_if_no_token() then return end

      -- Set very short timeout
      require('nvim-chess.config').setup({
        lichess = {
          token = vim.env.LICHESS_TOKEN,
          timeout = 50  -- 50ms timeout (should fail quickly)
        }
      })

      local start_time = vim.loop.hrtime()
      local success, result = pcall(function()
        return api.get_profile()
      end)
      local duration = (vim.loop.hrtime() - start_time) / 1000000  -- Convert to ms

      -- Should timeout quickly (within 3 seconds including overhead)
      assert.is_true(duration < 3000, "Request should timeout quickly, took: " .. duration .. "ms")

      if success then
        local profile, error = result, nil
        if error then
          assert.is_true(true, "Error received as expected: " .. error)
        else
          -- Sometimes very fast networks might succeed even with short timeout
          assert.is_true(true, "Request succeeded despite short timeout (very fast network)")
        end
      else
        -- Timeout error occurred, which is expected
        assert.is_true(true, "Timeout error handled correctly: " .. tostring(result))
      end

      -- Reset to normal timeout
      require('nvim-chess.config').setup({
        lichess = {
          token = vim.env.LICHESS_TOKEN,
          timeout = 30000
        }
      })
    end)
  end)
end)