# nvim-chess v0.3.1

Patch release with bug fixes and CI improvements.

## 🐛 Bug Fixes

### Puzzle API Endpoints Fixed
- **Fixed:** Puzzle operations were returning 404 errors
- **Root cause:** Duplicate `/api` prefix in puzzle endpoint URLs
- **Resolution:** Removed extra `/api` from all puzzle endpoints
- **Impact:** All puzzle commands now work correctly:
  - `:ChessDailyPuzzle` ✓
  - `:ChessNextPuzzle` ✓
  - `:ChessGetPuzzle {id}` ✓
  - `:ChessPuzzleActivity` ✓

### API Endpoint Audit
- Verified all 20 API endpoints for correct formatting
- Tested each endpoint for proper responses
- Confirmed no other endpoints have similar issues

## 🚀 CI/CD Improvements

### GitHub Actions Workflow
- **Added:** Automated testing with GitHub Actions
- **Matrix Testing:** Runs on both Neovim stable and nightly
- **Triggers:** Automatic execution on push and pull requests
- **Test Coverage:** All 53 unit tests + optional integration tests

### Test Status Badge
- **Added:** Dynamic test badge in README
- **Real-time Status:** Shows current test pass/fail status
- **Links:** Click badge to view workflow runs

### Documentation
- **Added:** CI documentation (`.github/CI.md`)
- Explains workflow setup and troubleshooting
- Instructions for setting up `LICHESS_TOKEN` secret
- Local testing commands

## 📊 Test Results

All 53 unit tests passing:
- ✅ 15 utility tests
- ✅ 5 authentication tests
- ✅ 4 configuration tests
- ✅ 5 UI tests
- ✅ 13 puzzle tests
- ✅ 11 integration tests

## 🔄 Upgrade Notes

No breaking changes. Simply update to v0.3.1:

**Using lazy.nvim:**
```vim
:Lazy update nvim-chess
```

**Using packer.nvim:**
```vim
:PackerUpdate
```

**Manual:**
```bash
cd ~/.local/share/nvim/site/pack/vendor/start/nvim-chess
git pull
git checkout v0.3.1
```

## 📝 What's Changed

**Full Changelog:** https://github.com/linuxswords/nvim-chess/compare/v0.3.0...v0.3.1

### Commits
- `3168518` Release version 0.3.1
- `a14f5d7` Add CI documentation
- `dacd25b` Add GitHub Actions CI workflow and test badge
- `eb2f6bf` fix api endpoint for puzzles

## 🙏 Thanks

Thanks for using nvim-chess! Report issues at:
https://github.com/linuxswords/nvim-chess/issues

## 📦 Installation

See the [README](https://github.com/linuxswords/nvim-chess#installation) for installation instructions.
