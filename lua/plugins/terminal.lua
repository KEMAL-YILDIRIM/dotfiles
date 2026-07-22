return {
  { -- Tmux

    'aserowy/tmux.nvim',
    enabled = false,
    config = function()
      local tmux = require 'tmux'
      tmux.setup()

      vim.keymap.set('n', '<leader>th', tmux.NvimTmuxNavigateLeft)
      vim.keymap.set('n', '<leader>tj', tmux.NvimTmuxNavigateDown)
      vim.keymap.set('n', '<leader>tk', tmux.NvimTmuxNavigateUp)
      vim.keymap.set('n', '<leader>tl', tmux.NvimTmuxNavigateRight)
      vim.keymap.set('n', '<leader>tp', tmux.NvimTmuxNavigateLastActive)
      vim.keymap.set('n', '<leader>tn', tmux.NvimTmuxNavigateNext)
      vim.keymap.set('n', '<leader>to', '<cmd>silent !tmux neww tmux-sessionizer<CR>')
    end,
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    ---@type snacks.Config
    opts = {
      bigfile = {},
      terminal = {
        shell = 'nu',
        win = {
          position = 'right',
          width = 0.4,
          bo = {
            filetype = 'snacks_terminal',
          },
          wo = {},
          stack = true, -- when enabled, multiple split windows with the same position will be stacked together (useful for terminals)
          keys = {
            term_normal = {
              '<C-;>',
              function() vim.cmd 'stopinsert' end,
              mode = 't',
              desc = 'Terminal: exit to normal mode',
            },
            --[[ term_normal = {
						"<esc>",
						function(self)
							self.esc_timer = self.esc_timer or vim.uv.new_timer()
							if self.esc_timer:is_active() then
								self.esc_timer:stop()
								vim.cmd("stopinsert")
							else
								self.esc_timer:start(200, 0, function() end)
								return "<esc>"
							end
						end,
						mode = "t",
						expr = true,
						desc = "Double escape to normal mode",
					}, ]]
          },
        },
      },
    },
    init = function()
      vim.keymap.set({ 'n', 't' }, '<C-/>', function()
        Snacks.terminal()
      end, { desc = 'Terminal' })
    end,
  },
}
