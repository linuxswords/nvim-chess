# Changelog

All notable changes to nvim-chess will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-11-01

### Added

- Configuration option for puzzle window mode
  - New `ui.puzzle_window_mode` config: "reuse" or "split"
  - Allows choosing between reusing current buffer or opening in new split
  - Provides flexibility for different workflow preferences

### Changed

- **Major UI/UX improvements** to chess board rendering
  - Enhanced board highlighting system
    - Last move highlighting for better move tracking
    - Improved highlighting for white pieces
  - Comprehensive color scheme overhaul
    - Refined board tile colors for better contrast
    - Updated piece colors for improved visibility
    - Better background colors for both GUI and terminal (cterm)
    - Lighter, more pleasant color palette
  - Board rendering refinements
    - Fixed alignment issues for consistent board display
    - Improved padding for cleaner appearance
    - Fixed column offset calculations
    - Better tile sizing and spacing
    - Multiple renderer fixes for edge cases

### Improved

- Documentation and visual guides
  - Updated README with better explanations
  - Improved setup instructions
  - Enhanced GIF demonstrations (looping, updated views)
  - Added visual examples of board views
  - Cleaner, more professional presentation

## [0.4.2] - 2025-10-13

### Fixed

- Puzzle navigation now properly fetches different puzzles each time
  - Fixed issue where `/api/puzzle/next` returned same puzzle when authenticated
  - Root cause: Lichess API doesn't support submitting puzzle completions via API
  - Solution: Use unauthenticated requests for puzzle fetching to get random puzzles
  - All puzzle progress continues to be tracked locally
  - Pressing '>' for next puzzle now works correctly without confirmation prompts

### Changed

- Puzzle fetching now uses unauthenticated API requests
  - Ensures different random puzzles on each fetch
  - Maintains all local tracking functionality
  - Added confirmation prompt when skipping unsolved puzzles
- Removed debug logging to /tmp directory
  - Cleaner production code
  - Better performance without file I/O overhead

### Technical Details

- Modified `api.get_next_puzzle()` to override authentication headers
- Updated puzzle manager to handle puzzle state transitions locally
- Removed attempted submissions to non-existent `/api/puzzle/round` endpoint
- Added comprehensive inline documentation explaining API limitations

## [0.4.1] - 2025-10-12

### Fixed

- Board coordinate labels now display correctly when flipped for black's perspective
  - File coordinates (a-h) now properly reverse to (h-a) when flipped
  - Rank numbers (1-8) now correctly show from black's viewpoint when flipped
  - Fixes confusion when entering moves from black's perspective

### Changed

- Replaced magic numbers with readable constants for player color determination
  - Added `PLY_WHITE` and `PLY_BLACK` constants
  - Added `get_player_from_ply()` helper function
  - Added `should_flip_board()` helper function
  - Improves code readability and maintainability

## [0.4.0] - 2025-10-12

### Changed

- **BREAKING CHANGE**: Refactored to focus exclusively on chess puzzles
  - Removed all game playing functionality (creating, joining, and playing games)
  - Removed streaming/real-time game updates
  - Removed challenge management features
  - Removed demo and mock testing utilities
  - Simplified configuration to focus on puzzle-solving features
- Puzzle manager now includes self-contained board rendering
  - No dependency on separate ui.board module
  - Inline FEN parsing and board display
  - Streamlined puzzle solving experience

### Removed

- Game playing commands: `ChessNewGame`, `ChessSeekGame`, `ChessJoinGame`, `ChessMove`
- Game control commands: `ChessResign`, `ChessAbort`
- Streaming commands: `ChessStartStreaming`, `ChessStopStreaming`
- Demo commands: `ChessDemo`, `ChessMock`
- Profile display command: `ChessProfile`
- Game-related modules: `game/manager.lua`, `api/streaming.lua`, `ui/board.lua`
- 17 game-related integration tests (103 passing unit tests remain)

### Kept

- All puzzle commands: `ChessDailyPuzzle`, `ChessNextPuzzle`, `ChessGetPuzzle`, `ChessPuzzleActivity`
- Authentication commands: `ChessAuthenticate`, `ChessStatus`, `ChessLogout`
- Version commands: `ChessVersion`, `ChessInfo`
- Complete chess engine with PGN-to-FEN conversion
- Puzzle board rendering with Unicode pieces
- Move validation and puzzle solving features

### Fixed

- LuaCov integration in CI pipeline
  - Created `.luacov_runner.lua` for proper coverage initialization
  - Updated Makefile to use luafile for coverage runner
  - Modified GitHub Actions workflow to set LuaRocks paths correctly
  - Fixed "Could not load stats file" error in CI

### Technical Details

- Simplified API client to only puzzle and account endpoints
- Authentication now uses `/account` endpoint instead of `/profile`
- Reduced configuration surface area (removed ui and game config sections)
- Code reduction: Removed ~1,750 lines, keeping focus on core puzzle functionality

## [0.3.5] - 2025-10-10

### Fixed

- Puzzle board now updates correctly when pressing 'n' to load next puzzle
  - Previously, each new puzzle created a new split window
  - Windows would accumulate, cluttering the interface
  - Board would not refresh to show the new puzzle position
- Window management improvements for puzzle navigation
  - Detects when user is in a puzzle buffer
  - Reuses current window for next puzzle instead of creating splits
  - Maintains smooth workflow when solving multiple puzzles in sequence

### Added

- Test coverage reporting with LuaCov and Codecov
  - Coverage badge in README showing test coverage percentage
  - GitHub Actions workflow generates and uploads coverage reports
  - Local coverage generation with `make coverage` command
  - Coverage configuration in `.luacov` file
  - Updated CI documentation with coverage instructions

## [0.3.4] - 2025-10-10

### Fixed

- Puzzle board now properly updates with each move during solving
  - Board refreshes after player's move
  - Board updates to show opponent's response
  - Provides real-time visual feedback throughout puzzle

### Changed

- Enhanced puzzle manager with UCI move application
  - Added `apply_uci_move_to_fen()` helper function
  - Integrated move application into `attempt_move()` workflow
  - Improved user experience with live board visualization

## [0.3.3] - 2025-10-10

### Added

- Full PGN-to-FEN conversion system for puzzle board display
  - Custom chess engine implementation (`lua/nvim-chess/chess/engine.lua`)
    - Board state representation and management
    - FEN parsing and generation
    - Helper functions for piece manipulation
  - SAN (Standard Algebraic Notation) move parser (`lua/nvim-chess/chess/san_parser.lua`)
    - Supports all chess move types: pawn moves, piece moves, captures, castling, promotion
    - Disambiguation handling (Nbd2, R1a3, etc.)
    - Move legality checking
  - Move execution engine (`lua/nvim-chess/chess/move_executor.lua`)
    - Execute moves on board state
    - Special move handling: castling, en passant, promotion
    - Castling rights and game state updates
  - PGN converter module (`lua/nvim-chess/chess/pgn_converter.lua`)
    - Convert Lichess PGN to FEN at any ply
    - PGN validation and parsing
    - Support for full game position lists
- Dynamic puzzle board updates
  - Board automatically refreshes after each player move
  - Board updates to show opponent's response moves
  - Full visual progression through puzzle solutions
  - Real-time FEN updates with UCI move application
- 62 new comprehensive tests (120 total tests now, all passing)
  - Chess engine tests (16 tests)
  - SAN parsing and move execution tests (24 tests)
  - PGN-to-FEN conversion tests (22 tests)
  - Tested with real Lichess puzzle data
  - Edge case coverage: castling, en passant, promotion, captures

### Fixed

- Puzzle board now displays correctly for all Lichess puzzles
  - Generates FEN from PGN moves provided by Lichess API
  - No more "Board display not available" warnings
- Puzzle board updates with each move during solving
  - Previously showed only starting position throughout puzzle
  - Now updates after player moves and opponent responses
  - Provides full visual feedback during puzzle solving

### Changed

- Updated puzzle manager to use PGN-to-FEN conversion
  - Integrated chess engine for position generation
  - Added UCI move application for board updates
  - Enhanced puzzle solving experience with live board updates

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

[0.6.0]: https://github.com/linuxswords/nvim-chess/compare/v0.5.0...v0.6.0
[0.4.2]: https://github.com/linuxswords/nvim-chess/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/linuxswords/nvim-chess/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/linuxswords/nvim-chess/compare/v0.3.5...v0.4.0
[0.3.5]: https://github.com/linuxswords/nvim-chess/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/linuxswords/nvim-chess/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/linuxswords/nvim-chess/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/linuxswords/nvim-chess/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/linuxswords/nvim-chess/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/linuxswords/nvim-chess/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/linuxswords/nvim-chess/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/linuxswords/nvim-chess/releases/tag/v0.1.0
