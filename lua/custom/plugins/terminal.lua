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

		local Terminal = require('toggleterm.terminal').Terminal
	end
}
