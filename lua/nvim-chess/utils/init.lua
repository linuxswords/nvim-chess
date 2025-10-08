local M = {}

-- Utility functions for chess operations

function M.parse_square(square)
  if not square or #square ~= 2 then
    return nil
  end

  local file_char = square:sub(1, 1):lower()
  local rank_char = square:sub(2, 2)

  local file = string.byte(file_char) - string.byte('a') + 1
  local rank = tonumber(rank_char)

  if file < 1 or file > 8 or rank < 1 or rank > 8 then
    return nil
  end

  return { file = file, rank = rank }
end

function M.square_to_coords(square)
  local coords = M.parse_square(square)
  if not coords then
    return nil
  end
  return coords.file, coords.rank
end

function M.coords_to_square(file, rank)
  if file < 1 or file > 8 or rank < 1 or rank > 8 then
    return nil
  end

  local file_char = string.char(string.byte('a') + file - 1)
  return file_char .. tostring(rank)
end

function M.is_valid_move_format(move)
  -- Check UCI format: e2e4, a7a8q, etc.
  return move:match("^[a-h][1-8][a-h][1-8][qrbn]?$") ~= nil
end

function M.parse_uci_move(move)
  if not M.is_valid_move_format(move) then
    return nil
  end

  local from_square = move:sub(1, 2)
  local to_square = move:sub(3, 4)
  local promotion = move:sub(5, 5)

  local from_file, from_rank = M.square_to_coords(from_square)
  local to_file, to_rank = M.square_to_coords(to_square)

  if not from_file or not to_file then
    return nil
  end

  return {
    from = { file = from_file, rank = from_rank, square = from_square },
    to = { file = to_file, rank = to_rank, square = to_square },
    promotion = promotion ~= "" and promotion or nil
  }
end

-- Time formatting utilities
function M.format_time(seconds)
  if not seconds then
    return "N/A"
  end

  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60

  if hours > 0 then
    return string.format("%d:%02d:%02d", hours, minutes, secs)
  else
    return string.format("%d:%02d", minutes, secs)
  end
end

-- JSON streaming utilities for handling nd-json responses
function M.parse_ndjson_line(line)
  if line and line ~= "" then
    local ok, json = pcall(vim.json.decode, line)
    if ok then
      return json
    end
  end
  return nil
end

function M.split_ndjson(text)
  local lines = {}
  for line in text:gmatch("[^\r\n]+") do
    local json = M.parse_ndjson_line(line)
    if json then
      table.insert(lines, json)
    end
  end
  return lines
end

-- Color utilities
function M.get_player_color(game_state, username)
  if not game_state or not username then
    return nil
  end

  if game_state.white and game_state.white.id == username then
    return "white"
  elseif game_state.black and game_state.black.id == username then
    return "black"
  end

  return nil
end

function M.is_player_turn(game_state, username)
  local player_color = M.get_player_color(game_state, username)
  if not player_color then
    return false
  end

  -- Parse turn from FEN (first character after position)
  local fen = game_state.fen
  if not fen then
    return false
  end

  local turn = fen:match("^[^%s]+%s+([wb])")
  if not turn then
    return false
  end

  local turn_color = turn == "w" and "white" or "black"
  return player_color == turn_color
end

return M