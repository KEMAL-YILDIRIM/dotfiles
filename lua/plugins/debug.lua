-- load the plugins then the keymap will be overriden inside the plugin keymaps section
vim.keymap.set('n', '<f9>', function()
  local ok, _ = pcall(require, 'dap')
  ok, _ = pcall(require, 'neotest')
end, { desc = "Load dap and neotest modules" })

local M = {}
table.insert(M, require 'plugins.debug.adapter')
return M
