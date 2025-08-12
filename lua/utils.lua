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
	local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return string.gsub(template, '[xy]', function(c)
		local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
		return string.format('%x', v)
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
	local is_win = vim.uv.os_uname().sysname:lower():find("win") == 1
	if is_win then
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



-- csharp helper section
local excluded_dirs = {
	node_modules = "node_modules",
	git = ".git",
	dist = "dist",
	wwwroot = "wwwroot",
	properties = "properties",
	build = "build",
	bin = "bin",
	debug = "debug",
	obj = "obj",
}

local is_excluded = function(name)
	for _, pattern in pairs(excluded_dirs) do
		if string.match(name:lower(), pattern) then
			return true
		end
	end
	return false
end

F.roslyn_cmd = function()
	vim.opt.rtp:append("D:/Nvim/roslyn.nvim")
	local attach = require 'plugins.lsp.attach'
	local nvim_data_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath "data", "mason", "packages"))
	local roslyn_mason_path = vim.fs.normalize(vim.fs.joinpath(nvim_data_path, "roslyn", "libexec"))
	local roslyn_cmd = {
		"dotnet",
		vim.fs.normalize(vim.fs.joinpath(roslyn_mason_path, "Microsoft.CodeAnalysis.LanguageServer.dll")),
		"--stdio",
		"--logLevel=Information",
		"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
	}

	-- vim.opt.rtp:append("D:/Nvim/rzls.nvim")
	-- local rzls_mason_path = vim.fs.normalize(vim.fs.joinpath(nvim_data_path, "rzls", "libexec"))
	-- vim.list_extend(roslyn_cmd, {
	-- 	'--razorSourceGenerator=' ..
	-- 	vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, 'Microsoft.CodeAnalysis.Razor.Compiler.dll')),
	-- 	'--razorDesignTimePath=' ..
	-- 	vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, 'Targets', 'Microsoft.NET.Sdk.Razor.DesignTime.targets')),
	-- 	'--extension=' ..
	-- 	vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, 'RazorExtension', 'Microsoft.VisualStudioCode.RazorExtension.dll')),
	-- })

	return roslyn_cmd;
end

F.find_csproj_file = function(path)
	local dirs = { path }

	while #dirs > 0 do
		local dir = table.remove(dirs, 1)
		for other, fs_obj_type in vim.fs.dir(dir) do
			local name = vim.fs.joinpath(dir, other)

			if fs_obj_type == "file" then
				if name:match("%.csproj$") then
					F.log("Project file found: " .. name)
					return name
				end
			elseif fs_obj_type == "directory" and not is_excluded(name) then
				dirs[#dirs + 1] = name
			end
		end
		if #dirs == 0 then
			local parent = vim.fn.fnamemodify(dir, ':h')
			if parent ~= '/' then
				dirs[1] = parent
			end
		end
	end
end
