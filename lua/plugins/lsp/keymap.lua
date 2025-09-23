local function lsp_attach(event)
	local lsp = vim.lsp
	local map = function(keys, func, desc)
		vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
	end

	vim.keymap.set("n", "<leader>l", "<NOP>", { desc = "LSP" })
	--  To jump back, press <C-T>.
	local builtin = require("telescope.builtin")
	map("<leader>ld", builtin.lsp_definitions, "Goto [D]efinition")
	map("<leader>lf", builtin.lsp_references, "Goto re[F]erences")
	map("<leader>li", builtin.lsp_implementations, "Goto [I]mplementation")
	map("<leader>lt", builtin.lsp_type_definitions, "[T]ype Definition")
	map("<leader>ls", builtin.lsp_document_symbols, "Document [S]ymbols")
	map("<leader>lw", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace Symbols")
	map("<leader>lr", lsp.buf.rename, "[R]ename")
	map("<leader>la", lsp.buf.code_action, "Code [A]ction")
	map("<space>lh", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
	end, "Enable Inlay [H]ints")
	map("<space>ll", function()
		vim.lsp.codelens.refresh({ bufnr = 0 })
	end, "Refresh Code [L]ens")

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
	map("<leader>lc", lsp.buf.declaration, "Goto De[C]laration")
end
return lsp_attach
