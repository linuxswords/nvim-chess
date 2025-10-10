-- LuaCov runner for plenary tests
-- This file ensures LuaCov is loaded before tests run

-- Get LuaRocks paths from environment or defaults
local lua_path = os.getenv("LUA_PATH") or ""
local lua_cpath = os.getenv("LUA_CPATH") or ""

-- Add environment paths if set
if lua_path ~= "" and not lua_path:match("^;;") then
  package.path = lua_path .. ";" .. package.path
end

if lua_cpath ~= "" and not lua_cpath:match("^;;") then
  package.cpath = lua_cpath .. ";" .. package.cpath
end

-- Also add common system paths where LuaRocks installs modules
local common_paths = {
  "/usr/local/share/lua/5.1/?.lua",
  "/usr/local/share/lua/5.1/?/init.lua",
  "/usr/share/lua/5.1/?.lua",
  "/usr/share/lua/5.1/?/init.lua",
  "/usr/local/lib/lua/5.1/?.so",
  "/usr/lib/lua/5.1/?.so",
}

for _, path in ipairs(common_paths) do
  if path:match("%.lua$") then
    if not package.path:find(path, 1, true) then
      package.path = package.path .. ";" .. path
    end
  else
    if not package.cpath:find(path, 1, true) then
      package.cpath = package.cpath .. ";" .. path
    end
  end
end

-- Debug: print paths (comment out in production)
-- print("LUA_PATH: " .. package.path)
-- print("LUA_CPATH: " .. package.cpath)

-- Try to load and initialize luacov
local ok, luacov = pcall(require, 'luacov.runner')
if ok then
  -- LuaCov loaded successfully, initialize it
  luacov.init()
  print("✓ LuaCov coverage tracking enabled")
else
  -- Try without .runner
  ok, luacov = pcall(require, 'luacov')
  if ok then
    print("✓ LuaCov loaded (basic)")
  else
    print("⚠ LuaCov not found - running tests without coverage")
    print("   package.path: " .. package.path:sub(1, 200) .. "...")
  end
end
