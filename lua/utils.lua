F = {}

-- ============================================================================
-- Windows Compatibility Layer
-- ============================================================================
-- Handles paths with spaces on Windows (e.g., C:\Users\Kemal Yildirim\...)

--- Windows detection flag
F.is_win = vim.fn.has('win32') == 1

--- Quote a path if it contains spaces (Windows only)
---@param path string
---@return string
F.quote_path = function(path)
  if not F.is_win or not path:find(' ') then
    return path
  end
  -- Already quoted
  if path:match('^".*"$') then
    return path
  end
  return '"' .. path .. '"'
end

--- Get the actual executable path, bypassing .cmd wrappers on Windows
--- For Mason packages, finds .exe directly or uses node for JS tools
---@param name string Tool name (e.g., 'stylua', 'prettier')
---@param opts? { mason?: boolean } Options
---@return string|table executable path or {command, args} for node tools
F.get_executable = function(name, opts)
  opts = opts or { mason = true }

  if not F.is_win then
    return name
  end

  if opts.mason ~= false then
    local mason_path = vim.fn.stdpath('data') .. '/mason/packages/' .. name

    -- Check for direct .exe (native tools: stylua, csharpier, etc.)
    local exe_path = mason_path .. '/' .. name .. '.exe'
    if vim.fn.filereadable(exe_path) == 1 then
      return exe_path
    end

    -- Check for node-based tools (prettier, eslint, etc.)
    local node_module = mason_path .. '/node_modules/' .. name
    if vim.fn.isdirectory(node_module) == 1 then
      -- Find the actual entry point
      local bin_cjs = node_module .. '/bin/' .. name .. '.cjs'
      local bin_js = node_module .. '/bin/' .. name .. '.js'
      local bin_mjs = node_module .. '/bin/' .. name .. '.mjs'
      local bin_plain = node_module .. '/bin/' .. name

      local entry_point = nil
      for _, p in ipairs({ bin_cjs, bin_js, bin_mjs, bin_plain }) do
        if vim.fn.filereadable(p) == 1 then
          entry_point = p
          break
        end
      end

      if entry_point then
        return {
          command = 'node',
          args = { entry_point },
        }
      end
    end
  end

  -- Fallback: try to find via exepath and quote if needed
  local resolved = vim.fn.exepath(name)
  if resolved ~= '' then
    return F.quote_path(resolved)
  end

  return name
end

--- Get conform formatter config for a Mason-installed tool
--- Handles Windows path issues automatically
---@param name string Formatter name (e.g., 'stylua', 'prettier')
---@param extra_opts? table Additional formatter options
---@return table Conform formatter config
F.get_conform_formatter = function(name, extra_opts)
  extra_opts = extra_opts or {}

  if not F.is_win then
    return extra_opts
  end

  local exe = F.get_executable(name)

  if type(exe) == 'table' then
    -- Node-based tool
    return vim.tbl_extend('force', {
      command = exe.command,
      prepend_args = exe.args,
    }, extra_opts)
  else
    -- Native executable
    return vim.tbl_extend('force', {
      command = exe,
    }, extra_opts)
  end
end

--- Safe wrapper for vim.fn.system that handles Windows paths with spaces
---@param cmd string|table Command to run
---@param ... any Additional arguments passed to vim.fn.system
---@return string Output from command
F.safe_system = function(cmd, ...)
  if F.is_win and type(cmd) == 'string' then
    -- For string commands on Windows, ensure proper shell handling
    -- Don't double-wrap if already wrapped
    if not cmd:match('^cmd%.exe') then
      cmd = 'cmd.exe /c ' .. cmd
    end
  elseif F.is_win and type(cmd) == 'table' and cmd[1] then
    -- For table commands, quote paths with spaces
    cmd[1] = F.quote_path(cmd[1])
  end
  return vim.fn.system(cmd, ...)
end

--- Safe wrapper for vim.fn.systemlist that handles Windows paths with spaces
---@param cmd string|table Command to run
---@param ... any Additional arguments passed to vim.fn.systemlist
---@return table Output lines from command
F.safe_systemlist = function(cmd, ...)
  if F.is_win and type(cmd) == 'string' then
    if not cmd:match('^cmd%.exe') then
      cmd = 'cmd.exe /c ' .. cmd
    end
  elseif F.is_win and type(cmd) == 'table' and cmd[1] then
    cmd[1] = F.quote_path(cmd[1])
  end
  return vim.fn.systemlist(cmd, ...)
end

--- Safe wrapper for vim.system (async) that handles Windows paths with spaces
---@param cmd table Command as table
---@param opts? table Options for vim.system
---@param on_exit? function Callback on exit
---@return vim.SystemObj
F.safe_system_async = function(cmd, opts, on_exit)
  if F.is_win and type(cmd) == 'table' and cmd[1] then
    cmd[1] = F.quote_path(cmd[1])
  end
  return vim.system(cmd, opts, on_exit)
end

--- Safe wrapper for vim.fn.jobstart that handles Windows paths with spaces
---@param cmd string|table Command to run
---@param opts? table Options for jobstart
---@return number Job ID
F.safe_jobstart = function(cmd, opts)
  if F.is_win and type(cmd) == 'table' and cmd[1] then
    cmd[1] = F.quote_path(cmd[1])
  end
  return vim.fn.jobstart(cmd, opts)
end

-- ============================================================================
-- General Utilities
-- ============================================================================

F.log = function(v)
  vim.api.nvim_echo({ { vim.inspect(v), 'WarningMsg' } }, true, {})
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

--- Runs the command and returns output with an ok
---@param cmd string Command to run
---@param path? string Optional working directory
---@return nil|table Output lines or nil on failure
F.cmd = function(cmd, path)
  local current = vim.fn.getcwd()
  local result = {}

  local info = 'Command failed: ' .. cmd
  if path then
    vim.fn.chdir(path)
    info = info .. ' |> path: ' .. path
  end

  -- Use safe_system which handles Windows paths automatically
  local output = F.safe_system(cmd)

  -- Handle command execution failures
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { info, 'ErrorMsg' } }, true, {})
    if path then
      vim.fn.chdir(current)
    end
    return nil
  end

  -- Split the output by newlines
  if output and output ~= '' then
    for line in output:gmatch('[^\r\n]+') do
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

F.triggerESC = function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
end

---Get the shada directory path (normalized)
---@return string
F.get_shada_dir = function()
	return vim.fs.normalize(vim.fn.stdpath('state') .. '/shada')
end

---Get all .tmp files in the shada directory
---@return string[] Full paths to tmp files
F.get_shada_tmp_files = function()
	local dir = F.get_shada_dir()
	local pattern = dir .. '/main.shada.tmp.*'
	local files = vim.fn.glob(pattern, false, true)
	return files
end

---Get the suffix letters from existing shada tmp files
---@return string[] Single-character suffixes
F.get_shada_tmp_suffixes = function()
	local files = F.get_shada_tmp_files()
	local suffixes = {}
	for _, file in ipairs(files) do
		local suffix = file:match('%.tmp%.(%a)$')
		if suffix then
			table.insert(suffixes, suffix)
		end
	end
	table.sort(suffixes)
	return suffixes
end

---Clear shada files
---@param opts? { permanent: boolean, target: string|nil }
--- permanent (bang): delete main.shada + all tmp files
--- target = "tmp": delete all tmp files only
--- target = single letter: delete specific main.shada.tmp.<letter>
F.clear_shada = function(opts)
	opts = opts or {}
	local dir = F.get_shada_dir()

	-- No target, no bang: clear oldfiles in memory + wshada
	if not opts.permanent and not opts.target then
		vim.v.oldfiles = {}
		vim.cmd('wshada!')
		vim.notify('Recent files cache cleared', vim.log.levels.INFO)
		return true
	end

	-- Target: delete specific tmp file(s)
	if opts.target then
		if opts.target == 'tmp' then
			-- Delete all tmp files
			local files = F.get_shada_tmp_files()
			if #files == 0 then
				vim.notify('No shada tmp files found', vim.log.levels.WARN)
				return true
			end
			local deleted, failed = 0, 0
			for _, file in ipairs(files) do
				local ok, err = os.remove(file)
				if ok then
					deleted = deleted + 1
				else
					vim.notify('Failed to delete: ' .. file .. ' (' .. (err or 'unknown') .. ')', vim.log.levels.ERROR)
					failed = failed + 1
				end
			end
			local msg = 'Deleted ' .. deleted .. ' shada tmp file(s)'
			if failed > 0 then
				msg = msg .. ' (' .. failed .. ' failed)'
			end
			vim.notify(msg, vim.log.levels.INFO)
			return failed == 0
		end

		-- Single letter: delete specific tmp file
		local file = dir .. '/main.shada.tmp.' .. opts.target
		if vim.fn.filereadable(file) == 0 then
			vim.notify('File not found: main.shada.tmp.' .. opts.target, vim.log.levels.WARN)
			return false
		end
		local ok, err = os.remove(file)
		if ok then
			vim.notify('Deleted main.shada.tmp.' .. opts.target, vim.log.levels.INFO)
		else
			vim.notify('Failed to delete main.shada.tmp.' .. opts.target .. ': ' .. (err or 'unknown'), vim.log.levels.ERROR)
			return false
		end
		return true
	end

	-- Bang (permanent): delete main.shada + all tmp files
	if opts.permanent then
		vim.v.oldfiles = {}
		local main_shada = dir .. '/main.shada'
		local deleted, failed = 0, 0

		if vim.fn.filereadable(main_shada) == 1 then
			local ok, err = os.remove(main_shada)
			if ok then
				deleted = deleted + 1
			else
				vim.notify('Failed to delete main.shada: ' .. (err or 'unknown'), vim.log.levels.ERROR)
				failed = failed + 1
			end
		end

		for _, file in ipairs(F.get_shada_tmp_files()) do
			local ok, err = os.remove(file)
			if ok then
				deleted = deleted + 1
			else
				vim.notify('Failed to delete: ' .. file .. ' (' .. (err or 'unknown') .. ')', vim.log.levels.ERROR)
				failed = failed + 1
			end
		end

		local msg = 'Shada cleared permanently (' .. deleted .. ' file(s) deleted)'
		if failed > 0 then
			msg = msg .. ' (' .. failed .. ' failed)'
		end
		vim.notify(msg, vim.log.levels.INFO)
		return failed == 0
	end

	return true
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
