vim.fn.sign_define('DapBreakpoint',
  {
    text = '●',
    texthl = 'DapBreakpoint',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })

-- dap ui setup for more information, see |:help nvim-dap-ui|
local dap = require("dap")
dap.set_log_level("TRACE")
local dapui = require 'dapui'

-- open the ui as soon as we are debugging
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- https://emojipedia.org/en/stickers/search?q=circle
vim.fn.sign_define('DapBreakpoint',
  {
    text = '⚪',
    texthl = 'DapBreakpointSymbol',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })

vim.fn.sign_define('DapStopped',
  {
    text = '🔴',
    texthl = 'yellow',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })
vim.fn.sign_define('DapBreakpointRejected',
  {
    text = '⭕',
    texthl = 'DapStoppedSymbol',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })

-- more minimal ui
dapui.setup({
  expand_lines = true,
  controls = { enabled = false }, -- no extra play/step buttons
  floating = { border = "rounded" },

  -- Set dapui window
  render = {
    max_type_length = 60,
    max_value_lines = 200,
  },

  -- Only one layout: just the "scopes" (variables) list at the bottom
  layouts = {
    {
      elements = {
        { id = "scopes", size = 1.0 }, -- 100% of this panel is scopes
      },
      size = 15,                       -- height in lines (adjust to taste)
      position = "bottom",             -- "left", "right", "top", "bottom"
    },
  },
})

return {}
