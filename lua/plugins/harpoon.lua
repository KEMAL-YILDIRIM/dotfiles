return {
	'ThePrimeagen/harpoon',
	-- event = "VeryLazy",
	keys = {
		{ "<leader>ha", function() require("harpoon.mark").add_file() end },
		{ "<leader>hh", function() require("harpoon.ui").toggle_quick_menu() end },
		{ "<leader>hb", function() require("harpoon.ui").nav_file(1) end },
		{ "<leader>hn", function() require("harpoon.ui").nav_file(2) end },
		{ "<leader>h1", function() require("harpoon.ui").nav_file(3) end },
		{ "<leader>h2", function() require("harpoon.ui").nav_file(4) end },
	},
	opts = {
		global_settings = {
			enter_on_sendcmd = true
		}
	}
}
