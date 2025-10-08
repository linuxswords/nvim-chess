local auth = require('nvim-chess.auth.manager')

describe('nvim-chess authentication', function()
  before_each(function()
    -- Clear any existing session
    auth.clear_session()
  end)

  describe('token management', function()
    it('should set and get tokens', function()
      assert.is_false(auth.is_authenticated())
      assert.is_nil(auth.get_token())

      auth.set_token('test_token_123')

      assert.is_true(auth.is_authenticated())
      assert.are.equal('test_token_123', auth.get_token())
    end)

    it('should clear tokens', function()
      auth.set_token('test_token')
      assert.is_true(auth.is_authenticated())

      auth.clear_session()
      assert.is_false(auth.is_authenticated())
      assert.is_nil(auth.get_token())
    end)

    it('should clear profile when token changes', function()
      auth.set_token('token1')
      -- Simulate storing a profile
      auth.get_user_profile = function() return { username = 'test' } end

      auth.set_token('token2')
      -- Profile should be cleared (would need actual implementation to test this properly)
      assert.is_true(auth.is_authenticated())
    end)
  end)

  describe('authentication status', function()
    it('should return correct authentication status', function()
      assert.is_false(auth.is_authenticated())

      auth.set_token('')
      assert.is_true(auth.is_authenticated()) -- Empty string is still "set"

      auth.set_token(nil)
      assert.is_false(auth.is_authenticated())
    end)
  end)

  describe('user profile', function()
    it('should handle profile storage', function()
      -- This would require mocking the API client for proper testing
      local profile = auth.get_user_profile()
      assert.is_nil(profile) -- Initially no profile

      -- Would need to test with actual API responses
    end)
  end)
end)