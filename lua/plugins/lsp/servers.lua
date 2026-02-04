local servers = {
	lemminx = {},
	stylua = {},
	ts_ls = {},
	roslyn_ls = {},
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
