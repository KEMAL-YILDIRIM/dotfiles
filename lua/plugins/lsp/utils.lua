-- dotnet
local excluded_dirs = {
	node_modules = "node_modules",
	git = "%.git",
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

F.find_csproj_file = function(path)
	return vim.fs.find(function(name)
		return name:match("%.csproj$") ~= nil
	end, { upward = true, path = path })[1]
end

-- Async build with callback (non-blocking, calls on_complete when done)
---@param csproj_path string
---@param on_complete fun(success: boolean, dll_path: string|nil)
F.build_project_async = function(csproj_path, on_complete)
	if not csproj_path then
		vim.notify("Build: ❗ csproj path is missing!", vim.log.levels.ERROR)
		if on_complete then on_complete(false, nil) end
		return
	end

	local project_name = vim.fn.fnamemodify(csproj_path, ":t:r")
	local project_dir = vim.fn.fnamemodify(csproj_path, ":h")
	vim.notify("Building " .. project_name .. "...", vim.log.levels.INFO)

	local cmd = { "dotnet", "build", csproj_path, "-clp:ErrorsOnly", "--nologo", "-c", "Debug" }
	local output_lines = {}

	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then table.insert(output_lines, line) end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then table.insert(output_lines, line) end
				end
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					local qf_items = {}
					for _, line in ipairs(output_lines) do
						local filename, lnum, col, text = line:match("([^%(]+)%((%d+),(%d+)%)%s*:%s*error%s*[%w%d]+:%s*(.*)")
						if filename and lnum and col and text then
							table.insert(qf_items, {
								filename = filename,
								lnum = tonumber(lnum),
								col = tonumber(col),
								text = text,
								type = "E",
							})
						elseif line:match("error") then
							table.insert(qf_items, { text = line, type = "E" })
						end
					end
					if #qf_items > 0 then
						vim.fn.setqflist(qf_items, "r")
						vim.cmd("copen")
					end
					vim.notify("Build: ❗ Failed", vim.log.levels.ERROR)
					if on_complete then on_complete(false, nil) end
				else
					vim.notify("Build: ✔️ " .. project_name, vim.log.levels.INFO)
					local filename = project_name .. ".dll"
					local debug_path = string.format("%s/bin/Debug/.*/", project_dir)
					local dll = vim.fn.findfile(filename, debug_path, 1)
					if dll == "" then dll = nil end
					if on_complete then on_complete(true, dll) end
				end
			end)
		end,
	})
end

-- Legacy async build (no callback)
F.build_project = function(csproj_path)
	F.build_project_async(csproj_path, nil)
end

F.build_cmd = function()
	local current_dir = vim.fn.expand("%:p:h") -- Get the current buffer's directory
	local project_path = F.find_csproj_file(current_dir)
	if not project_path then
		vim.notify("Couldn't find the csproj path")
		-- return existing make
		return vim.o.makeprg
	end

	local cmd = "dotnet build " .. project_path .. " -clp:ErrorsOnly --nologo -c debug"
	return cmd
end

-- Adding additonal functionality to utils
F.roslyn_cmd = function()
	vim.opt.rtp:append("D:/Nvim/roslyn.nvim")
	local roslyn_mason_path =
		vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "roslyn", "libexec"))
	local roslyn_cmd = {
		"dotnet",
		vim.fs.normalize(vim.fs.joinpath(roslyn_mason_path, "Microsoft.CodeAnalysis.LanguageServer.dll")),
		"--stdio",
		"--logLevel=Information",
		"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
		-- "--razorSourceGenerator=" .. roslyn_mason_path .. "/Microsoft.CodeAnalysis.Razor.Compiler.dll",
		-- "--razorDesignTimePath=" .. roslyn_mason_path .. "/Microsoft.NET.Sdk.Razor.DesignTime.targets",
		-- "--extension=" .. roslyn_mason_path .. "/Microsoft.VisualStudioCode.RazorExtension.dll",
	}

	return roslyn_cmd
end

F.get_user_secrets = function(current_dir)
	local proj_path = F.find_csproj_file(current_dir)
	if not proj_path then
		vim.notify("Couldn't find the csproj path")
		return nil
	end

	local proj_file = io.open(proj_path, "r")
	if not proj_file then
		vim.notify("Couldn't open the csproj file " .. proj_path)
		return nil
	end
	for line in proj_file:lines() do
		local _, guid = pcall(string.match, line, "<UserSecretsId>([0-9a-fA-F%-]+)</UserSecretsId>")
		if guid ~= nil and string.len(guid) > 0 then
			local path = vim.fs.joinpath(
				vim.fn.expand("~"),
				"AppData",
				"Roaming",
				"Microsoft",
				"UserSecrets",
				guid,
				"secrets.json"
			)
			F.log({ secret_path = path })
			return path
		end
	end

	vim.notify("user secrets doesn't exist! ")
	return nil
end

-- others
