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
	{
		'akinsho/toggleterm.nvim',
		-- event = "VeryLazy",
		cmd = "ToggleTerm",
		keys = {
			{ '<C-\\>', '<cmd>:3ToggleTerm direction=vertical size=60<CR>', mode = { 'n', 't' } },
		},
		version = "*",
		config = function()
			require('toggleterm').setup({

				start_in_insert = true,
				terminal_mappings = true,
				-- direction = 'float',
				-- shell = "pwsh.exe -NoLogo -NoProfile",
				shell = "pwsh.exe -NoLogo",
				auto_scroll = true,
				-- persist_mode = true,
				persist_size = true,
				close_on_exit = true,
			})

			-- vim.keymap.set({ 'n', 't' }, '<c-z>', '<cmd>:3ToggleTerm direction=vertical size=100<CR>',
			-- 	{ desc = "Open terminal in split" })
		end
	}
}
