local dap = require 'dap'
local dap_view = require 'dap-view'
vim.keymap.set('n', '<leader><f5>', function()
  dap.terminate { disconnect_args = { terminateDebuggee = false } }
end, { desc = 'debug: terminate' })
vim.keymap.set('n', '<f5>', function()
  local ft = vim.bo.filetype
  if ft == 'lua' then
    require('osv').launch { port = 8086 }
    dap.continue()
  elseif ft == 'cs' then
    -- Use async build for C# to avoid blocking and file locking issues
    F.refresh_dap_cs_configs()
    F.dap_continue_with_build()
  else
    dap.continue()
  end
end, { desc = 'debug: start/continue' })
vim.keymap.set('n', '<f11>', dap.step_into, { desc = 'debug: step into' })
vim.keymap.set('n', '<f10>', dap.step_over, { desc = 'debug: step over' })
vim.keymap.set('n', '<leader><f10>', dap.goto_, { desc = 'debug: set statement to current line' })
vim.keymap.set('n', '<leader><f11>', dap.step_out, { desc = 'debug: step out' })
vim.keymap.set('n', '<f9>', dap.toggle_breakpoint, { desc = 'debug: toggle breakpoint' })
vim.keymap.set('n', '<leader><f9>', function()
  dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, { desc = 'debug: conditional breakpoint' })
vim.keymap.set('n', '<f12>', function()
  dap_view.toggle()
end, { desc = 'debug: toggle session result.' })
vim.keymap.set('n', '<leader><f12>', dap.run_last, { desc = 'debug: see last test.' })
vim.keymap.set('n', '<leader><f8>', function()
  F.pick_dap_cs_configuration()
end, { desc = 'debug: pick C# build configuration (Debug/Release)' })

-- Eval var under cursor. `add_expr` sends <cexpr> to the Watches panel and
-- switches to it -- equivalent of the old dapui.eval hover.
vim.keymap.set({ 'n', 'v' }, '<f6>', function()
  dap_view.add_expr(vim.fn.expand '<cexpr>', true)
end, { desc = 'debug: eval under cursor / selection' })
vim.keymap.set('n', '<leader><f6>', dap.repl.toggle, { desc = 'debug: repl toggle' })
return {}
