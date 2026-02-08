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
    -- none-ls: Community fork of null-ls for formatting and diagnostics
    'nvimtools/none-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = { 'BufReadPre', 'BufNewFile' },
    keys = {
      {
        '<leader>==',
        function()
          vim.lsp.buf.format { async = false, timeout_ms = 3000 }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    config = function()
      local null_ls = require 'null-ls'
      local formatting = null_ls.builtins.formatting

      -- Helper to get Mason executable path on Windows
      local function get_command(name)
        if not F.is_win then
          return name
        end
        local exe = F.get_executable(name)
        if type(exe) == 'table' then
          return exe.command
        end
        return exe
      end

      -- Helper to get extra args for node-based tools
      local function get_extra_args(name)
        if not F.is_win then
          return nil
        end
        local exe = F.get_executable(name)
        if type(exe) == 'table' then
          return exe.args
        end
        return nil
      end

      local sources = {
        -- Lua
        formatting.stylua.with {
          command = get_command 'stylua',
          cwd = function()
            return vim.fn.stdpath 'config'
          end,
        },
        -- JavaScript/TypeScript/Web
        formatting.prettier.with {
          command = get_command 'prettier',
          extra_args = get_extra_args 'prettier',
          filetypes = {
            'javascript',
            'javascriptreact',
            'typescript',
            'typescriptreact',
            'json',
            'yaml',
            'markdown',
            'html',
            'css',
          },
        },
        -- C#
        formatting.csharpier.with {
          command = get_command 'csharpier',
          condition = function(utils)
            -- Only use csharpier if no .editorconfig (otherwise prefer LSP)
            local root = vim.fs.root(0, { '.editorconfig', '.git', '*.sln', '*.csproj' })
            if root and vim.fn.filereadable(root .. '/.editorconfig') == 1 then
              return false
            end
            return true
          end,
        },
      }

      null_ls.setup {
        sources = sources,
        -- Uncomment to format on save
        -- on_attach = function(client, bufnr)
        --   if client.supports_method 'textDocument/formatting' then
        --     vim.api.nvim_create_autocmd('BufWritePre', {
        --       buffer = bufnr,
        --       callback = function()
        --         vim.lsp.buf.format { bufnr = bufnr, timeout_ms = 3000 }
        --       end,
        --     })
        --   end
        -- end,
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
