local M = {}
M.set = function()
  local dap = require "dap"
  local dapui = require "dapui"
  vim.keymap.set('n', '<s-f5>', function()
    dap.terminate()
  end, { desc = 'debug: terminate' })
  vim.keymap.set('n', '<f5>', function()
    if (vim.filetype.match({ buf = 0, filename = '%.lua' })) then
      require 'osv'.launch({ port = 8086 })
    end
    dap.continue()
  end, { desc = 'debug: start/continue' })
  vim.keymap.set('n', '<f11>', dap.step_into, { desc = 'debug: step into' })
  vim.keymap.set('n', '<f10>', dap.step_over, { desc = 'debug: step over' })
  vim.keymap.set('n', '<s-f10>', dap.step_back, { desc = 'debug: step over' })
  vim.keymap.set('n', '<s-f11>', dap.step_out, { desc = 'debug: step out' })
  vim.keymap.set('n', '<f9>', dap.toggle_breakpoint, { desc = 'debug: toggle breakpoint' })
  vim.keymap.set('n', '<s-f9>',
    function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
    { desc = 'debug: conditional breakpoint' })
  vim.keymap.set('n', '<f12>', dapui.toggle, { desc = 'debug: see last session result.' })

  -- Eval var under cursor
  vim.keymap.set("n", "<s-f12>", function()
    require("dapui").eval(nil)
  end)
end
return M
