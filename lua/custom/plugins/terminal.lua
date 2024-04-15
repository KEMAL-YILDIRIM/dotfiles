return {
	{
		--[[ 
		'aserowy/tmux.nvim', 

		config = function()

			local tmux = require('tmux')
			tmux.setup()

			vim.keymap.set('n', "<leader-th>", tmux.NvimTmuxNavigateLeft)
			vim.keymap.set('n', "<leader-tj>", tmux.NvimTmuxNavigateDown)
			vim.keymap.set('n', "<leader-tk>", tmux.NvimTmuxNavigateUp)
			vim.keymap.set('n', "<leader-tl>", tmux.NvimTmuxNavigateRight)
			vim.keymap.set('n', "<leader-t.>", tmux.NvimTmuxNavigateLastActive)
			vim.keymap.set('n', "<leader-tn>", tmux.NvimTmuxNavigateNext)
			vim.keymap.set("n", "<leader-tt>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

		 end,
		]]
	},
}
