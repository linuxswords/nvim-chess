local M = {}

local config = require('nvim-chess.config')

-- Unicode chess pieces
local unicode_pieces = {
  white = {
    king = "♔", queen = "♕", rook = "♖",
    bishop = "♗", knight = "♘", pawn = "♙"
  },
  black = {
    king = "♚", queen = "♛", rook = "♜",
    bishop = "♝", knight = "♞", pawn = "♟"
  }
}

-- ASCII chess pieces
local ascii_pieces = {
  white = {
    king = "K", queen = "Q", rook = "R",
    bishop = "B", knight = "N", pawn = "P"
  },
  black = {
    king = "k", queen = "q", rook = "r",
    bishop = "b", knight = "n", pawn = "p"
  }
}

local function get_piece_set()
  local ui_config = config.get_ui_config()
  return ui_config.board_style == "unicode" and unicode_pieces or ascii_pieces
end

local function create_empty_board()
  local board = {}
  for rank = 1, 8 do
    board[rank] = {}
    for file = 1, 8 do
      board[rank][file] = nil
    end
  end
  return board
end

local function parse_fen_position(fen)
  local board = create_empty_board()
  local position = fen:match("^([^%s]+)")

  local rank = 8
  local file = 1

  for char in position:gmatch(".") do
    if char == "/" then
      rank = rank - 1
      file = 1
    elseif char:match("%d") then
      file = file + tonumber(char)
    else
      local piece_map = {
        K = {color = "white", type = "king"},
        Q = {color = "white", type = "queen"},
        R = {color = "white", type = "rook"},
        B = {color = "white", type = "bishop"},
        N = {color = "white", type = "knight"},
        P = {color = "white", type = "pawn"},
        k = {color = "black", type = "king"},
        q = {color = "black", type = "queen"},
        r = {color = "black", type = "rook"},
        b = {color = "black", type = "bishop"},
        n = {color = "black", type = "knight"},
        p = {color = "black", type = "pawn"},
      }

      if piece_map[char] then
        board[rank][file] = piece_map[char]
      end
      file = file + 1
    end
  end

  return board
end

-- Export parse_fen_position for use by puzzle module
M.parse_fen_position = parse_fen_position

local function render_board(board, flip)
  local pieces = get_piece_set()
  local ui_config = config.get_ui_config()
  local lines = {}

  -- Add top border with file labels if coordinates are shown
  if ui_config.show_coordinates then
    local files = flip and "  h g f e d c b a" or "  a b c d e f g h"
    table.insert(lines, files)
  end

  for rank_idx = 1, 8 do
    local rank = flip and rank_idx or (9 - rank_idx)
    local line = ui_config.show_coordinates and tostring(rank) .. " " or ""

    for file_idx = 1, 8 do
      local file = flip and (9 - file_idx) or file_idx
      local piece = board[rank] and board[rank][file]

      if piece then
        line = line .. pieces[piece.color][piece.type] .. " "
      else
        -- Empty square - use different chars for light/dark squares
        local is_light = (rank + file) % 2 == 0
        line = line .. (is_light and "·" or " ") .. " "
      end
    end

    if ui_config.show_coordinates then
      line = line .. " " .. tostring(rank)
    end
    table.insert(lines, line)
  end

  -- Add bottom border with file labels if coordinates are shown
  if ui_config.show_coordinates then
    local files = flip and "  h g f e d c b a" or "  a b c d e f g h"
    table.insert(lines, files)
  end

  return lines
end

function M.show_board(game_id)
  -- Create or focus chess board buffer
  local buf_name = game_id and ("chess-" .. game_id) or "chess-board"
  local existing_buf = vim.fn.bufnr(buf_name)

  local buf
  if existing_buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, buf_name)
  else
    buf = existing_buf
  end

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- For now, show starting position - will be replaced with actual game state
  local starting_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
  local board = parse_fen_position(starting_fen)
  local board_lines = render_board(board, false)

  -- Update buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, board_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Open in new window if not already visible
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
  else
    vim.api.nvim_set_current_win(win)
  end

  -- Set up buffer-local keymaps for chess moves
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Basic navigation
  vim.keymap.set('n', 'q', '<cmd>q<cr>', opts)
  vim.keymap.set('n', 'R', '<cmd>ChessResign<cr>', opts)
  vim.keymap.set('n', 'A', '<cmd>ChessAbort<cr>', opts)

  -- Move input
  vim.keymap.set('n', 'm', function()
    local move = vim.fn.input("Enter move (e.g., e2e4): ")
    if move and move ~= "" then
      require('nvim-chess.game.manager').make_move(move)
    end
  end, opts)

  -- Flip board
  vim.keymap.set('n', 'f', function()
    local game = require('nvim-chess.game.manager').get_current_game()
    if game and game.state and game.state.fen then
      -- Toggle flip state (stored in buffer variable)
      local flipped = vim.b[buf].chess_flipped or false
      vim.b[buf].chess_flipped = not flipped
      M.update_board(buf, game.state.fen, not flipped)
    end
  end, opts)

  -- Refresh board
  vim.keymap.set('n', '<C-r>', function()
    local game = require('nvim-chess.game.manager').get_current_game()
    if game and game.state and game.state.fen then
      local flipped = vim.b[buf].chess_flipped or false
      M.update_board(buf, game.state.fen, flipped)
    end
  end, opts)

  return buf
end

function M.update_board(buf, fen, flip)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  local board = parse_fen_position(fen)
  local board_lines = render_board(board, flip or false)

  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, board_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  return true
end

return M