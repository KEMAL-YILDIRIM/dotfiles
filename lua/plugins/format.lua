vim.keymap.set('n', '<leader>=-', 'gg=G', { desc = 'Format buffer with indentation' })

-- tab settings
vim.o.tabstop = 2
vim.o.softtabstop = 0
vim.o.shiftwidth = 2
vim.o.expandtab = true

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.o.list = true
vim.o.listchars = 'tab:» ,trail:·,nbsp:␣,extends:#'

-- Enable break indent
vim.o.breakindent = false
vim.o.linebreak = true
vim.o.autoindent = true
vim.o.wrap = true
-- vim.o.sidescroll=5
-- vim.o.listchars = vim.o.listchars + "precedes:<,extends:>"

vim.o.conceallevel = 0
vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Rectify the conceal level when the md files displayed',
  group = vim.api.nvim_create_augroup('conceal-setting', { clear = true }),
  callback = function()
    if vim.bo.filetype == 'markdown' or package.loaded['nvim-dap'] ~= nil then
      vim.o.conceallevel = 1
    end
  end,
})

return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    version = '*',
    config = function()
      require('mini.ai').setup()
      require('mini.pairs').setup()
      require('mini.surround').setup()
    end,
  },
  {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',
    enabled = true,
  },
  {
    -- Modern formatting plugin (recommended)
    'stevearc/conform.nvim',
    enabled = true,
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>==',
        function()
          require('conform').format { async = false, timeout_ms = 3000 }
        end,
        mode = '',
        desc = 'Format buffer with conform',
      },
    },
    config = function()
      -- Use Windows-compatible path resolution from utils
      local formatters = {}
      if F.is_win then
        formatters = {
          stylua = F.get_conform_formatter('stylua', {
            cwd = function()
              return vim.fn.stdpath 'config'
            end,
          }),
          prettier = F.get_conform_formatter 'prettier',
          csharpier = F.get_conform_formatter 'csharpier',
        }
      end

      require('conform').setup {
        formatters = formatters,
        formatters_by_ft = {
          lua = { 'stylua' },
          javascript = { 'prettier' },
          typescript = { 'prettier' },
          javascriptreact = { 'prettier' },
          typescriptreact = { 'prettier' },
          json = { 'prettier' },
          yaml = { 'prettier' },
          markdown = { 'prettier' },
          html = { 'prettier' },
          css = { 'prettier' },
          -- C#: Use LSP (Roslyn) when .editorconfig exists, otherwise csharpier
          cs = function(bufnr)
            local root = vim.fs.root(bufnr, { '.editorconfig', '.git', '*.sln', '*.csproj' })
            if root and vim.fn.filereadable(root .. '/.editorconfig') == 1 then
              -- Use Roslyn LSP formatting - it respects .editorconfig
              vim.notify('Using Roslyn LSP formatting (editorconfig found at: ' .. root .. ')', vim.log.levels.INFO)
              return { lsp_format = 'prefer' }
            end
            vim.notify('Using CSharpier (no editorconfig found)', vim.log.levels.INFO)
            return { 'csharpier' }
          end,
        },
        default_format_opts = {
          timeout_ms = 3000,
          lsp_format = 'fallback',
        },
        -- Uncomment to format on save
        -- format_on_save = {
        --   timeout_ms = 3000,
        --   lsp_format = 'fallback',
        -- },
      }
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
