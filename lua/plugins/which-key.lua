vim.keymap.set("n", "<leader>s", "nop", { desc = "Save", noremap = true })
vim.keymap.set("n", "<leader>f", "nop", { desc = "Find", noremap = true })
vim.keymap.set("n", "<leader>o", "nop", { desc = "Obsidian", noremap = true })
vim.keymap.set("n", "<leader>t", "nop", { desc = "Terminal", noremap = true })
vim.keymap.set("n", "<leader>q", "nop", { desc = "Quickfix", noremap = true })
vim.keymap.set("n", "<leader>u", "nop", { desc = "Unit Test", noremap = true })
vim.keymap.set("n", "<leader>d", "nop", { desc = "Diagnostics", noremap = true })
vim.keymap.set("n", "<leader>c", "nop", { desc = "Comment", noremap = true })
vim.keymap.set("n", "<leader>=", "nop", { desc = "Format", noremap = true })
vim.keymap.set("n", "<leader>g", "nop", { desc = "Git", noremap = true })
vim.keymap.set("n", "<leader>a", "nop", { desc = "AI", noremap = true })
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
		config = function()
			require("which-key")
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
