return {
	'akinsho/toggleterm.nvim',
	
	config = function()
		require('toggleterm').setup({

			start_in_insert = true,
			terminal_mappings = true,
			-- direction = 'float',
			shell = "pwsh.exe -NoLogo -NoProfile",
			auto_scroll = true,
			-- persist_mode = true,
			persist_size = true,
			close_on_exit = true,
		})

		
		vim.keymap.set({'n', 'i', 't'}, '<leader>tt', '<cmd>:1ToggleTerm direction=float<CR>', { desc = '[T]erminal [T]oggle' })
		vim.keymap.set({ 'n', 't' }, '<leader>tv', '<cmd>:3ToggleTerm direction=vertical size=100<CR>', { desc = '[T]erminal [V]ertical toggle' })

		-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
		-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
		-- is not what someone will guess without a bit more experience.
		--
		-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
		-- or just use <C-\><C-n> to exit terminal mode
		vim.keymap.set('t', '<leader>t<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })	

		local Terminal = require('toggleterm.terminal').Terminal
	end
}
