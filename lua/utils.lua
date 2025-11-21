F = {}
F.log = function(v)
	vim.api.nvim_echo({ { vim.inspect(v), "WarningMsg" } }, true, {})
	return v
end

F.reload = function(v)
	require("plenary.reload").reload_module(v)
	return require(v)
end

local random = math.random
F.uuid = function()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
		return string.format("%x", v)
	end)
end

F.index_of = function(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
	return nil
end

---Runs the command and returns output with an ok
---@param cmd any
---@param path any
---@return nil | table
F.cmd = function(cmd, path)
	local current = vim.fn.getcwd()
	local result = {}

	-- On Windows, ensure cmd is executed through cmd.exe
	if vim.g.is_win then
		cmd = "cmd.exe /c " .. cmd
	end

	-- Use vim.fn.system instead of io.popen for better cross-platform support
	local info = "Command failed: " .. cmd
	if path then
		vim.fn.chdir(path)
		info = info .. " |> path: " .. path
	end

	local output = vim.fn.system(cmd)

	-- Handle command execution failures
	if vim.v.shell_error ~= 0 then
		-- Command failed, but we might still want partial output
		vim.api.nvim_echo({ { info, "ErrorMsg" } }, true, {})
		return nil
	end

	-- Split the output by newlines
	if output and output ~= "" then
		for line in output:gmatch("[^\r\n]+") do
			table.insert(result, line)
		end
	end

	if path then
		vim.fn.chdir(current)
	end

	return result
end

-- Return a key with the given value (or nil if not found).  If there are
-- multiple keys with that value, the particular key returned is arbitrary.
F.key_of = function(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return nil
end

local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
F.triggerESC = function()
	vim.api.nvim_feedkeys(esc, "nx", false)
end

---Read file from the path
---@param path string
---@return string | nil
F.read_file = function(path)
	path = vim.fs.normalize(path)
	local file, content = nil, nil
	local success, err = pcall(function()
		file = io.open(path, "r")
		assert(file, "File not found!")
		content = file:read("*all")
		file:close()
	end)

	if not success then
		print("Error reading file:", err)
	end

	return content
end
