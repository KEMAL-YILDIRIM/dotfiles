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
    -- Register LspAttach early (in init, not config) so the autocmd exists
    -- before roslyn.nvim attaches on the first BufEnter. If registered inside
    -- config() the lazy-load of nvim-lspconfig races with roslyn's attach and
    -- the buffer-local keymaps (K, <leader>ld, etc.) are never created.
    local api = vim.api
    local keymap = require 'plugins.lsp.keymap'
    api.nvim_create_autocmd('LspAttach', {
      group = api.nvim_create_augroup('aug-lsp-attach', { clear = true }),
      callback = keymap
    })
  end,
}
