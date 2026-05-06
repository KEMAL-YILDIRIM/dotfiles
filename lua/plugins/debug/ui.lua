vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'ErrorMsg' })
vim.fn.sign_define("DapStopped", { text = "", texthl = "WarningMsg" })

-- Pending / rejected breakpoints use the same glyph as bound ones but in a
-- distinct olive-green colour so you can tell at a glance whether a breakpoint
-- has been verified by the adapter yet.
vim.api.nvim_set_hl(0, 'DapBreakpointPending', { fg = '#556B2F' })
vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DapBreakpointPending' })

-- dap ui setup for more information, see |:help nvim-dap-ui|
local dap = require("dap")
-- TRACE log written to: vim.fn.stdpath('cache') .. '/dap.log'
-- On Windows: %LOCALAPPDATA%\nvim-data\dap.log
-- Inspect it to see netcoredbg module-load events and attach handshake details.
dap.set_log_level("TRACE")
local dapui = require("dapui")

-- open the ui as soon as we are debugging
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

-- Re-send all pending breakpoints whenever a new module (DLL) is loaded.
-- Without this, breakpoints placed in a referenced shared project file before
-- attaching get rejected ('R') at attach time because the shared DLL hasn't
-- been loaded yet. Once the module-load event fires, we re-issue setBreakpoints
-- for every C# buffer that has at least one breakpoint so netcoredbg gets a
-- second chance to bind them against the now-available PDB.
dap.listeners.after.event_module['rebind_breakpoints'] = function(session, body)
  if not body or body.reason ~= 'new' then
    return
  end
  local bps = require('dap.breakpoints').get()
  if not next(bps) then
    return
  end
  -- Filter to only C# buffers so we don't spam other language adapters.
  local cs_bps = {}
  for bufnr, buf_bps in pairs(bps) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == 'cs' then
      cs_bps[bufnr] = buf_bps
    end
  end
  if next(cs_bps) then
    session:set_breakpoints(cs_bps)
  end
end

-- Notify when the session ends so it's obvious when `dotnet watch` has
-- restarted the app and detached the debugger (requiring a re-attach).
dap.listeners.before.event_terminated["dap_notify"] = function(session, body)
	local reason = (body and body.reason) or "unknown"
	vim.notify(
		string.format("[DAP] Session terminated (reason: %s). Re-attach if `dotnet watch` restarted.", reason),
		vim.log.levels.WARN
	)
end
dap.listeners.before.event_exited['dap_notify'] = function(session, body)
  local code = (body and body.exitCode) or '?'
  vim.notify(
    string.format('[DAP] Process exited (code: %s). Re-attach if `dotnet watch` restarted.', code),
    vim.log.levels.WARN
  )
end

-- ---------------------------------------------------------------------------
-- Attach / launch notifications
-- ---------------------------------------------------------------------------
-- Notify as soon as a debug session is established so you know which PID and
-- config name are active. The session object always has .config (the DAP
-- configuration table) and .pid (for attach sessions; nil for launch).

dap.listeners.after.attach['dap_notify'] = function(session, body)
  local pid = (body and body.processId) or session.pid or '?'
  local name = (session.config and session.config.name) or '?'
  vim.notify(
    string.format('[DAP] Attached — config: %s  PID: %s', name, pid),
    vim.log.levels.INFO
  )
end

dap.listeners.after.launch['dap_notify'] = function(session, body)
  local name = (session.config and session.config.name) or '?'
  vim.notify(
    string.format('[DAP] Launched — config: %s', name),
    vim.log.levels.INFO
  )
end

-- ---------------------------------------------------------------------------
-- Breakpoint-bound notification (first bind per session only)
-- ---------------------------------------------------------------------------
-- Fires when the adapter sends a `breakpoint` event with reason `changed` and
-- the breakpoint transitions to verified = true.  We only notify once per
-- session to confirm the wiring works without generating one message per BP.

dap.listeners.after.event_breakpoint['dap_notify'] = (function()
  local _notified = false

  -- Reset the flag each time a new session initialises so the notification
  -- fires again on re-attach (e.g. after dotnet watch restarts).
  dap.listeners.after.event_initialized['dap_notify_bp_reset'] = function()
    _notified = false
  end

  return function(session, body)
    if _notified then
      return
    end
    if not body or body.reason ~= 'changed' then
      return
    end
    local bp = body.breakpoint
    if bp and bp.verified then
      _notified = true
      local loc = ''
      if bp.source and bp.source.name then
        loc = string.format(' (%s:%s)', bp.source.name, bp.line or '?')
      end
      vim.notify(
        string.format('[DAP] Breakpoint bound%s — adapter has resolved at least one breakpoint.', loc),
        vim.log.levels.INFO
      )
    end
  end
end)()

-- ---------------------------------------------------------------------------
-- Stopped notifications (breakpoint / exception / entry)
-- ---------------------------------------------------------------------------
-- Skips `step` and `pause` to avoid noise during normal navigation.

local _stopped_reasons = { breakpoint = true, exception = true, entry = true }

dap.listeners.after.event_stopped['dap_notify'] = function(session, body)
  if not body or not body.reason then
    return
  end
  if not _stopped_reasons[body.reason] then
    return
  end
  local desc = body.description or body.reason
  local text = body.text
  if text and text ~= '' then
    desc = desc .. ': ' .. text
  end
  vim.notify(string.format('[DAP] Stopped — %s', desc), vim.log.levels.WARN)
end

-- ---------------------------------------------------------------------------
-- Warn on failed DAP responses
-- ---------------------------------------------------------------------------
-- nvim-dap dispatches listeners.after.<command>(session, err, response, ...)
-- where `err` is non-nil when the adapter returns success=false.
-- There is no single catch-all key; we hook the commands that can actually
-- fail in practice for a .NET / netcoredbg session.

local function dap_warn_on_err(cmd)
  dap.listeners.after[cmd]['dap_notify'] = function(session, err, response, request)
    if err then
      local msg = (type(err) == 'table' and err.message) or tostring(err)
      vim.notify(
        string.format('[DAP] %s failed — %s', cmd, msg),
        vim.log.levels.WARN
      )
    end
  end
end

-- Commands hooked: the ones netcoredbg can realistically reject.
-- setBreakpoints is intentionally omitted — pending breakpoints return
-- success=true with verified=false, so errors there are genuinely unexpected
-- and will surface via the breakpoint-bound listener absence instead.
dap_warn_on_err('initialize')
dap_warn_on_err('configurationDone')
dap_warn_on_err('attach')
dap_warn_on_err('launch')
dap_warn_on_err('evaluate')
dap_warn_on_err('exceptionInfo')

-- more minimal ui
---@diagnostic disable-next-line: missing-fields
dapui.setup({
	expand_lines = true,
	controls = { enabled = false }, -- no extra play/step buttons
	floating = { border = "rounded" },

	-- Set dapui window
	render = {
		indent = 2,
		max_type_length = 60,
		max_value_lines = 200,
	},

	-- Only one layout: just the "scopes" (variables) list at the bottom
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.7 }, -- 100% of this panel is scopes
				{ id = "watches", size = 0.1 }, -- 100% of this panel is scopes
				{ id = "repl", size = 0.2 }, -- 100% of this panel is scopes
			},
			size = 80, -- height in lines (adjust to taste)
			position = "left", -- "left", "right", "top", "bottom"
		},
	},
})

return {}
