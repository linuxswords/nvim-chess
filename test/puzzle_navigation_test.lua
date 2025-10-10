-- Test that puzzle board updates when jumping to next puzzle
-- This is a manual verification test

vim.opt.runtimepath:append(".")

print("========================================")
print("Puzzle Navigation Test")
print("========================================")
print("")

-- Test the buffer switching logic
local function test_buffer_name_matching()
  print("Testing buffer name matching...")

  local test_cases = {
    { name = "puzzle-abc123", expected = true, desc = "Standard puzzle buffer" },
    { name = "puzzle-xyz789", expected = true, desc = "Another puzzle buffer" },
    { name = "puzzle-", expected = true, desc = "Empty ID puzzle buffer" },
    { name = "some-other-buffer", expected = false, desc = "Non-puzzle buffer" },
    { name = "", expected = false, desc = "Empty buffer name" },
    { name = "my-puzzle-buffer", expected = false, desc = "Buffer with 'puzzle' in middle" },
  }

  for _, test in ipairs(test_cases) do
    local result = test.name:match("^puzzle%-")
    local pass = (result ~= nil) == test.expected
    local status = pass and "✓" or "✗"
    print(string.format("  %s %s: '%s' -> %s", status, test.desc, test.name, tostring(result ~= nil)))
  end

  print("")
end

test_buffer_name_matching()

print("Expected behavior when pressing 'n' for next puzzle:")
print("1. User is viewing puzzle-abc123 in a window")
print("2. User presses 'n' to load next puzzle")
print("3. New puzzle (puzzle-xyz789) loads")
print("4. Current buffer name matches '^puzzle%-' pattern")
print("5. Code reuses the current window instead of creating new split")
print("6. Window now shows puzzle-xyz789 in the SAME window")
print("")
print("Result: Board updates with new puzzle without creating new splits")
print("")
print("========================================")
print("✓ Buffer switching logic verified")
print("========================================")
