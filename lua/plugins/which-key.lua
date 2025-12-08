vim.keymap.set("n", "<leader>s", "<NOP>", { desc = "Save", noremap = true })
vim.keymap.set("n", "<leader>f", "<NOP>", { desc = "Find", noremap = true })
vim.keymap.set("n", "<leader>o", "<NOP>", { desc = "Obsidian", noremap = true })
vim.keymap.set("n", "<leader>t", "<NOP>", { desc = "Test", noremap = true })
vim.keymap.set("n", "<leader>q", "<NOP>", { desc = "Quickfix", noremap = true })
vim.keymap.set("n", "<leader>d", "<NOP>", { desc = "Diagnostics", noremap = false })
vim.keymap.set("n", "<leader>c", "<NOP>", { desc = "Comment", noremap = true })
vim.keymap.set("n", "<leader>=", "<NOP>", { desc = "Format", noremap = true })
vim.keymap.set("n", "<leader>g", "<NOP>", { desc = "Git", noremap = true })
vim.keymap.set("n", "<leader>a", "<NOP>", { desc = "AI", noremap = true })
return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			plugins = {
				presets = {
					text_objects = false, -- help for text objects triggered after entering an operator
					windows = false, -- default bindings on <c-w>
					nav = false, -- misc bindings to work with windows
					z = false, -- bindings for folds, spelling and others prefixed with z
					g = false, -- bindings for prefixed with g
				},
			},
		},
		config = function(opts)
			require("which-key").setup(opts);
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
