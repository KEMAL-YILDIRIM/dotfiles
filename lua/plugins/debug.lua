return {
	{
		'mfussenegger/nvim-dap',
		lazy = true,
		dependencies = {
			-- creates a beautiful debugger ui
			'rcarriga/nvim-dap-ui',

			-- display text as you step throughout the code
			'theHamsta/nvim-dap-virtual-text',

			-- you can install the debug adapters with 'williamboman/mason.nvim',
			-- to auto include some debug predefined configs 'jay-babu/mason-nvim-dap.nvim',

			-- lua debug
			'jbyuki/one-small-step-for-vimkind',

			-- async io operations
			'nvim-neotest/nvim-nio',
		},
		config = function()
			local dap, daputils = require("dap"), require("dap.utils")


			-- https://github.com/mfussenegger/nvim-dap/wiki/Cookbook#making-debugging-net-easier
			local build_project = function(csproj_path)
				local cmd = "dotnet build -c Debug " .. csproj_path
				local result = "Build: ❌"

				local output = F.cmd(cmd)
				if output ~= nil then
					result = "Build: ✔️ "
				end

				vim.api.nvim_echo({
					{ "\n" .. result,        "WarningMsg" },
					{ "\nexecuted: " .. cmd, "MoreMsg" },
				}, true, {})
			end

			local excluded_dirs = {
				node_modules = "node_modules",
				git = ".git",
				dist = "dist",
				wwwroot = "wwwroot",
				properties = "properties",
				build = "build",
				bin = "bin",
				debug = "debug",
				obj = "obj",
			}

			local is_excluded = function(name)
				for _, pattern in pairs(excluded_dirs) do
					if string.match(name:lower(), pattern) then
						return true
					end
				end
				return false
			end

			local function find_proj_file()
				local proj_path = vim.fs.root(0, function(name, path)
					return name:match('%.csproj$') ~= nil and not is_excluded(path)
				end)

				vim.api.nvim_echo({ { "Project file found: " .. proj_path, "WarningMsg" } }, true, {})
				return proj_path
			end

			require("mason").setup()
			local mason_registry = require('mason-registry')
			local package = mason_registry.get_package("netcoredbg")

			if not package:is_installed() then
				package:install()
			end


			-- C# / .NET
			dap.adapters.coreclr = {
				type = "executable",
				-- command = '/usr/local/netcoredbg',
				-- command = "netcoredbg",
				command = vim.fs.normalize(package:get_install_path() .. "/netcoredbg/netcoredbg.exe"),
				args = { "--interpreter=vscode" },
			}

			dap.configurations.cs = {
				{
					type = "coreclr",
					name = "launch .NET",
					request = "launch",
					program = function()
						local project_path = find_proj_file()
						if not project_path then
							return vim.notify("Couldn't find the csproj path")
						end

						build_project(project_path)
						local filter = string.format("Debug/.*/%s", vim.fn.fnamemodify(project_path, ":t"))
						local bin_path = string.format("%s/bin", project_path)
						local selected = require("dap.utils").pick_file({
							filter      = filter,
							executables = false,
							path        = bin_path,
						})

						local info = {
							{ "\nfilter: " .. filter, "MoreMsg" },
							{ "\npath: " .. bin_path, "MoreMsg" }
						}
						if selected ~= nil then
							table.insert(info, 1, { "\nselected: " .. selected, "WarningMsg" })
							vim.fn.chdir(vim.fn.fnamemodify(selected, ":h")) -- important for setting debug path
						end
						vim.api.nvim_echo(info, true, {})

						return selected
					end,
				},
				{
					type = "coreclr",
					name = "attach .NET",
					request = "attach",
					processId = daputils.pick_process,
				},
				{
					type = "coreclr",
					name = "attach to Azure Function",
					request = "attach",
					processId = function()
						local pid = nil
						while not pid do
							pid = require("azure-functions").get_process_id()
						end
						return pid
					end,
				},
				{
					type = "coreclr",
					name = "Attach (Smart)",
					request = "attach",
					processId = function()
						if not vim.g.roslyn_nvim_selected_solution then
							return vim.notify("No solution file found")
						end

						local solution_dir = vim.fs.dirname(vim.g.roslyn_nvim_selected_solution)

						local res = vim.system({ "dotnet", "sln", vim.g.roslyn_nvim_selected_solution, "list" }):wait()
						local csproj_files = vim.iter(vim.split(res.stdout, "\n"))
										:map(function(it)
											local fullpath = vim.fs.normalize(vim.fs.joinpath(solution_dir, it))
											if fullpath ~= solution_dir and vim.uv.fs_stat(fullpath) then
												return fullpath
											else
												return nil
											end
										end)
										:totable()

						return dap_utils.pick_process({
							filter = function(proc)
								return vim.iter(csproj_files):find(function(file)
									if vim.endswith(proc.name, vim.fn.fnamemodify(file, ":t:r")) then
										return true
									end
								end)
							end,
						})
					end,
				},
			}


			dap.configurations.lua = {
				{
					type = 'nlua',
					request = 'attach',
					name = "Attach to running Neovim instance",
				}
			}

			dap.adapters.nlua = function(callback, config)
				callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
			end



			vim.fn.sign_define('DapBreakpoint',
				{ text = '●', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })

			require('nvim-dap-virtual-text').setup()
			-- dap ui setup for more information, see |:help nvim-dap-ui|
			local dapui = require 'dapui'
			dapui.setup()
			dap.set_log_level("DEBUG")

			vim.keymap.set('n', '<s-f5>', function()
				dap.terminate()
			end, { desc = 'debug: terminate' })
			vim.keymap.set('n', '<f5>', function()
				if (vim.filetype.match({ buf = 0, filename = '%.lua' })) then
					require 'osv'.launch({ port = 8086 })
				end
				dap.continue()
			end, { desc = 'debug: start/continue' })
			vim.keymap.set('n', '<f11>', dap.step_into, { desc = 'debug: step into' })
			vim.keymap.set('n', '<f10>', dap.step_over, { desc = 'debug: step over' })
			vim.keymap.set('n', '<s-f10>', dap.step_back, { desc = 'debug: step over' })
			vim.keymap.set('n', '<s-f11>', dap.step_out, { desc = 'debug: step out' })
			vim.keymap.set('n', '<f9>', dap.toggle_breakpoint, { desc = 'debug: toggle breakpoint' })
			vim.keymap.set('n', '<s-f9>', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
				{ desc = 'debug: conditional breakpoint' })
			vim.keymap.set('n', '<f12>', dapui.toggle, { desc = 'debug: see last session result.' })

			-- Eval var under cursor
			vim.keymap.set("n", "<s-f12>", function()
				require("dapui").eval(nil, { enter = true })
			end)



			dap.listeners.after.event_initialized['dapui_config'] = dapui.open
			dap.listeners.before.event_terminated['dapui_config'] = dapui.close
			dap.listeners.before.event_exited['dapui_config'] = dapui.close
		end,
	},
}
