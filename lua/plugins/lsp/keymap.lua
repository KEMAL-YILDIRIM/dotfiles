local function lsp_attach(event)
	local lsp = vim.lsp
	local map = function(keys, func, desc)
		vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc, noremap = true })
	end

	-- jump to lsp document window
	vim.keymap.set("i", "<C-l>", function()
		vim.cmd.stopinsert()
		vim.lsp.buf.signature_help()
		vim.defer_fn(function()
			vim.cmd.wincmd("w")
		end, 100)
		vim.keymap.set("n", "q", ":close<CR>", { buffer = true })
	end)

	--  To jump back, press <C-T>.
	local builtin = require("telescope.builtin")
	map("<leader>l", "<NOP>", "")
	map("<leader>ld", builtin.lsp_definitions, "Goto Definition")
	map("<leader>lf", builtin.lsp_references, "Goto reFerences")
	map("<leader>li", builtin.lsp_implementations, "Goto Implementation")
	map("<leader>lt", builtin.lsp_type_definitions, "Type Definition")
	map("<leader>ls", builtin.lsp_document_symbols, "Document Symbols")
	map("<leader>lw", builtin.lsp_dynamic_workspace_symbols, "Workspace Symbols")
	map("<leader>lr", lsp.buf.rename, "Rename")
	map("<leader>la", lsp.buf.code_action, "Code Action")
	map("<space>lh", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
	end, "Enable Inlay Hints")
	map("<space>ll", function()
		vim.lsp.codelens.refresh({ bufnr = 0 })
	end, "Refresh Code Lens")

	-- Opens a popup that displays documentation about the word under your cursor
	--  See `:help K` for why this keymap
	map(
		"K", -- In your Neovim config
		function()
			vim.lsp.buf.hover()
			-- Immediately follow with signature help for overloads
			vim.defer_fn(function()
				vim.lsp.buf.signature_help()
			end, 100)
		end,
		"Hover Documentation"
	)

	-- WARN: This is not Goto Definition, this is Goto Declaration.
	--  For example, in C this would take you to the header
	map("<leader>lc", lsp.buf.declaration, "Goto DeClaration")
end
return lsp_attach
