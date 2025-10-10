# Continuous Integration

This project uses GitHub Actions for automated testing.

## Workflow: Tests

**File:** `.github/workflows/test.yml`

### Triggers
- Push to `master` or `main` branches
- Pull requests to `master` or `main` branches
- Manual workflow dispatch

### Test Matrix
Tests run on:
- Neovim stable
- Neovim nightly

### Steps

1. **Checkout code** - Uses `actions/checkout@v4`
2. **Install Neovim** - Uses `rhysd/action-setup-vim@v1` for specified version
3. **Install plenary.nvim** - Clones dependency into Neovim package path
4. **Install LuaRocks and LuaCov** - Installs coverage tools
5. **Run unit tests** - Executes `make test-unit` (120 tests)
6. **Run tests with coverage** - Generates coverage report (stable version only)
7. **Upload coverage to Codecov** - Uploads coverage data for tracking
8. **Run integration tests** (optional) - Runs `make test-integration` if `LICHESS_TOKEN` secret is configured

### Test Badge

The README displays dynamic badges showing test and coverage status:

```markdown
[![Tests](https://github.com/linuxswords/nvim-chess/actions/workflows/test.yml/badge.svg)](https://github.com/linuxswords/nvim-chess/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/linuxswords/nvim-chess/branch/master/graph/badge.svg)](https://codecov.io/gh/linuxswords/nvim-chess)
```

Test badge states:
- ✅ Green "passing" - All tests passed
- ❌ Red "failing" - Some tests failed
- 🟡 Yellow "no status" - Workflow hasn't run yet (wait ~10 minutes after first push)

Coverage badge shows:
- Percentage of code covered by tests
- Green for good coverage (>70%), yellow for medium (40-70%), red for low (<40%)

## Local Testing

Before pushing, run the same tests locally:

```bash
# Run unit tests (what CI runs)
make test-unit

# Run tests with coverage
make coverage

# Run all tests including integration (requires LICHESS_TOKEN)
export LICHESS_TOKEN=your_token_here
make test-all
```

### Coverage Reports

The coverage target generates a detailed coverage report:

```bash
make coverage
```

This will:
1. Install LuaCov if needed (`luarocks install luacov`)
2. Run all unit tests with coverage tracking
3. Generate `luacov.report.out` with line-by-line coverage data
4. Display a summary of coverage percentages

View the full report:
```bash
cat luacov.report.out
```

Coverage configuration is in `.luacov` and excludes test utilities and test files themselves.

## Integration Tests

Integration tests require a Lichess API token. To enable them in CI:

1. Go to repository Settings → Secrets and variables → Actions
2. Add a new repository secret named `LICHESS_TOKEN`
3. Set the value to your Lichess personal access token
4. Get a token from: https://lichess.org/account/oauth/token

**Note:** Integration tests continue on error to prevent token-related failures from blocking the workflow.

## Troubleshooting

### Badge shows "no status"
- Wait ~10 minutes after first workflow run
- Check that the workflow file path matches: `.github/workflows/test.yml`
- Verify workflow has run at least once in the Actions tab

### Tests fail in CI but pass locally
- Check Neovim version differences (CI runs stable and nightly)
- Verify plenary.nvim is installed correctly
- Review the workflow logs in the Actions tab

### Integration tests not running
- Verify `LICHESS_TOKEN` secret is set in repository settings
- Check that the token has required permissions: `board:play`, `puzzle:read`
- Note: Integration tests are optional and won't block the workflow

## Workflow File

View the complete workflow configuration in `.github/workflows/test.yml`.
