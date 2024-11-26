return
{
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
  },
  config = function()
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      registries = {
        'github:mason-org/mason-registry',
        'github:crashdummyy/mason-registry',
      },
      PATH = "prepend", -- "skip" seems to cause the spawning error
    })

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local servers = require "plugins.lsp.servers"
    local capabilities = require "plugins.lsp.capabilities"
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'jsonls',
      'prettier', -- prettier formatter
      'powershell_es',
      'css-lsp',
      'html-lsp',
      "tailwindcss-language-server",
      "roslyn",
      "rzls"
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }


  end,
}
