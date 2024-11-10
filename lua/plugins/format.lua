vim.keymap.set("n", "<leader>==", vim.lsp.buf.format, { desc = "Format buffer with lsp" })
-- vim.keymap.set("n", "<leader>=-", "gg<M-v>G=<CR>:w<CR>", { desc = "Format buffer with indentation" })
vim.keymap.set("n", "<leader>=-", "gg=G", { desc = "Format buffer with indentation" })
return {
  { -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',
  },
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },
  { -- Converts the linters and formatters into built in lsp
    "nvimtools/none-ls.nvim",
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
}
-- vim: ts=2 sts=2 sw=2 et
