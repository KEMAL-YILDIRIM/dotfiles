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

-- ---------------------------------------------------------------------------
-- Active C# build configuration (Debug / Release), VS-dropdown-style.
--
-- Persisted on `vim.g.dap_cs_configuration` so it survives across builds
-- in the same session. Default: "Debug".
-- ---------------------------------------------------------------------------

--- Returns the current C# build configuration ("Debug" or "Release").
F.get_dap_cs_configuration = function()
	local cfg = vim.g.dap_cs_configuration
	if cfg == "Debug" or cfg == "Release" then
		return cfg
	end
	return "Debug"
end

--- Sets the C# build configuration. Validates input; no-op on bad value.
F.set_dap_cs_configuration = function(cfg)
	if cfg ~= "Debug" and cfg ~= "Release" then
		vim.notify("DAP cs configuration: invalid value '" .. tostring(cfg) .. "'", vim.log.levels.WARN)
		return
	end
	vim.g.dap_cs_configuration = cfg
	vim.notify("DAP cs configuration: " .. cfg, vim.log.levels.INFO)
end

--- Interactive picker for Debug/Release. Bound to <leader><F8>.
F.pick_dap_cs_configuration = function()
	local current = F.get_dap_cs_configuration()
	vim.ui.select({ "Debug", "Release" }, {
		prompt = "C# build configuration (current: " .. current .. "):",
	}, function(choice)
		if choice then
			F.set_dap_cs_configuration(choice)
		end
	end)
end

--- Parses <TargetFramework> (single) or the first entry of <TargetFrameworks>
--- (multi) from a csproj. Returns the TFM string (e.g. "net8.0") or nil.
---
--- We can't rely on a lexical glob of bin/<cfg>/*/ because subdirs like
--- "net10.0" and "net8.0" sort '1' < '8', which makes the launcher pick a
--- stale leftover TFM directory. Parsing the csproj is the only reliable
--- way to know which TFM `dotnet build` will actually produce.
F.get_csproj_tfm = function(csproj_path)
	local ok, lines = pcall(vim.fn.readfile, csproj_path)
	if not ok or not lines then
		return nil
	end
	local blob = table.concat(lines, "\n")
	local single = blob:match("<TargetFramework>%s*([^<%s]+)%s*</TargetFramework>")
	if single then
		return single
	end
	local multi = blob:match("<TargetFrameworks>%s*([^<]+)%s*</TargetFrameworks>")
	if multi then
		local first = multi:match("([^;%s]+)")
		if first and first ~= "" then
			return first
		end
	end
	return nil
end

--- Resolves the freshly-built DLL inside bin/<configuration>/.
--- Strategy:
---   1. If csproj declares a TFM, look at bin/<cfg>/<tfm>/<name>.dll directly.
---   2. Fallback A: glob bin/<cfg>/*/<name>.dll and pick the newest by mtime
---      (avoids the lexical-sort footgun where net10.0 < net8.0).
---   3. Fallback B: recursive vim.fs.find under bin/<cfg>.
local function resolve_built_dll(project_dir, project_name, configuration, csproj_path)
	local norm_dir = vim.fs.normalize(project_dir)
	local filename = project_name .. ".dll"
	local bin_cfg = norm_dir .. "/bin/" .. configuration

	local tfm = F.get_csproj_tfm(csproj_path)
	if tfm then
		local candidate = bin_cfg .. "/" .. tfm .. "/" .. filename
		if vim.uv.fs_stat(candidate) then
			return vim.fs.normalize(candidate)
		end
	end

	local matches = vim.fn.glob(bin_cfg .. "/*/" .. filename, false, true)
	if #matches > 0 then
		local best, best_mtime = nil, -1
		for _, m in ipairs(matches) do
			local st = vim.uv.fs_stat(m)
			local mtime = (st and st.mtime and st.mtime.sec) or 0
			if mtime > best_mtime then
				best, best_mtime = m, mtime
			end
		end
		if best then
			return vim.fs.normalize(best)
		end
	end

	local found = vim.fs.find(filename, { path = bin_cfg, type = "file" })
	if #found > 0 then
		return vim.fs.normalize(found[1])
	end

	return nil
end

-- Async build with callback (non-blocking, calls on_complete when done)
---@param csproj_path string
---@param on_complete fun(success: boolean, dll_path: string|nil)
F.build_project_async = function(csproj_path, on_complete)
	if not csproj_path then
		vim.notify("Build: ❗ csproj path is missing!", vim.log.levels.ERROR)
		if on_complete then
			on_complete(false, nil)
		end
		return
	end

	local project_name = vim.fn.fnamemodify(csproj_path, ":t:r")
	local project_dir = vim.fn.fnamemodify(csproj_path, ":h")
	local configuration = F.get_dap_cs_configuration()
	vim.notify("Building " .. project_name .. " (" .. configuration .. ")...", vim.log.levels.INFO)

	local cmd = { "dotnet", "build", csproj_path, "-clp:ErrorsOnly", "--nologo", "-c", configuration }
	local output_lines = {}

	F.safe_jobstart(cmd, {
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
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					local qf_items = {}
					for _, line in ipairs(output_lines) do
						local filename, lnum, col, text =
							line:match("([^%(]+)%((%d+),(%d+)%)%s*:%s*error%s*[%w%d]+:%s*(.*)")
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
					if on_complete then
						on_complete(false, nil)
					end
				else
					vim.notify("Build: ✔️ " .. project_name .. " (" .. configuration .. ")", vim.log.levels.INFO)
					local dll = resolve_built_dll(project_dir, project_name, configuration, csproj_path)
					if on_complete then
						on_complete(true, dll)
					end
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

	local cmd = "dotnet build " .. project_path .. " -clp:ErrorsOnly --nologo -c " .. F.get_dap_cs_configuration()
	return cmd
end

-- Adding additonal functionality to utils
F.roslyn_cmd = function()
	-- NOTE: removed vim.opt.rtp:append("D:/Nvim/roslyn.nvim") — dev artifact
	-- that unconditionally corrupted rtp on every startup. roslyn.nvim is
	-- loaded by lazy.nvim from the registry; no manual rtp manipulation needed.
	local roslyn_mason_path =
		vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "roslyn", "libexec"))
	local roslyn_cmd = {
		"dotnet",
		vim.fs.normalize(vim.fs.joinpath(roslyn_mason_path, "Microsoft.CodeAnalysis.LanguageServer.dll")),
		"--stdio",
		"--logLevel=Information",
		"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
		"--razorSourceGenerator=" .. roslyn_mason_path .. "/.razorExtension/Microsoft.CodeAnalysis.Razor.Compiler.dll",
		"--razorDesignTimePath="
			.. roslyn_mason_path
			.. "/.razorExtension/Targets/Microsoft.NET.Sdk.Razor.DesignTime.targets",
		"--extension=" .. roslyn_mason_path .. "/.razorExtension/Microsoft.VisualStudioCode.RazorExtension.dll",
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
