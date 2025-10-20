vim.keymap.set("n", "<leader>ac", "<CMD>CodeCompanionChat Toggle<CR>", { desc = "[A]I Code Companion Chat [T]oggle" })
return {
	{
		"olimorris/codecompanion.nvim",
		event = "InsertEnter",
		opts = {
			-- adapters = {
			--   anthropic = function()
			--     return require("codecompanion.adapters").extend("anthropic", {
			--       env = {
			--         api_key = vim.env.ANTHROPIC_API_KEY
			--       },
			--     })
			--   end,
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
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = {
					keymap = {
						jump_prev = "[[",
						jump_next = "]]",
						accept = "<CR>",
						refresh = "gr",
						open = "<C-.>",
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
