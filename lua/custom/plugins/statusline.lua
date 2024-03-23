return {
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		config = function()


			local	lualine = require('lualine')
			local  options = {theme = 'palenight'}
			lualine.setup{ options, }
		end,
	},
}
