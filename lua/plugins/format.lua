vim.keymap.set("n", "<leader>==", vim.lsp.buf.format, { desc = "Format buffer with lsp" })
-- vim.keymap.set("n", "<leader>=-", "gg<M-v>G=<CR>:w<CR>", { desc = "Format buffer with indentation" })
vim.keymap.set("n", "<leader>=-", "gg=G", { desc = "Format buffer with indentation" })
return {
  { 'tpope/vim-sleuth', --[[ Detect tabstop and shiftwidth automatically]] },
  {
    "nvimtools/none-ls.nvim", -- Converts the linters and formatters into built in lsp
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.completion.spell,
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.formatting.csharpier,       
        }
      })
    end,
  },
  --[[ { -- Autoformat
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>=0',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer with conform',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        javascript = { { "prettierd", "prettier" } },
      },
    },
  }, ]]
}
-- vim: ts=2 sts=2 sw=2 et
