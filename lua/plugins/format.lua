vim.keymap.set("n", "<leader>==", vim.lsp.buf.format, { desc = "Format buffer with lsp" })
vim.keymap.set("n", "<leader>=-", "gg=G", { desc = "Format buffer with indentation" })

-- tab settings
vim.o.tabstop = 2
vim.o.softtabstop = 0
vim.o.shiftwidth = 2
vim.o.expandtab = true

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.o.list = true
vim.o.listchars = "tab:» ,trail:·,nbsp:␣,extends:#"

-- Enable break indent
vim.o.breakindent = false
vim.o.linebreak = true
vim.o.autoindent = true
vim.o.wrap = true
-- vim.o.sidescroll=5
-- vim.o.listchars = vim.o.listchars + "precedes:<,extends:>"


vim.o.conceallevel = 0
vim.api.nvim_create_autocmd("BufEnter", {
	desc = "Rectify the conceal level when the md files displayed",
	group = vim.api.nvim_create_augroup('conceal-setting', { clear = true }),
	callback = function()
		if
			vim.bo.filetype == "markdown"
			or package.loaded["nvim-dap"] ~= nil
		then
			vim.o.conceallevel = 1
		end
	end
})

return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    version = '*',
    config = function()
      require('mini.ai').setup()
      require('mini.pairs').setup() 
      require('mini.surround').setup()
    end,
  },
	{
		-- Detect tabstop and shiftwidth automatically
		'tpope/vim-sleuth',
		enabled = true
	},
	{
		-- Converts the linters and formatters into built in lsp
		"nvimtools/none-ls.nvim",
    event = "BufEnter",
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
