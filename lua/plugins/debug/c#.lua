local dap = require('dap')

local netcoredbg_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath('data'),
  'mason/packages/netcoredbg/netcoredbg/netcoredbg.exe'))
local netcoredbg_adapter = {
  type = 'executable',
  command = netcoredbg_path,
  args = { '--interpreter=vscode' },
}
dap.adapters.coreclr = netcoredbg_adapter
dap.adapters.netcoredbg = netcoredbg_adapter



-- Static attach configurations
local attach_configs = {
  {
    type = 'coreclr',
    name = '[Attach] Pick Process',
    request = 'attach',
    processId = require('dap.utils').pick_process,
  },
  {
    type = 'coreclr',
    name = '[Attach] Azure Function',
    request = 'attach',
    processId = function()
      local pid = nil
      while not pid do
        pid = require('azure-functions').get_process_id()
      end
      return pid
    end,
  },
  {
    type = 'coreclr',
    name = '[Attach] Smart (Solution)',
    request = 'attach',
    processId = function()
      if not vim.g.roslyn_nvim_selected_solution then
        return vim.notify('No solution file found')
      end

      local solution_dir = vim.fs.dirname(vim.g.roslyn_nvim_selected_solution)

      local res = vim.system({ 'dotnet', 'sln', vim.g.roslyn_nvim_selected_solution, 'list' }):wait()
      local csproj_files = vim.iter(vim.split(res.stdout, '\n'))
          :map(function(it)
            local fullpath = vim.fs.normalize(vim.fs.joinpath(solution_dir, it))
            if fullpath ~= solution_dir and vim.uv.fs_stat(fullpath) then
              return fullpath
            else
              return nil
            end
          end)
          :totable()

      return require('dap.utils').pick_process({
        filter = function(proc)
          return vim.iter(csproj_files):find(function(file)
            if vim.endswith(proc.name, vim.fn.fnamemodify(file, ':t:r')) then
              return true
            end
          end)
        end,
      })
    end,
  },
}

-- Static launch configurations
local launch_configs = {
  {
    type = 'coreclr',
    name = '[Launch] Current Project',
    request = 'launch',
    -- _build_info is populated dynamically when selected
    _build_info_fn = function()
      local current_dir = vim.fn.expand('%:p:h')
      local csproj = F.find_csproj_file(current_dir)
      if not csproj then
        vim.notify("Couldn't find the csproj path", vim.log.levels.ERROR)
        return nil
      end
      return {
        csproj = csproj,
        project_dir = vim.fn.fnamemodify(csproj, ':h'),
        project_name = vim.fn.fnamemodify(csproj, ':t:r'),
      }
    end,
  },
  {
    type = 'coreclr',
    name = '[Test] Debug Test Under Cursor',
    request = 'launch',
    program = 'dotnet',
    args = {},
    cwd = '${workspaceFolder}',
    stopAtEntry = false,
    console = 'integratedTerminal',
  },
}

local find_launch_settings = function()
	local current_dir = vim.fn.expand("%:p:h")
	local csproj = F.find_csproj_file(current_dir)
	if csproj then
		local project_dir = vim.fn.fnamemodify(csproj, ":h")
		local path = vim.fs.normalize(vim.fs.joinpath(project_dir, "Properties", "launchSettings.json"))
		if vim.uv.fs_stat(path) then
			return path, csproj
		end
	end
	-- Fallback: search from cwd
	local found = vim.fn.globpath(vim.fn.getcwd(), "**/Properties/launchSettings.json", false, true)
	if #found > 0 then
		local path = found[1]
		local project_dir = vim.fn.fnamemodify(path, ":h:h")
		local csproj_files = vim.fn.globpath(project_dir, "*.csproj", false, true)
		return path, csproj_files[1]
	end
	return nil, nil
end

-- Helper: Parse launchSettings.json and return configurations
local get_launch_profile_configs = function()
	local launch_settings_path, csproj = find_launch_settings()
	if not launch_settings_path or not csproj then
		return {}
	end

	local content = vim.fn.readfile(launch_settings_path)
	local json_str = table.concat(content, "\n")
	local ok, settings = pcall(vim.json.decode, json_str)
	if not ok or not settings.profiles then
		return {}
	end

	local configs = {}
	local project_dir = vim.fn.fnamemodify(csproj, ":h")
	local project_name = vim.fn.fnamemodify(csproj, ":t:r")

	for profile_name, profile in pairs(settings.profiles) do
		-- Skip IIS Express and similar non-project profiles
		if profile.commandName == "Project" then
			local env = {}
			if profile.environmentVariables then
				for k, v in pairs(profile.environmentVariables) do
					env[k] = v
				end
			end
			if profile.applicationUrl then
				env["ASPNETCORE_URLS"] = profile.applicationUrl
			end

			local args = {}
			if profile.commandLineArgs then
				for arg in profile.commandLineArgs:gmatch("%S+") do
					table.insert(args, arg)
				end
			end

			table.insert(configs, {
				type = "coreclr",
				name = "[Profile] " .. profile_name,
				request = "launch",
				-- Store build info for async build (used by F.dap_run_with_build)
				_build_info = {
					csproj = csproj,
					project_dir = project_dir,
					project_name = project_name,
				},
				cwd = project_dir,
				env = env,
				args = args,
				stopAtEntry = false,
				console = "integratedTerminal",
			})
		end
	end

	return configs
end

-- Run DAP with async build (non-blocking)
-- Builds the project first, then starts debugging on success
local dap_run_with_build = function(config)

	-- Get build info (static or from function)
	local info = config._build_info
	if not info and config._build_info_fn then
		info = config._build_info_fn()
	end

	-- If config has build info, build first then run
	if info then
		F.build_project_async(info.csproj, function(success, dll_path)
			if success and dll_path then
				-- Create a copy of config with program set
				local run_config = vim.tbl_extend("force", {}, config)
				run_config._build_info = nil
				run_config._build_info_fn = nil
				run_config.program = dll_path
				run_config.cwd = run_config.cwd or info.project_dir
				dap.run(run_config)
			elseif success then
				vim.notify("Build succeeded but could not find DLL", vim.log.levels.ERROR)
			end
			-- On failure, build_project_async already shows errors
		end)
	else
		-- No build info, run directly (for attach configs, etc.)
		dap.run(config)
	end
end

-- Show picker and run with build
F.dap_continue_with_build = function()
	local configs = dap.configurations.cs or {}

	if #configs == 0 then
		vim.notify("No debug configurations found", vim.log.levels.WARN)
		return
	end

	-- If already debugging, just continue
	if dap.session() then
		dap.continue()
		return
	end

	vim.ui.select(configs, {
		prompt = "Select debug configuration:",
		format_item = function(config)
			return config.name
		end,
	}, function(config)
		if config then
			dap_run_with_build(config)
		end
	end)
end

-- Helper: Parse .vscode/launch.json
local get_vscode_configs = function()
	local vscode_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.getcwd(), ".vscode", "launch.json"))
	if not vim.uv.fs_stat(vscode_path) then
		return {}
	end

	local content = vim.fn.readfile(vscode_path)
	local json_str = table.concat(content, "\n")
	-- Remove comments (jsonc support)
	json_str = json_str:gsub("//.-\n", "\n")
	json_str = json_str:gsub("/%*.-%*/", "")

	local ok, launch = pcall(vim.json.decode, json_str)
	if not ok or not launch.configurations then
		return {}
	end

	local configs = {}
	for _, config in ipairs(launch.configurations) do
		if config.type == "coreclr" or config.type == "netcoredbg" then
			-- Prefix name to identify source
			config.name = "[VSCode] " .. config.name
			table.insert(configs, config)
		end
	end

	return configs
end
-- Refresh function to rebuild configurations dynamically
F.refresh_dap_cs_configs = function()
  local configs = {}

  -- Add launch profiles from launchSettings.json
  local profile_configs = get_launch_profile_configs()
  for _, cfg in ipairs(profile_configs) do
    table.insert(configs, cfg)
  end

  -- Add VSCode configurations
  local vscode_configs = get_vscode_configs()
  for _, cfg in ipairs(vscode_configs) do
    table.insert(configs, cfg)
  end

  -- Add static launch configs
  for _, cfg in ipairs(launch_configs) do
    table.insert(configs, cfg)
  end

  -- Add attach configs
  for _, cfg in ipairs(attach_configs) do
    table.insert(configs, cfg)
  end

  dap.configurations.cs = configs
  return configs
end

return {}
