return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { "j-hui/fidget.nvim", opts = {} },
  },
  config = function()
    local api = vim.api
    local attach = require 'plugins.lsp.attach'
    api.nvim_create_autocmd('LspAttach', {
      group = api.nvim_create_augroup('aug-lsp-attach', { clear = true }),
      callback = attach
    })
  end,
}
