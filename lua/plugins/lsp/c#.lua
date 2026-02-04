return {
	{
		"seblyng/roslyn.nvim",
		-- dir = "D:/Nvim/roslyn.nvim",
		-- dev = true,
		opts = { filewatching = "roslyn", broad_search = true, lock_target = false, debug = true },
		init = function()
			vim.lsp.config("roslyn", {
				-- handlers = vim.tbl_extend("error", require("rzls.roslyn_handlers"), {
				handlers = {
					["textDocument/hover"] = function(err, result, ctx, config)
						if result and result.contents and result.contents.value then
							result.contents.value = result.contents.value:gsub("\\([^%w])", "%1")
						end
						vim.lsp.handlers["textDocument/hover"](err, result, ctx, config)
					end,
					-- },
				},
				cmd = F.roslyn_cmd(),
				on_attach = require("plugins.lsp.keymap"),
				settings = {
					["csharp|background_analysis"] = {
						dotnet_compiler_diagnostics_scope = "openFiles",
						dotnet_analyzer_diagnostics_scope = "openFiles",
					},
					["csharp|completion"] = {
						dotnet_provide_regex_completions = true,
						dotnet_show_name_completion_suggestions = true,
					},
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
					["csharp|symbol_search"] = {
						dotnet_search_reference_assemblies = true,
					},
					-- Formatting settings - these should be overridden by .editorconfig if present
					["csharp|formatting"] = {
						-- These are defaults, .editorconfig takes precedence
						dotnet_organize_imports_on_format = true,
					},
				},
			})
			vim.filetype.add({
				extension = {
					razor = "razor",
					cshtml = "razor",
				},
			})
			vim.lsp.enable("roslyn")
		end,
	},
}
