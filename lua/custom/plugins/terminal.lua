return { 
	{
		--[[
		'aserowy/tmux.nvim', 
		
		config = function()

			local tmux = require('tmux')
			tmux.setup()

			vim.keymap.set('n', "<C-h>", tmux.NvimTmuxNavigateLeft)
			vim.keymap.set('n', "<C-j>", tmux.NvimTmuxNavigateDown)
			vim.keymap.set('n', "<C-k>", tmux.NvimTmuxNavigateUp)
			vim.keymap.set('n', "<C-l>", tmux.NvimTmuxNavigateRight)
			vim.keymap.set('n', "<C-\\>", tmux.NvimTmuxNavigateLastActive)
			vim.keymap.set('n', "<C-Space>", tmux.NvimTmuxNavigateNext)

		end,
		]]
	},
}
