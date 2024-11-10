return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup({
        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          add = '<leader>[a',            -- Add surrounding in Normal and Visual modes
          delete = '<leader>[d',         -- Delete surrounding
          find = '<leader>[f',           -- Find surrounding (to the right)
          find_left = '<leader>[F',      -- Find surrounding (to the left)
          highlight = '<leader>[h',      -- Highlight surrounding
          replace = '<leader>[r',        -- Replace surrounding
          update_n_lines = '<leader>[u', -- Update `n_lines`

          suffix_last = '<leader>[l',    -- Suffix to search with "prev" method
          suffix_next = '<leader>[n',    -- Suffix to search with "next" method
        },
      })

      --Edit buffer in the way representing file system action
      --create new line like dir/file or dir/nested/.
      --Press =; read confirmation dialog; confirm with y/<CR> or not confirm with n/<Esc>
      require('mini.files').setup {
        mappings = {
          close       = '<ESC>',
          go_in       = 'l',
          go_in_plus  = 'L',
          go_out      = 'h',
          go_out_plus = 'H',
          mark_goto   = "'",
          mark_set    = 'm',
          reset       = '<BS>',
          reveal_cwd  = '@',
          show_help   = 'g?',
          synchronize = '=',
          trim_left   = '<',
          trim_right  = '>',
        },
      }

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim

      vim.keymap.set("n", "<leader>e", ":lua MiniFiles.open()<CR>", { desc = "File [E]xplorer" })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
