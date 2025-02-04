vim.opt.rtp:append("D:/Razor/nvim.razorls")
vim.opt.rtp:append("D:/Razor/rzls.nvim")
vim.opt.rtp:append("D:/Razor/roslyn.nvim")
vim.api.nvim_create_user_command("Test", function()
	package.loaded.razorls = nil
	require("razorls").test()
end, { desc = "Lsp test" })

return {

	{
		-- "seblj/roslyn.nvim",
		dir = "D:/Nvim/roslyn.nvim",
		name = "roslyn",
		dev = true,
		-- ft = "cs",
		opts = {
			broad_search = false,
			lock_target = true
		},

	},


	{
		-- "tris203/rzls.nvim",
		dir = "D:/Nvim/rzls.nvim",
		dev = true,
		name = "rzls",

		config = function()
			local attach = require 'plugins.lsp.attach'
			local capabilities = require "plugins.lsp.capabilities"
			local nvim_data_path = vim.fs.normalize(vim.fn.stdpath "data" .. "/mason/packages")

			-- Lsp hint display
			-- vim.lsp.inlay_hint.enable()

			require('roslyn').setup {
				args = {
					'--logLevel=Information',
					'--extensionLogDirectory=' .. vim.fs.normalize(vim.fs.dirname(vim.lsp.get_log_path())),
					'--razorSourceGenerator=' ..
					nvim_data_path .. '/roslyn/libexec/Microsoft.CodeAnalysis.Razor.Compiler.dll',
					'--razorDesignTimePath=' ..
					nvim_data_path .. '/rzls/libexec/Targets/Microsoft.NET.Sdk.Razor.DesignTime.targets',
				},
				filewatching = false,
				-- broad_search = true,
				exe = {
					"dotnet",
					nvim_data_path .. "/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll",
				},
				config = {
					handlers = require 'rzls.roslyn_handlers',
				},
			}

			require('rzls').setup {
				on_attach = attach,
				capabilities = capabilities,
				-- path = nvim_data_path .. "/rzls/libexec/rzls.exe",
			}
		end
	},


}
