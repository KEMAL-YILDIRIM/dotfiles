-- Highlight todo, notes, etc in comments
return {
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false }
  },
  {
    'numToStr/Comment.nvim',
    opts = {
      opleader = {
        ---Line-comment keymap
        line = '<leader>cl',
        ---Block-comment keymap
        block = '<leader>cb',
      },
    },
  },
}
