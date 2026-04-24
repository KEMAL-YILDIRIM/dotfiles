return {
  "williamboman/mason.nvim",
  event = "VeryLazy",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    require("mason").setup {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      registries = {
        "github:mason-org/mason-registry",
        "github:crashdummyy/mason-registry",
      },
      PATH = "prepend", -- "skip" seems to cause the spawning error
    }

    -- Register per-server vim.lsp.config() overrides (capabilities, settings, etc.)
    -- mason-lspconfig will call vim.lsp.enable() for each installed server automatically.
    local capabilities = require "plugins.lsp.capabilities"
    local servers = require "plugins.lsp.servers"
    for server_name, server_config in pairs(servers) do
      local cfg = vim.tbl_deep_extend("force", {}, server_config)
      cfg.capabilities = vim.tbl_deep_extend("force", {}, cfg.capabilities or {}, capabilities)
      vim.lsp.config(server_name, cfg)
    end

    -- Tools for mason-tool-installer (formatters, linters, non-LSP tools + LSP servers)
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      "stylua", -- formatter (not an LSP)
      "jsonls",
      "prettier",
      "powershell_es",
      "css-lsp",
      "html-lsp",
      "tailwindcss-language-server",
      "typescrip-language-server",
      "lemminx",
      "netcoredbg",
      "roslyn",
    })
    require("mason-tool-installer").setup { ensure_installed = ensure_installed }

    -- automatic_enable = true (default) lets mason-lspconfig call vim.lsp.enable()
    -- for every Mason-installed server automatically.
    require("mason-lspconfig").setup {}
  end,
}
