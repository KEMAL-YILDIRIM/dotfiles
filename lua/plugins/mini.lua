vim.keymap.set("n", "<leader>e", ":lua MiniFiles.open()<CR>", { desc = "Files" })
return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    version = '*',
    config = function()
      require('mini.ai').setup({
        n_lines = 500,
        mappings = {
          -- Main textobject prefixes
          around = 'a',
          inside = 'i',

          -- Next/last textobjects
          around_next = 'an',
          inside_next = 'in',
          around_last = 'ap',
          inside_last = 'ip',

          -- Move cursor to corresponding edge of `a` textobject
          goto_left = 'g[',
          goto_right = 'g]',
        },
      })
      require('mini.pairs').setup() -- use default config
      require('mini.surround').setup()

      -- Edit file system like editing a buffer
      require('mini.files').setup {
        options = {
          permanent_delete = false,
        },
        mappings = {
          close       = '<C-c>',
          go_in       = '<C-l>',
          go_in_plus  = '<C-l>',
          go_out      = '<C-h>',
          go_out_plus = '<C-h>',
          mark_goto   = '<C-g>',
          mark_set    = '<C-m>',
          reset       = '<C-s>',
          reveal_cwd  = '<C-p>',
          show_help   = 'g?',
          synchronize = '<C-y>',
          trim_left   = '<C-b>',
          trim_right  = '<C-n>',
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
