vim.keymap.set("n", "<leader>e", ":lua MiniFiles.open()<CR>", { desc = "Files" })
return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    version = '*',
    config = function()


      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }
      require('mini.pairs').setup() -- use default config

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup({
        mappings = {
          add = 'sa', -- Add surrounding in Normal and Visual modes
          delete = 'sd', -- Delete surrounding
          find = 'sf', -- Find surrounding (to the right)
          find_left = 'sF', -- Find surrounding (to the left)
          highlight = 'sh', -- Highlight surrounding
          replace = 'sr', -- Replace surrounding
          update_n_lines = 'sn', -- Update `n_lines`

          suffix_last = 'p', -- Suffix to search with "prev" method
          suffix_next = 'n', -- Suffix to search with "next" method
        },
      })

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
          reset       = '<C-r>',
          reveal_cwd  = '<C-p>',
          show_help   = 'g?',
          synchronize = '<C-y>',
          trim_left   = '<C-b>',
          trim_right  = '<C-n>',
        },
      }

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
