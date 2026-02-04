return {
	{
		"olimorris/codecompanion.nvim",
		event = "InsertEnter",
		opts = {
			-- adapters = {
			-- 	http = {
			-- 		anthropic = function()
			-- 			return require("codecompanion.adapters").extend("anthropic", {
			-- 				env = {
			-- 					api_key = vim.env.ANTHROPIC_API_KEY,
			-- 				},
			-- 			})
			-- 		end,
			-- 	},
			-- },
			strategies = {
				chat = {
					keymaps = {
						close = {
							modes = { n = "<C-x>", i = "<C-x>" },
							opts = {},
						},
					},
				},
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		init = function()
			vim.keymap.set(
				"n",
				"<leader>aa",
				"<CMD>CodeCompanionChat Toggle<CR>",
				{ desc = "AI Code Companion Chat Toggle" }
			)
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		enabled = true,
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = {
					keymap = {
						jump_prev = "[[",
						jump_next = "]]",
						accept = "<CR>",
						refresh = "gr",
						open = "<C-a>",
					},
				},
				suggestion = {
					keymap = {
						accept = "<C-y>",
						accept_word = false,
						accept_line = false,
						next = "<C-n>",
						prev = "<C-p>",
						dismiss = "<C-c>",
					},
				},
			})
		end,
	},
}
