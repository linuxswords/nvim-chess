local M = {}

-- Mock API responses for testing
local mock_responses = {
  profile = {
    username = "test_user",
    title = "NM",
    online = true,
    perfs = {
      blitz = { rating = 1500, games = 100 },
      rapid = { rating = 1400, games = 50 },
      classical = { rating = 1600, games = 25 }
    },
    count = {
      all = 175,
      rated = 150,
      win = 90,
      loss = 60,
      draw = 25
    }
  },
  challenge = {
    id = "test_challenge_123",
    url = "https://lichess.org/test_challenge_123",
    challenge = {
      id = "test_challenge_123",
      url = "https://lichess.org/test_challenge_123"
    }
  },
  game = {
    id = "test_game_456",
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    white = { id = "test_user", rating = 1500 },
    black = { id = "opponent", rating = 1450 },
    status = "started"
  },
  seek = {
    ok = true
  }
}

-- Mock API client
local mock_api = {}

function mock_api.get_profile()
  return mock_responses.profile, nil
end

function mock_api.create_challenge(opts)
  return mock_responses.challenge, nil
end

function mock_api.seek_game(opts)
  return mock_responses.seek, nil
end

function mock_api.get_game(game_id)
  local game = vim.deepcopy(mock_responses.game)
  game.id = game_id
  return game, nil
end

function mock_api.make_move(game_id, move, draw_offer)
  return { ok = true }, nil
end

function mock_api.resign_game(game_id)
  return { ok = true }, nil
end

function mock_api.abort_game(game_id)
  return { ok = true }, nil
end

-- Mock streaming
function mock_api.stream_incoming_events()
  return {
    body = '{"type":"challenge","challenge":{"id":"mock_challenge"}}\n'
  }
end

function mock_api.stream_game_state(game_id)
  return {
    body = '{"type":"gameFull","state":{"fen":"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"}}\n'
  }
end

-- Mock auth manager
local mock_auth = {
  _token = "mock_token_123",
  _profile = mock_responses.profile
}

function mock_auth.set_token(token)
  mock_auth._token = token
end

function mock_auth.get_token()
  return mock_auth._token
end

function mock_auth.is_authenticated()
  return mock_auth._token ~= nil
end

function mock_auth.validate_token()
  return true, nil
end

function mock_auth.get_user_profile()
  return mock_auth._profile
end

function mock_auth.clear_session()
  mock_auth._token = nil
  mock_auth._profile = nil
end

-- Enable/disable mock mode
local mock_enabled = false

function M.enable()
  mock_enabled = true

  -- Replace the real modules with mocks
  package.loaded['nvim-chess.api.client'] = mock_api
  package.loaded['nvim-chess.auth.manager'] = mock_auth

  vim.notify("Mock mode enabled - using fake Lichess API", vim.log.levels.INFO)
end

function M.disable()
  mock_enabled = false

  -- Clear the mocked modules so they reload normally
  package.loaded['nvim-chess.api.client'] = nil
  package.loaded['nvim-chess.auth.manager'] = nil

  vim.notify("Mock mode disabled - using real Lichess API", vim.log.levels.INFO)
end

function M.is_enabled()
  return mock_enabled
end

-- Update mock responses for testing
function M.set_profile(profile)
  mock_responses.profile = profile
  mock_auth._profile = profile
end

function M.set_game_state(game_id, fen)
  mock_responses.game.id = game_id
  mock_responses.game.fen = fen
end

function M.simulate_challenge(challenge_data)
  mock_responses.challenge = challenge_data
end

function M.simulate_move_response(response)
  mock_api.make_move = function() return response, nil end
end

function M.simulate_api_error(endpoint, error_msg)
  if endpoint == "profile" then
    mock_api.get_profile = function() return nil, error_msg end
  elseif endpoint == "challenge" then
    mock_api.create_challenge = function() return nil, error_msg end
  elseif endpoint == "game" then
    mock_api.get_game = function() return nil, error_msg end
  end
end

return M