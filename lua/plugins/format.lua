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
    -- conform.nvim: modern formatter plugin, replaces none-ls for 0.12 compat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    keys = {
      {
        '<leader>==',
        function()
          require('conform').format { async = false, timeout_ms = 3000 }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        lua             = { 'stylua' },
        javascript      = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript      = { 'prettier' },
        typescriptreact = { 'prettier' },
        json            = { 'prettier' },
        yaml            = { 'prettier' },
        markdown        = { 'prettier' },
        html            = { 'prettier' },
        css             = { 'prettier' },
        cs              = { 'csharpier' },
      },
      formatters = {
        -- Lua: pin cwd to nvim config so .stylua.toml is always found
        stylua = F.get_conform_formatter('stylua', {
          cwd = function() return vim.fn.stdpath 'config' end,
        }),
        -- JS/TS/Web: handles node-based .cmd wrapper on Windows
        prettier = F.get_conform_formatter('prettier'),
        -- C#: skip csharpier when .editorconfig is present (defer to LSP)
        csharpier = F.get_conform_formatter('csharpier', {
          condition = function(self, ctx)
            local root = vim.fs.root(ctx.buf, { '.editorconfig', '.git', '*.sln', '*.csproj' })
            if root and vim.fn.filereadable(root .. '/.editorconfig') == 1 then
              return false
            end
            return true
          end,
        }),
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
