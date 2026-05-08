return {
	{
		-- Pulled in as a dependency by codecompanion and neotest.
		-- Pinned to the active 'main' branch (the 'master' branch is archived and
		-- incompatible with Neovim 0.12's updated TSNode query API).
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		-- No setup needed: the `configs` module was removed in the main branch.
		-- Parser management and highlighting are handled by tree-sitter-manager
		-- and the FileType autocmd below.
	},
	{
		"romus204/tree-sitter-manager.nvim",
		config = function()
			-- Set up the full MSVC + Windows SDK environment so that cl.exe and link.exe
			-- (used by tree-sitter CLI to compile parsers) can find standard headers and libs.
			-- This mirrors what vcvars64.bat does for include and lib paths.
			local msvc_root =
				"C:\\Program Files (x86)\\Microsoft Visual Studio\\18\\BuildTools\\VC\\Tools\\MSVC\\14.50.35717"
			local sdk_root = "C:\\Program Files (x86)\\Windows Kits\\10"
			local sdk_ver = "10.0.26100.0"

			if not vim.env.INCLUDE then
				vim.env.INCLUDE = table.concat({
					msvc_root .. "\\include",
					sdk_root .. "\\Include\\" .. sdk_ver .. "\\ucrt",
					sdk_root .. "\\Include\\" .. sdk_ver .. "\\shared",
					sdk_root .. "\\Include\\" .. sdk_ver .. "\\um",
				}, ";")
			end

			if not vim.env.LIB then
				vim.env.LIB = table.concat({
					msvc_root .. "\\lib\\x64",
					sdk_root .. "\\Lib\\" .. sdk_ver .. "\\ucrt\\x64",
					sdk_root .. "\\Lib\\" .. sdk_ver .. "\\um\\x64",
				}, ";")
			end

			require("tree-sitter-manager").setup({
				ensure_installed = {
					"bash",
					"c",
					"rust",
					"c_sharp",
					"html",
					"css",
					"markdown",
					"markdown_inline",
					"lua",
					"vim",
					"latex",
					"vimdoc",
					"sql",
					"json",
					"regex",
					"javascript",
				},
				-- Highlighting is handled by the universal FileType autocmd on the
				-- nvim-treesitter entry above, which correctly resolves filetype →
				-- language mappings. Disable here to avoid redundant/conflicting autocmds.
				highlight = false,
			})

		-- Universal treesitter highlighting: resolves Vim filetype → parser language
		-- (e.g. 'cs' → 'c_sharp', 'ts' → 'typescript') via Neovim's built-in registry,
		-- then starts highlighting only when a compiled parser is actually available.
		-- This replaces tree-sitter-manager's pattern-based approach, which uses raw
		-- language names and therefore silently misses filetypes with different names.
		--
		-- Guard: Neovim 0.12 enables treesitter highlighting for Markdown by default,
		-- so we check whether a highlighter is already active to avoid double-starting.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function()
				local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
				if lang then
					local buf = vim.api.nvim_get_current_buf()
					if not vim.treesitter.highlighter.active[buf] then
						pcall(vim.treesitter.start)
					end
				end
			end,
			desc = "Auto-enable treesitter highlighting for all supported filetypes",
		})
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
