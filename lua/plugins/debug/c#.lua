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

-- ---------------------------------------------------------------------------
-- Common debug options applied to every configuration
-- ---------------------------------------------------------------------------
-- justMyCode = false: Matches Visual Studio's behaviour for referenced projects.
--   Despite the name, this does NOT mean "don't break in my code" — it means
--   "don't let netcoredbg silently reject breakpoints in modules it misclassifies
--   as non-user code". Referenced ProjectReference assemblies are often
--   misclassified on attach, causing the 'R' (rejected) breakpoint sign.
--   You still only stop where you place breakpoints; the only side-effect is
--   that F11 step-into will enter framework internals (mitigated by
--   enableStepFiltering keeping property getters / compiler stubs filtered).
--
-- sourceFileMap identity mapping: forces netcoredbg to canonicalise paths when
--   matching the buffer path against PDB source records, resolving Windows
--   case / slash mismatches without remapping anything.
local common_debug_opts = {
  justMyCode = false,
  enableStepFiltering = true,
  symbolOptions = {
    searchMicrosoftSymbolServer = false,
    searchPaths = {}, -- populated dynamically in F.refresh_dap_cs_configs
  },
  sourceFileMap = {
    ['${workspaceFolder}'] = '${workspaceFolder}',
  },
}

-- ---------------------------------------------------------------------------
-- Process enumeration helpers
-- ---------------------------------------------------------------------------

--- Returns a list of { pid, ppid, name, cmdline, exe_path } for all dotnet processes.
--- On Windows uses PowerShell/CIM; on Unix uses `ps`.
local function list_dotnet_processes()
  local procs = {}

  if vim.fn.has('win32') == 1 then
    -- PowerShell: get dotnet.exe processes with command lines and executable path.
    -- ExecutablePath gives us the full path to the dotnet.exe binary, which we
    -- surface in the picker label so the user can distinguish framework versions.
    local ps_cmd = table.concat({
      'Get-CimInstance Win32_Process -Filter "Name=\'dotnet.exe\'" |',
      'Select-Object ProcessId,ParentProcessId,Name,CommandLine,ExecutablePath |',
      'ConvertTo-Json -Compress -Depth 2',
    }, ' ')
    local res = vim.system({ 'powershell', '-NoProfile', '-NonInteractive', '-Command', ps_cmd }):wait()

    if res.code ~= 0 or not res.stdout or res.stdout == '' then
      return procs
    end

    local stdout = vim.trim(res.stdout)
    local ok, decoded = pcall(vim.json.decode, stdout)
    if not ok or not decoded then
      return procs
    end

    -- ConvertTo-Json returns an object (not array) when there is only one result
    local entries = vim.isarray(decoded) and decoded or { decoded }
    for _, e in ipairs(entries) do
      table.insert(procs, {
        pid = e.ProcessId,
        ppid = e.ParentProcessId,
        name = e.Name or 'dotnet.exe',
        cmdline = e.CommandLine or '',
        exe_path = e.ExecutablePath or '',
      })
    end
  else
    -- Unix: ps -eo pid,ppid,comm,args for dotnet processes
    local res = vim.system({ 'ps', '-eo', 'pid,ppid,comm,args' }):wait()
    if res.code ~= 0 or not res.stdout then
      return procs
    end
    for line in res.stdout:gmatch('[^\n]+') do
      -- fields: pid ppid comm rest-of-args
      local pid, ppid, comm, args = line:match('^%s*(%d+)%s+(%d+)%s+(%S+)%s+(.*)')
      if pid and comm and (comm:find('dotnet', 1, true) or (args and args:find('dotnet', 1, true))) then
        table.insert(procs, {
          pid = tonumber(pid),
          ppid = tonumber(ppid),
          name = comm,
          cmdline = args or '',
          exe_path = '',
        })
      end
    end
  end

  return procs
end

--- Noise-filter: returns true for background dotnet SDK infrastructure processes
--- that are never the debuggable app target. Conservative — only excludes known
--- tooling DLLs so legitimate processes (testhost, dotnet-watch child, etc.)
--- remain visible.
local dotnet_noise_dlls = {
  'microsoft.codeanalysis.languageserver.dll', -- Roslyn LSP server
  'msbuild.dll',                               -- Build host
  'vbcscompiler.dll',                          -- VB/C# incremental compiler
}
local function is_dotnet_noise(cmdline)
  local lower = cmdline:lower()
  for _, dll in ipairs(dotnet_noise_dlls) do
    if lower:find(dll, 1, true) then
      return true
    end
  end
  return false
end

--- Given a cmdline string, extracts the first *.dll token as the "DLL name".
--- e.g. '"dotnet" exec "D:\path\to\MyApp.dll" --urls http://..."' -> 'MyApp.dll'
local function dll_name_from_cmdline(cmdline)
  -- Match any token ending in .dll (case-insensitive), with or without quotes
  local token = cmdline:match('["\']?([^"\'%s]+%.dll)["\']?')
  if token then
    -- Return just the filename portion
    return token:match('[^\\/]+$') or token
  end
  return nil
end

--- Given a list of csproj basenames (e.g. {"MyApp", "MyApi"}), finds dotnet
--- child processes that are running one of those DLLs (as spawned by
--- `dotnet watch exec …`). Excludes the watcher host itself.
---
--- Must be called from within a coroutine (nvim-dap runs config functions in
--- a coroutine automatically via its `eval_option` machinery).
---
--- - If exactly one candidate: returns its PID immediately (auto-attach).
--- - Otherwise: shows vim.ui.select with rich labels including PID + cmdline.
--- - Notifies which PID was picked so you can verify it's the right child.
--- - Returns nil on failure/cancel.
local function pick_dotnet_child(basenames)
  local procs = list_dotnet_processes()

  if #procs == 0 then
    vim.notify('[DAP] No dotnet processes found. Is the app running?', vim.log.levels.WARN)
    return require('dap').ABORT
  end

  local candidates = {}
  for _, proc in ipairs(procs) do
    local cmd = proc.cmdline
    local cmd_lower = cmd:lower()

    -- ----------------------------------------------------------------
    -- Skip watcher host processes (not the debuggable app child).
    --
    -- SDK ≤9 watcher host:  dotnet watch -c Debug ...
    -- SDK 10 watcher host:  dotnet "...dotnet-watch.dll" -c Debug ...
    -- ----------------------------------------------------------------
    -- Pattern A: classic   "dotnet.exe" watch ...
    if cmd_lower:match('^"?[^"]*dotnet[^"]*"?%s+watch%s')
      or cmd_lower:match('^"?[^"]*dotnet[^"]*"?%s+watch$')
    then
      goto continue
    end
    -- Pattern B: SDK 10    "dotnet.exe" "...dotnet-watch.dll" ...
    if cmd_lower:find('dotnet%-watch%.dll', 1, true) then
      goto continue
    end

    -- ----------------------------------------------------------------
    -- Candidate detection — two mechanisms:
    --
    -- (A) DLL name in cmdline (SDK ≤9, `dotnet exec MyApp.dll ...`):
    --     match against csproj basenames.
    --
    -- (B) DOTNET_WATCH env var in cmdline (SDK 10, `dotnet run --no-build
    --     -e DOTNET_WATCH=1 ...`): presence of the marker is sufficient
    --     — the watcher host is already excluded above.
    -- ----------------------------------------------------------------
    local matched = false

    -- (B) SDK 10: watcher injects DOTNET_WATCH=1 into the child cmdline
    if cmd:find('DOTNET_WATCH=1', 1, true) then
      matched = true
    end

    -- (A) SDK ≤9: cmdline contains the project DLL name
    if not matched then
      for _, basename in ipairs(basenames) do
        -- plain find so dots in basename are treated literally
        if cmd_lower:find(basename:lower() .. '.dll', 1, true) then
          matched = true
          break
        end
      end
    end

    if matched then
      table.insert(candidates, proc)
    end

    ::continue::
  end

  if #candidates == 0 then
    -- Dump all considered cmdlines so the user can see exactly why nothing matched.
    local lines = { '[DAP] No matching dotnet child process found.' }
    lines[#lines + 1] = 'Looking for any of: ' .. table.concat(basenames, ', ')
    lines[#lines + 1] = string.format('Considered %d dotnet process(es):', #procs)
    for _, proc in ipairs(procs) do
      local short = proc.cmdline
      if #short > 120 then
        short = short:sub(1, 117) .. '...'
      end
      lines[#lines + 1] = string.format('  [%s] %s', proc.pid, short)
    end
    lines[#lines + 1] = "Make sure `dotnet watch -c Debug` is running and the app has started."
    vim.notify(table.concat(lines, '\n'), vim.log.levels.WARN)
    return require('dap').ABORT
  end

  local function notify_and_return(proc)
    local label = dll_name_from_cmdline(proc.cmdline)
      or proc.cmdline:match('%-%-launch%-profile%s+(%S+)')
      or proc.name
    vim.notify(
      string.format('[DAP] Attaching to PID %s (%s)', proc.pid, label),
      vim.log.levels.INFO
    )
    return proc.pid
  end

  if #candidates == 1 then
    return notify_and_return(candidates[1])
  end

  -- Multiple candidates: suspend the coroutine, show picker, resume with result
  local co = coroutine.running()
  assert(co, '[DAP] pick_dotnet_child must be called inside a coroutine')

  vim.ui.select(candidates, {
    prompt = 'Select dotnet child process to attach:',
    format_item = function(proc)
      -- Try to show a short meaningful label.
      -- SDK 10 children: extract --launch-profile value if present.
      local profile = proc.cmdline:match('%-%-launch%-profile%s+(%S+)')
      if profile then
        return string.format('[%s] dotnet run --launch-profile %s', proc.pid, profile)
      end
      -- SDK ≤9 children: show the DLL name from cmdline.
      local dll = dll_name_from_cmdline(proc.cmdline)
      if dll then
        return string.format('[%s] %s', proc.pid, dll)
      end
      -- Fallback: truncated cmdline
      local short_cmd = proc.cmdline
      if #short_cmd > 100 then
        short_cmd = '...' .. short_cmd:sub(-100)
      end
      return string.format('[%s] %s', proc.pid, short_cmd)
    end,
  }, function(proc)
    -- Schedule the resume so it always happens after the coroutine.yield below,
    -- even if vim.ui.select calls back synchronously (same pattern as nvim-dap).
    vim.schedule(function()
      coroutine.resume(co, proc)
    end)
  end)

  local selected = coroutine.yield()
  if selected then
    return notify_and_return(selected)
  end
  return require('dap').ABORT
end

--- Resolves csproj basenames from the active Roslyn solution (if available),
--- falling back to all .csproj files under cwd.
local function get_solution_project_basenames()
  local basenames = {}

  if vim.g.roslyn_nvim_selected_solution then
    local solution_dir = vim.fs.dirname(vim.g.roslyn_nvim_selected_solution)
    local res = vim.system({ 'dotnet', 'sln', vim.g.roslyn_nvim_selected_solution, 'list' }):wait()
    if res.code == 0 and res.stdout then
      for _, line in ipairs(vim.split(res.stdout, '\n')) do
        local fullpath = vim.fs.normalize(vim.fs.joinpath(solution_dir, line))
        if fullpath ~= solution_dir and vim.uv.fs_stat(fullpath) then
          table.insert(basenames, vim.fn.fnamemodify(fullpath, ':t:r'))
        end
      end
    end
  end

  -- Fallback: find .csproj under cwd
  if #basenames == 0 then
    local csprojs = vim.fn.globpath(vim.fn.getcwd(), '**/*.csproj', false, true)
    for _, f in ipairs(csprojs) do
      table.insert(basenames, vim.fn.fnamemodify(f, ':t:r'))
    end
  end

  return basenames
end

-- ---------------------------------------------------------------------------
-- Static attach configurations
-- ---------------------------------------------------------------------------
local attach_configs = {
  {
    type = 'coreclr',
    name = '[Attach] Pick Process',
    request = 'attach',
    processId = require('dap.utils').pick_process,
  },
  -- Filtered variant: lists dotnet processes with enriched labels.
  -- Label format: [PID] DLL_name — exe_path
  -- Excludes known SDK noise (Roslyn LSP, MSBuild, VBCSCompiler) but keeps
  -- everything else visible (dotnet-watch parent, testhost, user apps, etc.).
  -- Uses the coroutine+vim.ui.select pattern (Telescope-compatible).
  {
    type = 'coreclr',
    name = '[Attach] Pick Process (dotnet)',
    request = 'attach',
    processId = function()
      local procs = list_dotnet_processes()
      if #procs == 0 then
        vim.notify('[DAP] No dotnet processes found.', vim.log.levels.WARN)
        return require('dap').ABORT
      end

      -- Apply conservative noise filter
      local candidates = {}
      for _, proc in ipairs(procs) do
        if not is_dotnet_noise(proc.cmdline) then
          table.insert(candidates, proc)
        end
      end

      if #candidates == 0 then
        vim.notify('[DAP] No attachable dotnet processes found (all were tooling noise).', vim.log.levels.WARN)
        return require('dap').ABORT
      end

      -- Build display label: [PID] DLL_name — exe_path
      local function format_proc(proc)
        local dll = dll_name_from_cmdline(proc.cmdline) or proc.name or 'dotnet.exe'
        local exe = proc.exe_path
        if exe and #exe > 0 then
          -- Truncate long paths from the left
          if #exe > 60 then
            exe = '...' .. exe:sub(-57)
          end
          return string.format('[%s] %s \xe2\x80\x94 %s', proc.pid, dll, exe)
        end
        return string.format('[%s] %s', proc.pid, dll)
      end

      if #candidates == 1 then
        local proc = candidates[1]
        vim.notify(string.format('[DAP] Attaching to %s', format_proc(proc)), vim.log.levels.INFO)
        return proc.pid
      end

      -- Multiple: suspend coroutine, show picker, resume with selection
      local co = coroutine.running()
      assert(co, '[DAP] Pick Process (dotnet) must be called inside a coroutine')

      vim.ui.select(candidates, {
        prompt = 'Select dotnet process to attach:',
        format_item = format_proc,
      }, function(proc)
        vim.schedule(function()
          coroutine.resume(co, proc)
        end)
      end)

      local selected = coroutine.yield()
      if selected then
        vim.notify(string.format('[DAP] Attaching to %s', format_proc(selected)), vim.log.levels.INFO)
        return selected.pid
      end
      return require('dap').ABORT
    end,
  },
  -- Dedicated config for `dotnet watch -c Debug` scenarios.
  -- Finds the child dotnet.exe process running the app DLL (not the watcher
  -- host), auto-attaches when unambiguous, or shows a filtered picker.
  -- nvim-dap calls processId() inside a coroutine, so pick_dotnet_child can
  -- yield for vim.ui.select when there are multiple candidates.
  {
    type = 'coreclr',
    name = '[Attach] dotnet watch (child)',
    request = 'attach',
    processId = function()
      local basenames = get_solution_project_basenames()
      if #basenames == 0 then
        vim.notify('[DAP] No .csproj files found to match against.', vim.log.levels.WARN)
        return require('dap').ABORT
      end
      return pick_dotnet_child(basenames)
    end,
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
  -- Smart attach: tries cmdline-aware child picker first (good for dotnet watch
  -- and self-contained exe scenarios), then falls back to dap.utils.pick_process
  -- filtered by project basenames for any other hosting model.
  {
    type = 'coreclr',
    name = '[Attach] Smart (Solution)',
    request = 'attach',
    processId = function()
      if not vim.g.roslyn_nvim_selected_solution then
        vim.notify('[DAP] No solution file found', vim.log.levels.WARN)
        return require('dap').ABORT
      end

      local basenames = get_solution_project_basenames()
      if #basenames == 0 then
        vim.notify('[DAP] No projects found in solution', vim.log.levels.WARN)
        return require('dap').ABORT
      end

      -- Try command-line-aware child picker first
      local pid = pick_dotnet_child(basenames)
      if pid then
        return pid
      end

      -- Fallback: dap.utils.pick_process with a name filter
      -- (catches self-contained exe scenarios where process name == project name)
      return require('dap.utils').pick_process {
        filter = function(proc)
          for _, name in ipairs(basenames) do
            if vim.endswith(proc.name, name) or vim.endswith(proc.name, name .. '.exe') then
              return true
            end
          end
          return false
        end,
      }
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

	local active_cfg = (F.get_dap_cs_configuration and F.get_dap_cs_configuration()) or "Debug"
	vim.ui.select(configs, {
		prompt = "Select debug configuration (Configuration: " .. active_cfg .. "):",
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

  -- Build symbol search paths from all known project bin/Debug AND bin/Release
  -- dirs so netcoredbg can locate PDBs for referenced shared projects even
  -- when they are not in the same folder as the entry DLL. Including both
  -- configurations is cheap (netcoredbg only loads what it needs) and means
  -- switching the active C# configuration doesn't require a DAP refresh.
  local search_paths = {}
  local seen = {}
  local function add_bin_dirs(proj_dir)
    for _, cfg in ipairs({ 'Debug', 'Release' }) do
      local bin_dir = vim.fs.normalize(proj_dir .. '/bin/' .. cfg)
      if not seen[bin_dir] then
        seen[bin_dir] = true
        table.insert(search_paths, bin_dir)
      end
    end
  end
  if vim.g.roslyn_nvim_selected_solution then
    local solution_dir = vim.fs.dirname(vim.g.roslyn_nvim_selected_solution)
    local res = vim.system({ 'dotnet', 'sln', vim.g.roslyn_nvim_selected_solution, 'list' }):wait()
    if res.code == 0 and res.stdout then
      for _, line in ipairs(vim.split(res.stdout, '\n')) do
        local fullpath = vim.fs.normalize(vim.fs.joinpath(solution_dir, line))
        if fullpath ~= solution_dir and vim.uv.fs_stat(fullpath) then
          add_bin_dirs(vim.fn.fnamemodify(fullpath, ':h'))
        end
      end
    end
  end
  -- Fallback: scan all csproj bin dirs under cwd
  if #search_paths == 0 then
    local csprojs = vim.fn.globpath(vim.fn.getcwd(), '**/*.csproj', false, true)
    for _, f in ipairs(csprojs) do
      add_bin_dirs(vim.fn.fnamemodify(f, ':h'))
    end
  end

  -- Merge common_debug_opts into every config (deep extend so nested tables
  -- like symbolOptions/sourceFileMap are merged, not replaced).
  -- Build a concrete opts table with the resolved search paths.
  local opts_with_paths = vim.tbl_deep_extend('force', common_debug_opts, {
    symbolOptions = { searchPaths = search_paths },
  })

  local final_configs = {}
  for _, cfg in ipairs(configs) do
    -- tbl_deep_extend: opts_with_paths wins for symbol/source keys,
    -- but per-config keys (name, type, request, processId, program …) are
    -- preserved because cfg comes last and wins on conflict.
    local merged = vim.tbl_deep_extend('force', opts_with_paths, cfg)
    table.insert(final_configs, merged)
  end

  dap.configurations.cs = final_configs
  return final_configs
end

return {}
