-- NOTE: nvim-lspconfig is NOT used for its server configs here — all servers
-- are configured via the native vim.lsp.config() / vim.lsp.enable() API (0.11+).
-- It is kept solely as a load-order anchor: its `init` hook fires before any
-- BufEnter-triggered server attach, ensuring the LspAttach autocmd (and thus
-- buffer-local keymaps) always exists before roslyn.nvim or mason-lspconfig
-- auto-enables servers. fidget.nvim is bundled here for the same reason.
--
-- Future: could replace with a plain `{ event = "BufEnter", init = ... }` spec
-- to drop the nvim-lspconfig dependency entirely.
return {
  'neovim/nvim-lspconfig',
  event = "BufEnter",
  dependencies = {
    {
      "j-hui/fidget.nvim",
      opts = {}
    },
  },
  init = function()
    local api = vim.api
    local keymap = require 'plugins.lsp.keymap'
    api.nvim_create_autocmd('LspAttach', {
      group = api.nvim_create_augroup('aug-lsp-attach', { clear = true }),
      callback = keymap
    })
  end,
}
