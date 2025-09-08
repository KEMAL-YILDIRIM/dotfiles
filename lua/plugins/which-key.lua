return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        ["<C-c>"] = { "<Esc>", "Exit which-key" },
      },
    },
    config = function()
      local wk = require("which-key")
      wk.add({
        { '<leader>s', 'nop', group = 'Search' },
        { '<leader>o', 'nop', group = 'Obsidian' },
        { '<leader>t', 'nop', group = 'Terminal' },
        { '<leader>q', 'nop', group = 'Quickfix' },
        { '<leader>u', 'nop', group = 'Unit Test' },
        { '<leader>d', 'nop', group = 'Diagnostics' },
        { '<leader>c', 'nop', group = 'Comment' },
        { '<leader>=', 'nop', group = 'Format' },
        { '<leader>g', 'nop', group = 'Git' },
        { '<leader>a', 'nop', group = 'AI' },
      })
    end,
  }
}
-- vim: ts=2 sts=2 sw=2 et
