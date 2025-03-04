return {

	{
		-- "seblyng/roslyn.nvim",
		dir = "D:/Nvim/roslyn.nvim",
		name = "roslyn",
		dev = true,
		ft = { "cs", "razor" },
		opts = {
		},

	},


	{
		-- "tris203/rzls.nvim",
		dir = "D:/Nvim/rzls.nvim",
		dev = true,
		ft = "razor",
		event = "VeryLazy",
		name = "rzls",

		config = function()
			vim.opt.rtp:append("D:/Nvim/rzls.nvim")
			vim.opt.rtp:append("D:/Nvim/roslyn.nvim")
			local attach = require 'plugins.lsp.attach'
			local capabilities = require "plugins.lsp.capabilities"
			local nvim_data_path = vim.fs.normalize(vim.fn.stdpath "data" .. "/mason/packages")

			require('roslyn').setup {
				args = {
					'--stdio',
					'--logLevel=Information',
					'--extensionLogDirectory=' .. vim.fs.normalize(vim.fs.dirname(vim.lsp.get_log_path())),
					'--razorSourceGenerator=' .. nvim_data_path .. '/roslyn/libexec/Microsoft.CodeAnalysis.Razor.Compiler.dll',
					'--razorDesignTimePath=' .. nvim_data_path .. '/rzls/libexec/Targets/Microsoft.NET.Sdk.Razor.DesignTime.targets',
				},
				filewatching = true,
				broad_search = true,
				lock_target = true,
				debug_enabled = false,
				exe = {
					"dotnet",
					nvim_data_path .. "/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll",
				},

				---@diagnostic disable-next-line: missing-fields			
				config = {
					settings = {
						["csharp|inlay_hints"] = {
							csharp_enable_inlay_hints_for_implicit_object_creation = true,
							csharp_enable_inlay_hints_for_implicit_variable_types = true,
							csharp_enable_inlay_hints_for_lambda_parameter_types = true,
							csharp_enable_inlay_hints_for_types = true,
							dotnet_enable_inlay_hints_for_indexer_parameters = true,
							dotnet_enable_inlay_hints_for_literal_parameters = true,
							dotnet_enable_inlay_hints_for_object_creation_parameters = true,
							dotnet_enable_inlay_hints_for_other_parameters = true,
							dotnet_enable_inlay_hints_for_parameters = true,
							dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
						},
						["csharp|code_lens"] = {
							dotnet_enable_references_code_lens = true,
						},
					},
					handlers = require 'rzls.roslyn_handlers',
				},
			}

			require('rzls').setup {
				on_attach = attach,
				capabilities = capabilities,
			}
		end
	},


}
