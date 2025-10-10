# Changelog

All notable changes to nvim-chess will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.3] - 2025-10-10

### Added

- Ability to show the board on puzzle view
  - PNG to FEN parser
  - comprehenrive tests

## [0.3.2] - 2025-10-10

### Fixed

- ChessNextPuzzle command error due to missing FEN in Lichess API response
  - Lichess puzzle endpoints don't provide FEN field in responses
  - Updated puzzle manager to handle missing FEN gracefully
  - Shows puzzle info with Lichess training link when FEN unavailable
  - Puzzle solving functionality works without board display

### Added

- 5 new tests for missing FEN handling (58 total tests now)
  - Tests API response structure without FEN field
  - Tests graceful handling of nil FEN in board display
  - Tests fallback information display
  - Tests puzzle functionality without board rendering
  - All tests passing

### Changed

- Updated puzzle parser to accept game data for future FEN extraction
- Enhanced show_puzzle to display helpful message when board unavailable
- Stores PGN and game ID for potential future PGN-to-FEN conversion

## [0.3.1] - 2025-10-10

### Added

- GitHub Actions CI workflow for automated testing
  - Tests run on Neovim stable and nightly
  - Automatic execution on push and pull requests
  - Matrix strategy for version compatibility testing
  - Optional integration tests with Lichess token
- Dynamic test status badge in README
  - Real-time test status from GitHub Actions
  - Links to workflow runs
- CI documentation (`.github/CI.md`)
  - Workflow explanation and troubleshooting guide
  - Badge setup instructions
  - Local testing commands

### Fixed

- Puzzle API endpoints returning 404 errors
  - Removed duplicate `/api` prefix from puzzle endpoints
  - Fixed `/puzzle/daily`, `/puzzle/next`, `/puzzle/{id}`, `/puzzle/activity`
  - All puzzle operations now work correctly
  - Verified all 20 API endpoints for correct formatting

## [0.3.0] - 2025-10-10

### Added

- Authentication commands for easier token management
  - `:ChessAuthenticate [token]` - Smart authentication (uses configured token by default, prompts if none, or uses provided token)
  - `:ChessStatus` - Show current authentication status
  - `:ChessLogout` - Logout from Lichess
- Smart token detection in `:ChessAuthenticate`:
  1. Uses provided token if given as argument
  2. Uses configured token from setup if available
  3. Prompts interactively if no token configured
- Token validation with immediate feedback showing username
- Comprehensive authentication guide (AUTHENTICATION_GUIDE.md)

### Changed

- `:ChessAuthenticate` now uses configured token by default (no need to re-enter)
- Improved authentication documentation in README
- Added `puzzle:read` to recommended token scopes
- Setup now automatically initializes auth with configured token

### Fixed

- `:ChessNextPuzzle` now works without authentication (returns random puzzles)
  - Authenticated users still get rating-matched puzzles
  - Removed incorrect authentication requirement
  - Updated documentation to reflect correct behavior

## [0.2.0] - 2025-10-09

### Added

- Chess puzzle solving functionality
  - Daily puzzle support (no authentication required)
  - Training puzzle mode with rating-based matching (requires authentication)
  - Specific puzzle loading by ID
  - Puzzle activity history tracking
- Puzzle UI with interactive controls
  - Automatic board flipping based on side to move
  - Move history display
  - Puzzle metadata (ID, rating, themes, play count)
- Puzzle solving features
  - Move validation using UCI notation
  - Solution checking with correct/incorrect feedback
  - Automatic opponent move playback
  - Hint system showing move suggestions
  - Full solution display
- New commands
  - `:ChessDailyPuzzle` - Solve today's daily puzzle
  - `:ChessNextPuzzle` - Get next training puzzle
  - `:ChessGetPuzzle {id}` - Load specific puzzle by ID
  - `:ChessPuzzleActivity` - View puzzle history
- Puzzle API integration
  - `get_daily_puzzle()` - Fetch daily puzzle
  - `get_next_puzzle()` - Get next training puzzle
  - `get_puzzle(id)` - Load specific puzzle
  - `get_puzzle_activity()` - View puzzle history
  - `get_puzzle_dashboard()` - Get puzzle statistics
- Puzzle manager module (`lua/nvim-chess/puzzle/manager.lua`)
- Comprehensive puzzle test suite with 13 tests
- Release management documentation
  - RELEASE_PLAN.md with versioning strategy
  - CHANGELOG.md (this file)
  - Version tracking system

### Changed

- Updated README with puzzle features and usage documentation
- Extended API client with puzzle endpoints
- Exported `parse_fen_position()` from UI board module for puzzle rendering
- Added puzzle controls to interactive UI

### Fixed

- None

## [0.1.0] - 2025-10-08

### Added

- Initial release of nvim-chess
- Play chess games on Lichess.org
- Real-time game updates via streaming API
- Text-based chess board rendering
  - Unicode piece support (♔ ♕ ♖ ♗ ♘ ♙)
  - ASCII piece fallback
  - Board coordinates display
  - Board flip functionality
- Game management
  - Create new games with time controls
  - Seek games with matchmaking
  - Join existing games by ID
  - Make moves using UCI notation
  - Resign and abort games
- Profile and ratings display
  - View Lichess profile information
  - Display ratings across variants
  - Game statistics (wins, losses, draws)
- Authentication system
  - Lichess personal access token support
  - OAuth token management
- API client for Lichess
  - Game operations (create, join, move, resign, abort)
  - Challenge management
  - Profile fetching
  - Event streaming support
- Configuration system
  - Customizable board style (unicode/ascii)
  - Auto-refresh settings
  - Time control defaults
  - Show/hide coordinates
- Commands
  - `:ChessNewGame [time]` - Create new game
  - `:ChessSeekGame [time]` - Seek a game
  - `:ChessJoinGame {id}` - Join game by ID
  - `:ChessShowBoard [id]` - Show chess board
  - `:ChessMove {move}` - Make a move
  - `:ChessProfile` - Display profile
  - `:ChessResign` - Resign current game
  - `:ChessAbort` - Abort current game
  - `:ChessStartStreaming` - Start event streaming
  - `:ChessStopStreaming` - Stop streaming
- Testing infrastructure
  - Mock system for testing without API
  - Demo commands for testing
  - Unit test suite with plenary.nvim
  - Integration tests
  - Makefile with test targets
- Documentation
  - Comprehensive README
  - Installation instructions for lazy.nvim and packer.nvim
  - Usage examples and workflows
  - Command reference
- Board controls
  - `m` - Make a move
  - `f` - Flip board orientation
  - `R` - Resign game
  - `A` - Abort game
  - `q` - Close board
  - `<C-r>` - Refresh board

### Dependencies

- Neovim 0.7+
- plenary.nvim

[0.3.3]: https://github.com/linuxswords/nvim-chess/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/linuxswords/nvim-chess/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/linuxswords/nvim-chess/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/linuxswords/nvim-chess/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/linuxswords/nvim-chess/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/linuxswords/nvim-chess/releases/tag/v0.1.0
