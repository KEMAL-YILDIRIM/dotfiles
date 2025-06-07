vim.api.nvim_create_autocmd({ "InsertLeave" }, {
	pattern = "*",
	callback = function()
		local clients = vim.lsp.get_clients({ name = "roslyn" })
		if not clients or #clients == 0 then
			return
		end

		local buffers = vim.lsp.get_buffers_by_client_id(clients[1].id)
		for _, buf in ipairs(buffers) do
			vim.lsp.util._refresh("textDocument/diagnostic", { bufnr = buf })
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local bufnr = args.buf

		if client and (client.name == "roslyn" or client.name == "roslyn_ls") then
			vim.api.nvim_create_autocmd("InsertCharPre", {
				desc = "Roslyn: Trigger an auto insert on '/'.",
				buffer = bufnr,
				callback = function()
					local char = vim.v.char

					if char ~= "/" then
						return
					end

					local row, col = unpack(vim.api.nvim_win_get_cursor(0))
					row, col = row - 1, col + 1
					local uri = vim.uri_from_bufnr(bufnr)

					local params = {
						_vs_textDocument = { uri = uri },
						_vs_position = { line = row, character = col },
						_vs_ch = char,
						_vs_options = {
							tabSize = vim.bo[bufnr].tabstop,
							insertSpaces = vim.bo[bufnr].expandtab,
						},
					}

					-- NOTE: We should send textDocument/_vs_onAutoInsert request only after
					-- buffer has changed.
					vim.defer_fn(function()
						client:request(
						---@diagnostic disable-next-line: param-type-mismatch
							M.method_name,
							params,
							function(err, result, _)
								if err or not result then
									return
								end

								vim.snippet.expand(result._vs_textEdit.newText)
							end,
							bufnr
						)
					end, 1)
				end,
			})
		end
	end,
})

vim.opt.rtp:append("D:/Nvim/roslyn.nvim")
local attach = require 'plugins.lsp.attach'
local nvim_data_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath "data", "mason", "packages"))
local roslyn_mason_path = vim.fs.normalize(vim.fs.joinpath(nvim_data_path, "roslyn", "libexec"))
local roslyn_cmd = {
	"dotnet",
	vim.fs.normalize(vim.fs.joinpath(roslyn_mason_path, "Microsoft.CodeAnalysis.LanguageServer.dll")),
	"--stdio",
	"--logLevel=Information",
	"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
}

-- vim.opt.rtp:append("D:/Nvim/rzls.nvim")
-- local rzls_mason_path = vim.fs.normalize(vim.fs.joinpath(nvim_data_path, "rzls", "libexec"))
-- vim.list_extend(roslyn_cmd, {
-- 	'--razorSourceGenerator=' ..
-- 	vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, 'Microsoft.CodeAnalysis.Razor.Compiler.dll')),
-- 	'--razorDesignTimePath=' ..
-- 	vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, 'Targets', 'Microsoft.NET.Sdk.Razor.DesignTime.targets')),
-- 	'--extension=' ..
-- 	vim.fs.normalize(vim.fs.joinpath(rzls_mason_path, 'RazorExtension', 'Microsoft.VisualStudioCode.RazorExtension.dll')),
-- })

return {
	{
		-- "seblyng/roslyn.nvim",
		dir = "D:/Nvim/roslyn.nvim",
		name = "roslyn",
		dev = true,
		ft = { "cs", "razor", "cshtml" },
		-- dependencies = {
		-- 	{
		-- 		-- "tris203/rzls.nvim",
		-- 		dir = "D:/Nvim/rzls.nvim",
		-- 		dev = true,
		-- 		ft = "razor",
		-- 		-- event = "VeryLazy",
		-- 		-- name = "rzls",
		-- 		config = true,
		-- 	},
		-- },
		---@module 'roslyn.config'
		---@type RoslynNvimConfig
		opts = {
			broad_search = true,
			lock_target = true,
			debug_enabled = false,
		},
		config = function()
			vim.lsp.config("roslyn", {
				cmd = roslyn_cmd,
				-- handlers = require("rzls.roslyn_handlers"),
				on_attach = attach,
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
					["csharp|completion"] = {
						dotnet_show_completion_items_from_unimported_namespaces = true,
					},
					["csharp|code_lens"] = {
						dotnet_enable_references_code_lens = true,
					},
				},
			})
			vim.lsp.enable("roslyn")
		end,
		-- init = function()
		-- 	-- We add the Razor file types before the plugin loads.
		-- 	vim.filetype.add({
		-- 		extension = {
		-- 			razor = "razor",
		-- 			cshtml = "razor",
		-- 		},
		-- 	})
		-- end,
	},
	{
		"GustavEikaas/easy-dotnet.nvim",
		enabled = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim", },
		config = function()
			local dotnet = require("easy-dotnet")
			-- Options are not required
			dotnet.setup({
				get_sdk_path = function()
					return "C:/ProgramFiles/dotnet/sdk/8.0.311"
				end,
				test_runner = {
					---@type "split" | "float" | "buf"
					viewmode = "float",
					enable_buffer_test_execution = true, --Experimental, run tests directly from buffer
					noBuild = true,
					noRestore = true,
					mappings = {
						run_test_from_buffer = { lhs = "<leader>ub", desc = "Run tests on [B]uffer" },
						filter_failed_tests = { lhs = "<leader>uf", desc = "[F]ilter failed tests" },
						debug_test = { lhs = "<leader>ud", desc = "[D]ebug test" },
						go_to_file = { lhs = "<leader>ug", desc = "[G]o to file" },
						run_all = { lhs = "<leader>ua", desc = "Run [A]ll tests" },
						run = { lhs = "<leader>ur", desc = "[R]un current test" },
						peek_stacktrace = { lhs = "<leader>up", desc = "[P]eek stacktrace of failed test" },
						expand = { lhs = "ze", desc = "expand" },
						expand_node = { lhs = "zn", desc = "expand node" },
						expand_all = { lhs = "za", desc = "expand all" },
						collapse_all = { lhs = "zc", desc = "collapse all" },
						close = { lhs = "<C-c>", desc = "[C]lose testrunner" },
						refresh_testrunner = { lhs = "<C-r>", desc = "[R]efresh testrunner" }
					},
				},
				---@param action "test" | "restore" | "build" | "run"
				terminal = function(path, action, args)
					local commands = {
						run = function()
							return string.format("dotnet run --project %s %s", path, args)
						end,
						test = function()
							return string.format("dotnet test %s %s", path, args)
						end,
						restore = function()
							return string.format("dotnet restore %s %s", path, args)
						end,
						build = function()
							return string.format("dotnet build %s %s", path, args)
						end,
						watch = function()
							return string.format("dotnet watch --project %s %s", path, args)
						end
					}

					local command = commands[action]() .. "\r"
					vim.cmd("vsplit")
					vim.cmd("term " .. command)
				end,
				auto_bootstrap_namespace = {
					--block_scoped, file_scoped
					type = "file_scoped",
					enabled = true
				},
				picker = "telescope",
			})
		end
	}
}
