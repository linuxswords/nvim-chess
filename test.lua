#!/usr/bin/env nvim -l

-- Simple test runner for nvim-chess
-- Usage: nvim -l test.lua [test-type]

-- Add current directory to runtime path
vim.opt.runtimepath:prepend('.')

local args = vim.v.argv
local test_type = args[#args] -- Get last argument

print("🏁 nvim-chess Test Runner")
print("========================")

-- Enable mock mode for all tests
local mock = require('nvim-chess.test-utils.mock')
mock.enable()

local demo = require('nvim-chess.test-utils.demo')

if test_type == "basic" then
  print("Running basic demo...")
  demo.run_basic_demo()
elseif test_type == "errors" then
  print("Running error scenarios...")
  demo.test_error_scenarios()
elseif test_type == "game" then
  print("Running game flow test...")
  demo.test_game_flow()
elseif test_type == "bench" then
  print("Running benchmark...")
  demo.benchmark_board_rendering()
else
  print("Running all tests...")
  demo.quick_test()

  -- Wait a bit between tests
  vim.defer_fn(function()
    demo.test_error_scenarios()

    vim.defer_fn(function()
      demo.benchmark_board_rendering()
      print("\n✅ All tests completed!")
    end, 2000)
  end, 3000)
end

-- Keep nvim open for a bit to see results
vim.defer_fn(function()
  print("\n📝 Test completed. Exiting...")
  vim.cmd('qa!')
end, 8000)