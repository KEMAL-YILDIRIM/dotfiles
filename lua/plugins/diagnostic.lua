vim.diagnostic.config({
	virtual_text = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "ErrorMsg",
			[vim.diagnostic.severity.WARN] = "WarningMsg",
		},
	},
})

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
		event = "BufEnter",
		opts = { function() end },
		cmd = "Trouble",
		keys = {},
		init = function(opts)
      --because the default d key conflict with the delete actions we need to define it as a which key registration rather then vim.keymap.set
			local wk = require("which-key")
			wk.add({
				{ "<leader>d", group = "[D]iagnostics" },
				{
					"<leader>dp",
					"<CMD>Trouble diagnostics prev<CR>",
					mode = "n",
					desc = "Previous diagnostic message",
				},
				{
					"<leader>dn",
					"<CMD>Trouble diagnostics next<CR>",
					mode = "n",
					desc = "Toggle workspace diagnostic",
				},
				{
					"<leader>dw",
					"<CMD>Trouble diagnostics toggle<CR>",
					mode = "n",
					desc = "Toggle diagnostic list",
				},
				{
					"<leader>ds",
					"<CMD>Trouble symbols toggle focus=false<CR>",
					mode = "n",
					desc = "Document symbols",
				},
				{
					"<leader>dd",
					"<CMD>Trouble diagnostics toggle filter.buf=0<CR>",
					mode = "n",
					desc = "Toggle document diagnostics",
				},
				{
					"<leader>dq",
					"<CMD>Trouble qflist toggle<CR>",
					mode = "n",
					desc = "Toggle diagnostic quickfix",
				},
				{
					"<leader>dl",
					"<CMD>Trouble loclist toggle<CR>",
					mode = "n",
					desc = "Toggle location list",
				},
				{
					"<leader>dr",
					"<CMD>Trouble lsp toggle focus=false win.position=right<CR>",
					mode = "n",
					desc = "Open References/definitions in trouble",
				},
			})
		end,
	},
}
