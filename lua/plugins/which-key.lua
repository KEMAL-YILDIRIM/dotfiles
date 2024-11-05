return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
    },
    config = function()
      local wk = require("which-key")
      wk.add({
        { '<leader>s', 'nop', group = '[S]earch' },
        { '<leader>o', 'nop', group = '[O]bsidian' },
        { '<leader>t', 'nop', group = '[T]ab' },
        { '<leader>[', 'nop', group = '[S]urround' },
        { '<leader>q', 'nop', group = '[Q]uickfix' },
        { '<leader>x', 'nop', group = '[X]diagnostics' },
        { '<leader>c', 'nop', group = '[C]omment' },
        { '<leader>=', 'nop', group = '[=]Format' },
        { '<leader>g', 'nop', group = '[G]it' },
      })
    end,
  }
}
-- vim: ts=2 sts=2 sw=2 et
