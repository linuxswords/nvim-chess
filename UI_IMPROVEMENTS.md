# UI Improvements Plan

This document tracks planned UI/UX improvements for nvim-chess.

## Status Legend
- ✅ **Completed** - Implemented and tested
- 📝 **Saved for later** - Approved but not yet implemented
- 💡 **Proposed** - Suggested but not yet approved

---

## Phase 1: Visual Feedback & Core UX

### ✅ 1. Syntax Highlighting for Chess Pieces
**Status**: Completed in v0.5.0

Added highlight groups and real-time syntax highlighting:
- `ChessWhitePiece` - Bold white pieces
- `ChessBlackPiece` - Bold black pieces
- `ChessLightSquare` - Beige background (#F0D9B5)
- `ChessDarkSquare` - Brown background (#B58863)

Highlights applied via `nvim_buf_add_highlight` with UTF-8 aware byte position calculation.

**Files modified**: `lua/nvim-chess/puzzle/renderer.lua`

---

### ✅ 2. Better Notifications with Icons
**Status**: Completed in v0.5.0

Replaced plain text notifications with emoji-enhanced messages using proper log levels:

| Icon | Context | Example |
|------|---------|---------|
| ✓ | Correct move | "✓ Correct! Continue..." |
| ✗ | Wrong/Error | "✗ Wrong move! Expected: e2e4" |
| 🎉 | Puzzle solved | "🎉 Puzzle solved!" |
| 🧩 | New puzzle | "🧩 New Puzzle (Rating: 1850)" |
| 💡 | Hint | "💡 Hint: Move from e2 to e4" |
| 📖 | Solution | "📖 Solution: e2e4 → d7d8q" |
| ⚠️  | Warning | "⚠️  Puzzle already completed" |
| 🤖 | Opponent move | "🤖 Opponent plays: e7e5" |
| ⏭️  | Skip | "⏭️  Puzzle skipped" |
| 📌 | Stay | "📌 Staying on current puzzle" |
| 🔒 | Auth required | "🔒 Authentication required" |

**Files modified**: `lua/nvim-chess/puzzle/manager.lua`

---

### 📝 3. Progress Bar for Multi-Move Puzzles
**Status**: Saved for later

Show visual progress through puzzle solution sequence.

**Proposed implementation**:
```
Progress: [████████░░] 8/10 moves
```

Or using virtual text below the board:
```lua
vim.api.nvim_buf_set_extmark(buf, ns, line, 0, {
  virt_text = {{"[" .. string.rep("█", completed) .. string.rep("░", remaining) .. "]", "Comment"}},
  virt_text_pos = "eol"
})
```

**Files to modify**: `lua/nvim-chess/puzzle/renderer.lua`

---

### 📝 4. Theme Badges for Puzzle Categories
**Status**: Saved for later

Add visual badges showing puzzle themes (tactics, endgame, etc.).

**Proposed implementation**:
```
Themes: [🎯 Fork] [⚔️  Pin] [🏰 Endgame]
```

Could use highlight groups for each theme category:
- Tactics: `ChessThemeTactics` (orange)
- Endgame: `ChessThemeEndgame` (purple)
- Opening: `ChessThemeOpening` (green)

**Files to modify**: `lua/nvim-chess/puzzle/renderer.lua`

---

## Phase 2: Advanced Visual Features

### 💡 5. Last Move Highlighting
**Status**: Proposed

Highlight the last move made on the board (both from and to squares).

**Proposed implementation**:
```lua
vim.api.nvim_buf_add_highlight(buf, ns, "ChessLastMoveFrom", line, col_start, col_end)
vim.api.nvim_buf_add_highlight(buf, ns, "ChessLastMoveTo", line, col_start, col_end)
```

Highlight groups:
- `ChessLastMoveFrom` - Yellow/gold background for source square
- `ChessLastMoveTo` - Green background for destination square

**Files to modify**: `lua/nvim-chess/puzzle/renderer.lua`, `lua/nvim-chess/puzzle/solver.lua`

---

### 💡 6. Legal Move Indicators (Hint Mode)
**Status**: Proposed

When hint is shown, highlight all legal moves for that piece.

**Proposed implementation**:
- Use extmarks with virtual text to show possible destination squares
- Add dots or arrows showing legal moves

```lua
-- Show legal move destinations
for _, move in ipairs(legal_moves) do
  vim.api.nvim_buf_set_extmark(buf, ns, rank, file, {
    virt_text = {{"○", "ChessLegalMove"}},
    virt_text_pos = "overlay"
  })
end
```

**Files to modify**: `lua/nvim-chess/puzzle/solver.lua`, `lua/nvim-chess/puzzle/renderer.lua`

---

### 💡 7. Check/Checkmate Indicators
**Status**: Proposed

Visual indicator when king is in check or checkmate.

**Proposed implementation**:
- Highlight king square in red when in check
- Add "⚠ CHECK" virtual text
- Use `ChessCheck` highlight group

```lua
if is_in_check(board_state) then
  vim.api.nvim_buf_add_highlight(buf, ns, "ChessCheck", king_line, king_col, king_col + 3)
  vim.api.nvim_buf_set_extmark(buf, ns, board_end_line, 0, {
    virt_text = {{"⚠ CHECK", "ErrorMsg"}},
    virt_text_pos = "eol"
  })
end
```

**Files to modify**: `lua/nvim-chess/chess/engine.lua`, `lua/nvim-chess/puzzle/renderer.lua`

---

## Phase 3: Interactive Enhancements

### 💡 8. Floating Window for Move Input
**Status**: Proposed

Replace vim.fn.input() with modern floating window for move entry.

**Proposed implementation**:
```lua
local function show_move_input()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 30
  local height = 3
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = width,
    height = height,
    row = 1,
    col = 0,
    style = "minimal",
    border = "rounded",
    title = " Enter Move ",
    title_pos = "center"
  })
  -- Enable input mode
end
```

**Files to modify**: `lua/nvim-chess/puzzle/renderer.lua`

---

### 💡 9. Move History Panel
**Status**: Proposed

Show move history in a side panel with notation and navigation.

**Proposed implementation**:
```
┌─ MOVE HISTORY ─────┐
│ 1. e4    e5        │
│ 2. Nf3   Nc6       │
│ 3. Bc4   Nf6       │
│ 4. You → ?         │
└────────────────────┘
```

Allow clicking/navigating moves to review position at that point.

**Files to modify**: New `lua/nvim-chess/puzzle/history_panel.lua`

---

### 💡 10. Puzzle Statistics Dashboard
**Status**: Proposed

Show comprehensive stats in a dedicated buffer.

**Proposed implementation**:
```
┌─ PUZZLE STATISTICS ──────────────────┐
│                                       │
│  Total Solved:    42 / 50  (84%)     │
│  Success Rate:    78%                 │
│  Average Rating:  1650                │
│                                       │
│  By Theme:                            │
│    Fork:          12 / 15  (80%)     │
│    Pin:            8 / 10  (80%)     │
│    Endgame:        5 / 8   (62%)     │
│                                       │
│  Recent Puzzles:                      │
│    ✓ abc123  (1850)  Fork            │
│    ✓ def456  (1720)  Endgame         │
│    ✗ ghi789  (1950)  Pin             │
│                                       │
└───────────────────────────────────────┘
```

**Files to modify**: New `lua/nvim-chess/puzzle/stats.lua`, `lua/nvim-chess/puzzle/state.lua`

---

### 💡 11. Board Flip Animation
**Status**: Proposed

Smooth transition when flipping board perspective (White/Black view).

**Proposed implementation**:
- Use timer to gradually update board rendering
- Or instant flip with brief highlight flash to show orientation change

**Files to modify**: `lua/nvim-chess/puzzle/renderer.lua`

---

### 💡 12. Puzzle Difficulty Indicator
**Status**: Proposed

Visual representation of puzzle difficulty based on rating.

**Proposed implementation**:
```
Difficulty: ⭐⭐⭐☆☆  (1850)

Rating ranges:
< 1200: ⭐☆☆☆☆ (Beginner)
1200-1500: ⭐⭐☆☆☆ (Easy)
1500-1800: ⭐⭐⭐☆☆ (Medium)
1800-2100: ⭐⭐⭐⭐☆ (Hard)
> 2100: ⭐⭐⭐⭐⭐ (Expert)
```

**Files to modify**: `lua/nvim-chess/puzzle/renderer.lua`

---

## Implementation Notes

### Performance Considerations
- Use buffer-local namespaces for highlights to avoid conflicts
- Clear old extmarks before adding new ones
- Debounce rapid updates to avoid flickering

### Accessibility
- Ensure all visual indicators have text equivalents
- Support ASCII fallback mode for terminals without Unicode
- Allow customization of all colors/themes

### Configuration
Allow users to enable/disable features:
```lua
require('nvim-chess').setup({
  ui = {
    syntax_highlighting = true,
    notification_icons = true,
    progress_bar = true,
    theme_badges = true,
    last_move_highlight = true,
    legal_move_hints = false,
    check_indicator = true,
    floating_input = true,
    move_history_panel = false,
  }
})
```

---

## Next Steps

1. ✅ Complete Phase 1 items #1-2
2. 📝 Implement Phase 1 items #3-4 (progress bar, theme badges)
3. Review and prioritize Phase 2 items
4. Gather user feedback on proposed features
5. Create detailed specs for Phase 3 interactive features
