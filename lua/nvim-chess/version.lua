local M = {}

local buffer = require("nvim-chess.utils.buffer")

-- Plugin version information
M.version = "0.5.0"
M.name = "nvim-chess"
M.description = "A Neovim plugin for solving chess puzzles from Lichess.org"
M.author = "linuxswords"
M.homepage = "https://github.com/linuxswords/nvim-chess"
M.license = "MIT"

-- Get the current version string
function M.get_version()
	return M.version
end

-- Get full plugin information
function M.get_info()
	return {
		name = M.name,
		version = M.version,
		description = M.description,
		author = M.author,
		homepage = M.homepage,
		license = M.license,
	}
end

-- Show version in Neovim notification
function M.show_version()
	vim.notify(string.format("%s v%s", M.name, M.version), vim.log.levels.INFO)
end

-- Show detailed info in a buffer
function M.show_info()
	local info = M.get_info()
	local lines = {
		string.format("%s", info.name),
		string.rep("=", #info.name),
		"",
		string.format("Version:     %s", info.version),
		string.format("Description: %s", info.description),
		string.format("Author:      %s", info.author),
		string.format("Homepage:    %s", info.homepage),
		string.format("License:     %s", info.license),
		"",
		"For more information, visit:",
		info.homepage,
	}

	-- Create or reuse info buffer
	local buf = buffer.create_or_get("nvim-chess-info")

	-- Update buffer content
	buffer.set_lines(buf, lines)

	-- Open in new window if not already visible
	buffer.show_in_window(buf)

	return buf
end

-- Compare version with another version string
-- Returns: -1 if this < other, 0 if equal, 1 if this > other
function M.compare_version(other_version)
	local function parse_version(ver)
		local major, minor, patch = ver:match("^(%d+)%.(%d+)%.(%d+)")
		return {
			major = tonumber(major) or 0,
			minor = tonumber(minor) or 0,
			patch = tonumber(patch) or 0,
		}
	end

	local this = parse_version(M.version)
	local other = parse_version(other_version)

	if this.major ~= other.major then
		return this.major < other.major and -1 or 1
	end

	if this.minor ~= other.minor then
		return this.minor < other.minor and -1 or 1
	end

	if this.patch ~= other.patch then
		return this.patch < other.patch and -1 or 1
	end

	return 0
end

-- Check if current version is at least the specified version
function M.is_at_least(min_version)
	return M.compare_version(min_version) >= 0
end

return M
