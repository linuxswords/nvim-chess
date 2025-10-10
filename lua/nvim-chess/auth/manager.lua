local M = {}

local current_token = nil
local user_profile = nil

function M.set_token(token)
  current_token = token
  user_profile = nil -- Clear cached profile when token changes
end

function M.get_token()
  return current_token
end

function M.is_authenticated()
  return current_token ~= nil
end

function M.validate_token()
  if not current_token then
    return false, "No token set"
  end

  local api = require('nvim-chess.api.client')
  local account, error = api.get_account()

  if error then
    return false, error
  end

  if account then
    user_profile = account
    return true, nil
  end

  return false, "Invalid token"
end

function M.get_user_profile()
  return user_profile
end

function M.clear_session()
  current_token = nil
  user_profile = nil
end

return M