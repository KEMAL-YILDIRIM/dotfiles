local servers = {
	lemminx = {},
	ts_ls = {},
	-- roslyn_ls removed: roslyn.nvim manages its own 'roslyn' client via
	-- vim.lsp.enable('roslyn'). Having roslyn_ls here caused mason-lspconfig
	-- to attempt a duplicate/conflicting enable of the server.
	pyright = {},
	rust_analyzer = {},
	lua_ls = {
		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim" },
				},
			},
		},
	},
}
return servers
