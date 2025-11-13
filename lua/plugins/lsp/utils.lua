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

F.build_project = function(csproj_path)
	local result = "Build: ❗\n"
	if not csproj_path then
		vim.notify(result .. "csproj path is missing!", vim.log.levels.INFO)
		return
	end

	local cmd = { "dotnet", "build", csproj_path, "-clp:ErrorsOnly", "--nologo", "-c", "debug" }
	local output_lines = {}

	local on_exit = function()
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
		else
			result = "Build: ✔️\n"
		end
		vim.notify(result .. "executed: " .. vim.inspect(cmd) .. "\n", vim.log.levels.INFO)
	end

	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(output_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(output_lines, line)
					end
				end
			end
		end,
		on_exit = function()
			on_exit()
		end,
	})
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
F.roslyn_cmd = function(opts)
	vim.opt.rtp:append("D:/Nvim/roslyn.nvim")
	local nvim_data_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages"))
	local roslyn_mason_path = vim.fs.normalize(vim.fs.joinpath(nvim_data_path, "roslyn", "libexec"))
	local roslyn_cmd = {
		"dotnet",
		vim.fs.normalize(vim.fs.joinpath(roslyn_mason_path, "Microsoft.CodeAnalysis.LanguageServer.dll")),
		"--stdio",
		"--logLevel=Information",
		"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
	}

	if opts and opts.rzls then
		vim.opt.rtp:append("D:/Nvim/rzls.nvim")
		local rzls_mason_path = vim.fs.normalize(vim.fs.joinpath(nvim_data_path, "rzls", "libexec", "RazorExtension"))
		vim.list_extend(roslyn_cmd, {
			"--razorSourceGenerator="
				.. vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll")),
			"--razorDesignTimePath=" .. vim.fs.normalize(
				vim.fs.joinpath(rzls_mason_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets")
			),
			"--extension=" .. vim.fs.normalize(
				vim.fs.joinpath(rzls_mason_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll")
			),
		})
	end

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
