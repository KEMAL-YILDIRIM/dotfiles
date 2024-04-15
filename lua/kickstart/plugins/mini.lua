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
      require('mini.surround').setup()

      --Edit buffer in the way representing file system action
      --create new line like dir/file or dir/nested/.
      --Press =; read confirmation dialog; confirm with y/<CR> or not confirm with n/<Esc>
      require('mini.files').setup { mappings = { close = "<Esc>" } }

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim

      vim.keymap.set("n", "<leader>e", ":lua MiniFiles.open()<CR>", { desc = "File [E]xplorer" })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
