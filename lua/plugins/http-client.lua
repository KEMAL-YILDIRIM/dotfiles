return {
	{
		"oysandvik94/curl.nvim",
		cmd = { "CurlOpen" },
	},
	{
		"mistweaverco/kulala.nvim",
		keys = {
			{ "<leader>rs", desc = "Send [R]equest" },
			{ "<leader>ra", desc = "Send [A]ll [R]equests" },
			{ "<leader>ro", desc = "[O]pen [R]equest scratchpad" },
		},
		ft = { "http", "rest" },
		opts = {
			-- your configuration comes here
			global_keymaps = false,
		},
	},
}
