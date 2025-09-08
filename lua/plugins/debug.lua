vim.keymap.set('n', '<f9>', function()
  -- Load nvim-dap plugin if not already loaded
  local ok, _ = pcall(require, 'dap')
  if not ok then
    require('lazy').load({ plugins = { 'nvim-dap' } })
  end
end, { desc = "Load dap module" })

local M = {}
table.insert(M, require 'plugins.debug.adapter')
return M
