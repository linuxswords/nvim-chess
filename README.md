# nvim-chess

A Neovim plugin for playing chess on Lichess.org directly from your editor.

## Features

- 🏆 Play chess games on Lichess.org
- ⚡ Real-time game updates via streaming API
- 🎨 Text-based chess board with Unicode or ASCII pieces
- 👤 Profile and rating information
- 🎮 Game creation and management
- ✅ Move validation and UCI notation
- 📱 Challenge management
- 🔄 Auto-refresh and flip board functionality

## Requirements

- Neovim 0.7+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Lichess.org account and personal access token

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'linuxswords/nvim-chess',
  requires = { 'nvim-lua/plenary.nvim' }
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'linuxswords/nvim-chess',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
```

## Configuration

### Getting a Lichess Token

1. Go to [https://lichess.org/account/oauth/token](https://lichess.org/account/oauth/token)
2. Create a new personal access token
3. Select appropriate scopes (recommend: `board:play`, `challenge:read`, `challenge:write`)

### Setup

```lua
require('nvim-chess').setup({
  lichess = {
    token = "your_lichess_token_here",  -- Required: Your Lichess personal access token
    timeout = 30000,                   -- Request timeout in milliseconds
  },
  ui = {
    board_style = "unicode",           -- "unicode" or "ascii" pieces
    auto_refresh = true,               -- Auto-refresh board on updates
    show_coordinates = true,           -- Show board coordinates (a-h, 1-8)
    highlight_last_move = true,        -- Highlight the last move made
  },
  game = {
    auto_accept_challenges = false,    -- Automatically accept incoming challenges
    default_time_control = "10+0",     -- Default time control for new games
  }
})
```

## Usage

### Basic Workflow

1. **Start streaming** for real-time updates:

   ```vim
   :ChessStartStreaming
   ```

2. **Create a new game**:

   ```vim
   :ChessNewGame 10+0
   ```

3. **Join an existing game**:

   ```vim
   :ChessJoinGame abc12345
   ```

4. **Make moves** using UCI notation:

   ```vim
   :ChessMove e2e4
   ```

   Or press `m` in the board buffer for interactive input.

5. **View your profile**:

   ```vim
   :ChessProfile
   ```

### Chess Board Controls

When viewing a chess board, use these keys:

- `m` - Enter a move
- `f` - Flip board orientation
- `R` - Resign game
- `A` - Abort game
- `q` - Close board
- `<C-r>` - Refresh board

### Move Notation

Use UCI (Universal Chess Interface) notation for moves:

- `e2e4` - Move piece from e2 to e4
- `a7a8q` - Promote pawn to queen
- `e1g1` - Castling (king side)

## Commands

| Command                | Description                                |
| ---------------------- | ------------------------------------------ |
| `:ChessNewGame [time]` | Create new game with optional time control |
| `:ChessJoinGame {id}`  | Join existing game by ID                   |
| `:ChessShowBoard [id]` | Show board for current/specified game      |
| `:ChessMove {move}`    | Make a move (UCI notation)                 |
| `:ChessProfile`        | Display profile and ratings                |
| `:ChessResign`         | Resign current game                        |
| `:ChessAbort`          | Abort current game                         |
| `:ChessStartStreaming` | Start real-time event streaming            |
| `:ChessStopStreaming`  | Stop all streaming                         |

## Board Display

The plugin displays chess boards using either Unicode or ASCII pieces:

### Unicode Style

```
  a b c d e f g h
8 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜  8
7 ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟  7
6 · · · · · · · ·  6
5 · · · · · · · ·  5
4 · · · · · · · ·  4
3 · · · · · · · ·  3
2 ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙  2
1 ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖  1
  a b c d e f g h
```

### ASCII Style

```
  a b c d e f g h
8 r n b q k b n r  8
7 p p p p p p p p  7
6 . . . . . . . .  6
5 . . . . . . . .  5
4 . . . . . . . .  4
3 . . . . . . . .  3
2 P P P P P P P P  2
1 R N B Q K B N R  1
  a b c d e f g h
```

## Architecture

The plugin is structured with these main modules:

- `lua/nvim-chess/` - Core plugin logic
  - `init.lua` - Main plugin interface
  - `config.lua` - Configuration management
  - `api/` - Lichess API communication
  - `ui/` - Chess board rendering
  - `game/` - Game state management
  - `auth/` - Authentication handling
  - `utils/` - Utility functions

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions welcome! Please read the contributing guidelines and submit pull requests.

## Support

- File issues on GitHub
- Check the documentation with `:help nvim-chess`
- Ensure you have a valid Lichess token configured

