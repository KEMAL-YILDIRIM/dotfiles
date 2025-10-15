return {
	{
		"stevearc/oil.nvim",
		-- enabled = false,
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			delete_to_trash = true,
			lsp_file_methods = {
				-- Set to true to autosave buffers that are updated with LSP willRenameFiles
				-- Set to "unmodified" to only save unmodified buffers
				autosave_changes = true,
			},
			keymaps = {
				-- Set to false to disable all of the above keymaps

				-- ["<C-p>"] = "actions.preview",
				["<CR>"] = false,
				-- ["<CR>"] = "actions.select",
				["<C-s>"] = false,
				-- ["<C-s>"] = { "actions.select", opts = { vertical = true } },
				["<C-h>"] = false,
				-- ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
				["-"] = false,
				-- ["-"] = { "actions.parent", mode = "n" },
				["`"] = false,
				-- ["`"] = { "actions.cd", mode = "n" },
				["<C-t>"] = false,
				-- ["<C-t>"] = { "actions.select", opts = { tab = true } },
				["_"] = false,
				-- ["_"] = { "actions.open_cwd", mode = "n" },
				["~"] = false,
				-- ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
				["<C-l>"] = false,
				-- ["<C-l>"] = "actions.refresh",
				["<C-p>"] = false,
				-- ["<C-p>"] = "actions.preview",

				["g?"] = { "actions.show_help", mode = "n" },
				["l"] = "actions.select",
				["gl"] = { "actions.select", opts = { vertical = true } },
				["<S-k>"] = "actions.preview",
				["<C-c>"] = { "actions.close", mode = "n" },
				["g="] = "actions.refresh",
				["h"] = { "actions.parent", mode = "n" },
				["ge"] = { "actions.open_cwd", mode = "n" },
				["gc"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
				["gs"] = { "actions.change_sort", mode = "n" },
				["gx"] = "actions.open_external",
				["gh"] = { "actions.toggle_hidden", mode = "n" },
				["g\\"] = { "actions.toggle_trash", mode = "n" },
				["yp"] = {
					desc = "Copy file path",
					callback = function()
						require("oil.actions").copy_entry_path.callback()
						vim.notify("Path copied to clipboard")
					end,
				},
			},
			use_default_keymaps = true,
		},
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
		init = function()
			-- vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Files" })
			vim.keymap.set("n", "<leader>e", function()
				require("oil").open_float()
			end, { desc = "Files" })
		end,
	},
}
