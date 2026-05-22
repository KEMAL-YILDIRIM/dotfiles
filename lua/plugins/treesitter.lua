-- Universal treesitter highlighting: resolves Vim filetype → parser language
-- (e.g. 'cs' → 'c_sharp', 'ts' → 'typescript') via Neovim's built-in registry,
-- then starts highlighting only when a compiled parser is actually available.
-- Registered here at the top level so this file is executed by lazy.nvim during
-- its startup spec-collection pass, before any FileType events fire for files
-- opened via `nvim somefile.js` on the CLI.
--
-- Neovim 0.12 enables treesitter highlighting for Markdown natively, so we
-- explicitly skip it here to avoid a double-start.
-- The active[buf] guard is a safety net for any other filetypes that 0.12+
-- may enable by default in the future.
-- Prepend nvim-treesitter's bundled queries dir to rtp at startup (before any
-- FileType events fire). The plugin path is stable under lazy.nvim's data dir.
-- See the long comment on the nvim-treesitter spec below for the full rationale.
local ts_runtime = vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/runtime'
if vim.uv.fs_stat(ts_runtime) then
	vim.opt.runtimepath:prepend(ts_runtime)
end

local ts_native_filetypes = { markdown = true }
vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
	group = vim.api.nvim_create_augroup('ts_highlight', { clear = true }),
	pattern = '*',
	callback = function()
		local ft = vim.bo.filetype
		if ft == '' or vim.bo.buftype ~= '' then
			return
		end
		if ts_native_filetypes[ft] then
			return
		end
		local lang = vim.treesitter.language.get_lang(ft)
		if lang then
			local buf = vim.api.nvim_get_current_buf()
			if not vim.treesitter.highlighter.active[buf] then
				pcall(vim.treesitter.start)
			end
		end
	end,
	desc = 'Auto-enable treesitter highlighting for all supported filetypes',
})

return {
	{
		-- Pulled in as a dependency by codecompanion and neotest.
		-- Pinned to the active 'main' branch (the 'master' branch is archived and
		-- incompatible with Neovim 0.12's updated TSNode query API).
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate", -- ensure parsers are rebuilt on plugin update
		-- nvim-treesitter's main branch ships its bundled queries in <plugin>/runtime/queries,
		-- but that path is NOT on Neovim's runtimepath by default. Without this, queries
		-- like @property, @variable.member, and @function.method.call (defined in the
		-- ecma highlights inherited by JS/TS) are never loaded — only Neovim's minimal
		-- built-in queries are found, leaving property accesses and method calls
		-- unhighlighted. tree-sitter-manager handles parser compilation but does not
		-- copy queries, so the rtp prepend is done at the top of this file instead.
		-- No setup needed: configs module was removed in main; we only need the rtp.

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
          "nu",
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
          "python",
				},
				-- Highlighting is handled by the universal FileType autocmd on the
				-- nvim-treesitter entry above, which correctly resolves filetype →
				-- language mappings. Disable here to avoid redundant/conflicting autocmds.
				highlight = false,
			})

		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
