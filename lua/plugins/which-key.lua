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
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]ab' },
        { '<leader>[', group = '[S]urround' },
        { '<leader>q', group = '[Q]uickfix' },
        { '<leader>x', group = 'Diagnosti[X]' },
        { '<leader>c', group = '[C]omment' },
        { '<leader>=', group = '[=]Format' },
        { '<leader>g', group = '[G]it' },
      })
    end,
  }
}
-- vim: ts=2 sts=2 sw=2 et
