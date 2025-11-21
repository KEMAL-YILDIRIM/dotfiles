return {
	{
		"stevearc/quicker.nvim",
		ft = "qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
		init = function()
			vim.keymap.set("n", "<leader>qf", function()
				require("quicker").toggle()
			end, {
				desc = "Toggle quickfix",
			})
			vim.keymap.set("n", "<leader>ql", function()
				require("quicker").toggle({ loclist = true })
			end, {
				desc = "Toggle loclist",
			})
			require("quicker").setup({
				keys = {
					{
						">",
						function()
							require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
						end,
						desc = "Expand quickfix context",
					},
					{
						"<",
						function()
							require("quicker").collapse()
						end,
						desc = "Collapse quickfix context",
					},
				},
			})
		end,
	},
	{
		"folke/trouble.nvim",
		opts = { function() end },
		cmd = "Trouble",
		keys = {},
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			{
				"folke/todo-comments.nvim",
				config = function()
					-- Debug keymap
					vim.keymap.set(
						"n",
						"<leader>dp",
						vim.diagnostic.goto_prev,
						{ desc = "Go to Previous diagnostic message" }
					)
					vim.keymap.set(
						"n",
						"<leader>dn",
						vim.diagnostic.goto_next,
						{ desc = "Go to Next diagnostic message" }
					)
					vim.keymap.set(
						"n",
						"<leader>dm",
						vim.diagnostic.open_float,
						{ desc = "Show diagnostic error Messages" }
					)

					vim.keymap.set(
						"n",
						"<leader>dx",
						"<cmd>Trouble diagnostics toggle<cr>",
						{ desc = "Open/close trouble list" }
					)
					vim.keymap.set(
						"n",
						"<leader>ds",
						"<cmd>Trouble symbols toggle focus=false<cr>",
						{ desc = "Open trouble Document Symbols" }
					)
					vim.keymap.set(
						"n",
						"<leader>dd",
						"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
						{ desc = "Open trouble Document diagnostics" }
					)
					vim.keymap.set(
						"n",
						"<leader>dq",
						"<cmd>Trouble qflist toggle<cr>",
						{ desc = "Open trouble Quickfix list" }
					)
					vim.keymap.set(
						"n",
						"<leader>dl",
						"<cmd>Trouble loclist toggle<cr>",
						{ desc = "Open trouble Location list" }
					)
					vim.keymap.set("n", "<leader>dt", "<cmd>Trouble todo<CR>", { desc = "Open Todos in trouble" })
					vim.keymap.set(
						"n",
						"<leader>dr",
						"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
						{ desc = "Open References/definitions in trouble" }
					)
				end,
			},
		},
	},
}
