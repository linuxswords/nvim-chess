# v0.2.0 - Chess Puzzle Support 🧩

**Major Feature Release:** nvim-chess now includes comprehensive chess puzzle solving!

This release adds a complete puzzle system, allowing you to solve daily puzzles, train with rating-based puzzles, and track your puzzle activity - all from within Neovim.

## ✨ What's New

### 🧩 Chess Puzzles
- **Daily Puzzles**: Solve Lichess daily puzzles without authentication
- **Training Mode**: Get personalized puzzles based on your rating (requires auth)
- **Puzzle Library**: Load any specific puzzle by ID
- **Activity Tracking**: View your complete puzzle solving history

### 🎯 Puzzle Features
- **Move Validation**: Real-time checking using UCI notation
- **Smart Feedback**: Immediate correct/incorrect move indication
- **Auto-Playback**: Opponent responses play automatically
- **Hint System**: Get hints showing from/to squares
- **Solution Display**: View complete solutions when needed
- **Progress Tracking**: Keep history of solved/failed puzzles

### 🎨 Interactive Puzzle UI
- Beautiful puzzle display with metadata
- Automatic board flipping (view from your side)
- Move history tracking
- Puzzle rating, themes, and play count
- Clean, intuitive controls

## 📋 New Commands

| Command | Description |
|---------|-------------|
| `:ChessDailyPuzzle` | Solve today's daily puzzle (no auth) |
| `:ChessNextPuzzle` | Get next training puzzle (requires auth) |
| `:ChessGetPuzzle {id}` | Load specific puzzle by ID |
| `:ChessPuzzleActivity` | View puzzle history (requires auth) |
| `:ChessVersion` | Show plugin version |
| `:ChessInfo` | Show detailed plugin information |

## ⌨️ Puzzle Controls

When viewing a puzzle:
- `m` - Make a move (enter UCI notation)
- `h` - Show hint (displays from/to squares)
- `s` - Show full solution
- `n` - Get next puzzle
- `q` - Close puzzle
- `<C-r>` - Refresh puzzle display

## 🎮 Usage Examples

```vim
" Solve the daily puzzle (no authentication needed)
:ChessDailyPuzzle

" Train with puzzles matched to your rating
:ChessNextPuzzle

" Load a specific puzzle
:ChessGetPuzzle abc12345

" View your puzzle solving history
:ChessPuzzleActivity

" Check plugin version
:ChessVersion
```

## 🔧 Technical Improvements

### New Modules
- `lua/nvim-chess/puzzle/manager.lua` - Complete puzzle management system
- `lua/nvim-chess/version.lua` - Version tracking and comparison

### API Extensions
- `get_daily_puzzle()` - Fetch daily puzzle
- `get_next_puzzle()` - Get next training puzzle
- `get_puzzle(id)` - Load specific puzzle
- `get_puzzle_activity()` - View puzzle history
- `get_puzzle_dashboard()` - Get puzzle statistics

### Testing
- 13 comprehensive puzzle tests
- Move validation testing
- Solution checking tests
- FEN parsing validation
- All tests passing ✅

### Documentation
- CHANGELOG.md following Keep a Changelog format
- RELEASE_PLAN.md with versioning strategy
- Release checklist template
- Enhanced README with puzzle section

## 📦 Installation

### lazy.nvim
```lua
{
  'linuxswords/nvim-chess',
  tag = 'v0.2.0',  -- Pin to this release
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('nvim-chess').setup({
      lichess = {
        token = "your_lichess_token_here",  -- Optional for daily puzzle
      }
    })
  end
}
```

### packer.nvim
```lua
use {
  'linuxswords/nvim-chess',
  tag = 'v0.2.0',
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

### Upgrading from v0.1.0

If you're using version pinning:
```lua
-- Update from:
tag = 'v0.1.0',
-- To:
tag = 'v0.2.0',
```

Then run `:Lazy update` or `:PackerSync`

## 🔄 Migration Guide

**Good News:** This release is fully backwards compatible! No breaking changes.

All existing game functionality works exactly as before. Puzzle features are completely additive.

## ⚙️ Requirements

- Neovim 0.7+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Lichess.org account (optional for daily puzzle, required for training)
- [Personal access token](https://lichess.org/account/oauth/token) (optional for daily puzzle)

## 🚀 Quick Start with Puzzles

1. Install or update to v0.2.0
2. Try the daily puzzle: `:ChessDailyPuzzle` (no auth needed!)
3. For training mode, set up your Lichess token
4. Use `:ChessNextPuzzle` for personalized puzzles
5. Press `h` for hints, `s` for solutions, `n` for next puzzle

## 📚 Documentation

- [README](https://github.com/linuxswords/nvim-chess/blob/v0.2.0/README.md) - Complete documentation
- [CHANGELOG](https://github.com/linuxswords/nvim-chess/blob/v0.2.0/CHANGELOG.md) - Detailed change history
- [RELEASE_PLAN](https://github.com/linuxswords/nvim-chess/blob/v0.2.0/RELEASE_PLAN.md) - Release management strategy

## 🎯 What's Next

Future plans for nvim-chess:
- Puzzle Rush mode
- Puzzle themes filtering
- Offline puzzle database
- Analysis board
- PGN import/export
- More interactive features

## 🐛 Known Issues

None at this time. Please report any issues on GitHub!

## 🤝 Contributing

Contributions welcome! Check out our release plan and contributing guidelines.

## 📊 Release Statistics

- **Files Changed**: 8 files
- **New Commands**: 4 puzzle commands + 2 version commands
- **New Tests**: 13 puzzle tests
- **Lines Added**: ~1000+
- **Backwards Compatible**: ✅ Yes

---

**Full Changelog**: https://github.com/linuxswords/nvim-chess/compare/v0.1.0...v0.2.0
