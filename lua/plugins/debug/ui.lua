vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "", linehl = "", numhl = "" })

-- dap ui setup for more information, see |:help nvim-dap-ui|
local dap = require("dap")
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
				{ id = "stacks", size = 0.2 }, -- 100% of this panel is scopes
				{ id = "repl", size = 0.1 }, -- 100% of this panel is scopes
			},
			size = 80, -- height in lines (adjust to taste)
			position = "left", -- "left", "right", "top", "bottom"
		},
	},
})

return {}
