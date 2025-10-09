# Release Checklist

Use this checklist when preparing a new release of nvim-chess.

## Pre-Release (Development)

- [ ] All planned features implemented
- [ ] All tests passing
  - [ ] `make test-unit` passes
  - [ ] `make test-integration` passes (if applicable)
- [ ] Documentation updated
  - [ ] README.md reflects new features
  - [ ] Command reference updated
  - [ ] Usage examples added
- [ ] CHANGELOG.md updated with changes
  - [ ] Added section for new version
  - [ ] Listed all features, changes, and fixes
  - [ ] Added date to release entry
- [ ] Version bumped in `lua/nvim-chess/version.lua`
- [ ] No `TODO` or `FIXME` comments in release code
- [ ] Code reviewed and cleaned up

## Version Decision

- [ ] Determine version number (MAJOR.MINOR.PATCH)
  - [ ] Breaking changes? → Increment MAJOR
  - [ ] New features? → Increment MINOR
  - [ ] Bug fixes only? → Increment PATCH
- [ ] Check for breaking changes
  - [ ] List breaking changes in CHANGELOG
  - [ ] Create migration guide if needed
- [ ] Review semantic versioning rules

## Pre-Release Testing

- [ ] Test installation with lazy.nvim
  ```lua
  { 'linuxswords/nvim-chess', branch = 'master' }
  ```
- [ ] Test all new features
- [ ] Test all commands work
- [ ] Check for errors in logs (`:messages`)
- [ ] Test on clean Neovim config

## Release Process

### Step 1: Prepare Release Commit

- [ ] Commit all changes
  ```bash
  git add .
  git commit -m "Release v0.X.X"
  ```
- [ ] Push to remote
  ```bash
  git push origin master
  ```

### Step 2: Create Git Tag

- [ ] Create annotated git tag with detailed message
  ```bash
  git tag -a v0.X.X -m "Release v0.X.X: <title>

  Features:
  - Feature 1
  - Feature 2

  Changes:
  - Change 1

  Fixes:
  - Fix 1
  "
  ```

### Step 3: Push Tag

- [ ] Push tag to GitHub
  ```bash
  git push origin v0.X.X
  ```
- [ ] Verify tag appears on GitHub
  - https://github.com/linuxswords/nvim-chess/tags

### Step 4: Create GitHub Release

- [ ] Go to: https://github.com/linuxswords/nvim-chess/releases/new
- [ ] Select the tag: v0.X.X
- [ ] Title: "v0.X.X - <Release Title>"
- [ ] Description: Include:
  - [ ] Overview of changes (copy from CHANGELOG)
  - [ ] Installation instructions
  ```markdown
  ## Installation

  ### lazy.nvim
  ```lua
  {
    'linuxswords/nvim-chess',
    tag = 'v0.X.X',
    dependencies = { 'nvim-lua/plenary.nvim' }
  }
  ```

  ### packer.nvim
  ```lua
  use {
    'linuxswords/nvim-chess',
    tag = 'v0.X.X',
    requires = { 'nvim-lua/plenary.nvim' }
  }
  ```
  ```
  - [ ] Breaking changes section (if any)
  - [ ] Migration guide link (if needed)
  - [ ] Known issues (if any)
  - [ ] Link to CHANGELOG
- [ ] Attach any assets (optional)
- [ ] Mark as pre-release if < v1.0.0 (optional)
- [ ] Publish release

## Post-Release Verification

- [ ] Verify release appears on GitHub releases page
- [ ] Check tag is visible: `git fetch --tags && git tag -l`
- [ ] Test installation with lazy.nvim using new tag
  ```lua
  { 'linuxswords/nvim-chess', tag = 'v0.X.X' }
  ```
- [ ] Test installation with packer.nvim using new tag
- [ ] Verify `:ChessVersion` shows correct version
- [ ] Check `:ChessInfo` displays correct information

## Post-Release Tasks

- [ ] Update any external documentation links
- [ ] Monitor GitHub issues for problems
- [ ] Announce release (optional)
  - [ ] Reddit: r/neovim
  - [ ] Twitter/X
  - [ ] Neovim Discord
- [ ] Update project status (if applicable)

## Version Tracking

- [ ] Record release in internal tracking (if used)
- [ ] Update roadmap with completed features
- [ ] Plan next version features

## Rollback Plan (if issues found)

If critical issues are discovered:

1. [ ] Delete tag locally
   ```bash
   git tag -d v0.X.X
   ```
2. [ ] Delete tag remotely
   ```bash
   git push origin :refs/tags/v0.X.X
   ```
3. [ ] Delete or mark GitHub Release as pre-release
4. [ ] Fix critical issues
5. [ ] Restart release process with patch version (v0.X.X+1)

## Notes

- Always test thoroughly before releasing
- Document breaking changes clearly
- Provide migration guides for major changes
- Keep CHANGELOG up to date
- Use semantic versioning strictly

## Release Template

```markdown
# v0.X.X - <Release Title>

## What's New

<Brief overview of main features/changes>

## Features

- Feature 1
- Feature 2

## Changes

- Change 1

## Fixes

- Fix 1

## Installation

### lazy.nvim
\`\`\`lua
{
  'linuxswords/nvim-chess',
  tag = 'v0.X.X',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
\`\`\`

### packer.nvim
\`\`\`lua
use {
  'linuxswords/nvim-chess',
  tag = 'v0.X.X',
  requires = { 'nvim-lua/plenary.nvim' }
}
\`\`\`

## Full Changelog

See [CHANGELOG.md](https://github.com/linuxswords/nvim-chess/blob/master/CHANGELOG.md) for complete details.
```

---

**Current Version:** v0.2.0
**Last Updated:** 2025-10-09
