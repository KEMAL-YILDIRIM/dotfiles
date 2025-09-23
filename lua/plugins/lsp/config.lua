return {
  'neovim/nvim-lspconfig',
  event = "BufEnter",
  dependencies = {
    {
      "j-hui/fidget.nvim",
      opts = {}
    },
  },
  config = function()
    local api = vim.api
    local keymap = require 'plugins.lsp.keymap'
    api.nvim_create_autocmd('LspAttach', {
      group = api.nvim_create_augroup('aug-lsp-attach', { clear = true }),
      callback = keymap
    })
    vim.diagnostic.config({ virtual_text = true })
  end,
}
