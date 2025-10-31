# v0.1.0 - Initial Release

**nvim-chess** - Play chess on Lichess.org directly from Neovim!

This is the initial release of nvim-chess, bringing the power of Lichess.org to your favorite text editor.

## 🎮 Features

### Chess Gameplay
- 🏆 Play chess games on Lichess.org
- ⚡ Real-time game updates via streaming API
- 🎨 Text-based chess board with Unicode or ASCII pieces
- 🎯 UCI move notation support (e2e4, etc.)
- 🔄 Auto-refresh and flip board functionality

### Game Management
- Create new games with custom time controls
- Seek games with matchmaking
- Join existing games by ID
- Make moves with validation
- Resign and abort games

### Profile & Ratings
- 👤 View your Lichess profile
- 📊 Display ratings across all variants
- 📈 Game statistics (wins, losses, draws)

### Interactive Board
- `m` - Make a move
- `f` - Flip board orientation
- `R` - Resign game
- `A` - Abort game
- `q` - Close board
- `<C-r>` - Refresh board

## 📋 Commands

- `:ChessNewGame [time]` - Create new game with optional time control
- `:ChessSeekGame [time]` - Seek a game with matchmaking
- `:ChessJoinGame {id}` - Join existing game by ID
- `:ChessShowBoard [id]` - Show chess board
- `:ChessMove {move}` - Make a move (UCI notation)
- `:ChessProfile` - Display profile and ratings
- `:ChessResign` - Resign current game
- `:ChessAbort` - Abort current game
- `:ChessStartStreaming` - Start real-time event streaming
- `:ChessStopStreaming` - Stop all streaming

## 🧪 Testing

- Mock system for testing without Lichess API
- Demo commands for development testing
- Comprehensive unit and integration test suites
- Makefile with test targets

## 📦 Installation

### lazy.nvim
```lua
{
  'linuxswords/nvim-chess',
  tag = 'v0.1.0',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('nvim-chess').setup({
      lichess = {
        token = "your_lichess_token_here",  -- Get from https://lichess.org/account/oauth/token
      }
    })
  end
}
```

### packer.nvim
```lua
use {
  'linuxswords/nvim-chess',
  tag = 'v0.1.0',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('nvim-chess').setup({
      lichess = {
        token = "your_lichess_token_here",
      }
    })
  end
}
```

## ⚙️ Requirements

- Neovim 0.7+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Lichess.org account and [personal access token](https://lichess.org/account/oauth/token)

## 🚀 Quick Start

1. Install the plugin with your package manager
2. Get a Lichess token from https://lichess.org/account/oauth/token
3. Configure the plugin with your token
4. Start streaming: `:ChessStartStreaming`
5. Create a game: `:ChessNewGame 10+0`
6. Make moves: `:ChessMove e2e4` or press `m` in the board buffer

## 📚 Documentation

See the [README](https://github.com/linuxswords/nvim-chess/blob/master/README.md) for complete documentation.

## 🐛 Known Issues

None at this time.

## 🤝 Contributing

Contributions welcome! Please feel free to submit issues and pull requests.

---

**Full Changelog**: https://github.com/linuxswords/nvim-chess/commits/v0.1.0
