return {

	{ -- lualine
		'nvim-lualine/lualine.nvim',
		event = 'UIEnter',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			local lualine = require('lualine')
			-- local  options = {theme = 'palenight'}
			-- local  options = {theme = 'ayu_mirage'}
			local defaults = {
				options = {
					theme = 'nightfly',
				},
				sections = {
					lualine_c = { { 'filename', path = 2 } },
				},
			}
			lualine.setup(defaults)
		end,
	},

}
