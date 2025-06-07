return {
	{
		'nvim-lua/plenary.nvim',
		ft = 'lua',
		config = function()
			-- planary test
			vim.keymap.set("n", "<leader>up", "<Plug>PlenaryTestFile", { desc = "[P]lenary Test" })
		end
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"Issafalcon/neotest-dotnet",
		},
		lazy = true,
		ft = "cs",
		config = function()
			local ntest = require("neotest")
			ntest.setup({
				adapters = {
					require("neotest-dotnet")({
						dap = {
							-- Extra arguments for nvim-dap configuration
							-- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
							args = { justMyCode = false },
							-- Enter the name of your dap adapter, the default value is netcoredbg
							adapter_name = "netcoredbg"
						},
						-- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
						-- Note: Only custom attributes for non-parameterized tests should be added here. See the support note about parameterized tests
						custom_attributes = {
							xunit = { "MyCustomFactAttribute" },
							nunit = { "MyCustomTestAttribute" },
							mstest = { "MyCustomTestMethodAttribute" }
						},
						-- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
						dotnet_additional_args = {
							"--verbosity detailed"
						},
						-- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
						-- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
						--       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
						discovery_root = "project" -- Default
					})
				}
			})
			vim.keymap.set("n", "<leader>ur", function() ntest.run.run() end, { desc = "[R]un Test" })
			vim.keymap.set("n", "<leader>uf", function() ntest.run.run(vim.fn.expand("%")) end,
				{ desc = "[R]un all tests on the [F]ile" })
			vim.keymap.set("n", "<leader>ud", function() ntest.run.run({ strategy = "dap" }) end,
				{ desc = "[D]ebug Test" })
			vim.keymap.set("n", "<leader>us", function() ntest.run.stop() end, { desc = "[S]top Test" })
		end
	}
}
