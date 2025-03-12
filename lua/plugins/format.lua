vim.keymap.set("n", "<leader>==", vim.lsp.buf.format, { desc = "Format buffer with lsp" })
vim.keymap.set("n", "<leader>=-", "gg=G", { desc = "Format buffer with indentation" })

-- tab settings
vim.opt.tabstop = 2
vim.opt.softtabstop = 0
vim.opt.shiftwidth = 1
vim.opt.expandtab = false

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

return {
	{
		-- Detect tabstop and shiftwidth automatically
		'tpope/vim-sleuth',
		enabled = true
	},
	{
		'lukas-reineke/indent-blankline.nvim',
		main = 'ibl',
		enabled = false,
		opts = {},
	},
	{
		-- Converts the linters and formatters into built in lsp
		"nvimtools/none-ls.nvim",
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.completion.spell,
					null_ls.builtins.formatting.prettier,
					null_ls.builtins.formatting.csharpier,
				}
			})
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
