local _ft = { "dbout", "dbui", "*sql" }
return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod" , ft = _ft, event = "BufEnter", },
		{ "kristijanhusak/vim-dadbod-completion", ft = _ft, event = "BufEnter", },
	},
  lazy = true,
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_ui_disable_mappings = 1
		vim.g.db_ui_execute_on_save = 0
		-- Your DBUI configuration

		vim.g.db_ui_winwidth = 40
		vim.g.db_ui_use_nvim_notify = 1
		vim.g.db_ui_icons = {
			expanded = "",
			collapsed = "",
			saved_query = "",
			new_query = "󰎔",
			tables = "󰓫",
			buffers = "",
			connection_ok = "✓",
			connection_error = "✕",
		}

		local original_max_var_type_width = vim.env.SQLCMDMAXVARTYPEWIDTH
		local original_max_fixed_type_width = vim.env.SQLCMDMAXFIXEDTYPEWIDTH

		-- Toggle between original and custom width for column
		vim.keymap.set("n", "<leader>ww", function()
			local width = vim.g.db_ui_winwidth
			if vim.env.SQLCMDMAXFIXEDTYPEWIDTH == original_max_fixed_type_width then
				vim.env.SQLCMDMAXFIXEDTYPEWIDTH = width
				vim.env.SQLCMDMAXVARTYPEWIDTH = width
				vim.notify("Variable width set to: " .. width)
			else
				vim.env.SQLCMDMAXFIXEDTYPEWIDTH = original_max_fixed_type_width
				vim.env.SQLCMDMAXVARTYPEWIDTH = original_max_var_type_width
				vim.notify("Variable width set back to original")
			end
		end, { desc = "Toggle variable width" })

		local group = vim.api.nvim_create_augroup("DadbodMappings", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*sql",
			group = group,
			callback = function()
				vim.keymap.set("n", "<leader>dbs", "<Plug>(DBUI_SaveQuery)", { buffer = true })
				vim.keymap.set("n", "<leader>dbe", "<Plug>(DBUI_ExecuteQuery)", { buffer = true })
				vim.keymap.set("n", "<leader>db.", "<Plug>(DBUI_ToggleResultLayout)", { buffer = true })
				vim.keymap.set("n", "<leader>dbq", "<Plug>(DBUI_Quit)", { buffer = true })
				vim.keymap.set("n", "<leader>dbr", "<Plug>(DBUI_Redraw)", { buffer = true })
			end,
			desc = "Set keymaps for dbui",
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dbout",
			group = group,
			callback = function()
				vim.keymap.set("n", "yh", "<Plug>(DBUI_YankHeader)", { buffer = true })
				vim.keymap.set("n", "yc", "<Plug>(DBUI_YankCellValue)", { buffer = true })
			end,
			desc = "Set keymaps for dbui",
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dbui",
			group = group,
			callback = function()
				vim.keymap.set("n", "l", "<Plug>(DBUI_SelectLine)", { buffer = true })
				vim.keymap.set("n", "L", "<Plug>(DBUI_SelectLineVsplit)", { buffer = true })
				vim.keymap.set("n", "d", "<Plug>(DBUI_DeleteLine)", { buffer = true })
				vim.keymap.set("n", "fk", "<Plug>(DBUI_JumpToForeignKey)", { buffer = true })
				vim.keymap.set("n", "a", "<Plug>(DBUI_AddConnection)", { buffer = true })
				vim.keymap.set("n", "r", "<Plug>(DBUI_RenameLine)", { buffer = true })
			end,
			desc = "Set keymaps for dbui",
		})

		--[[
		-- HACK: Override `sqlcmd` just when about to execute a query and restore it after execution
		-- I want to have `-k` argument for sqlcmd: `/path/to/sqlcmd $@ -k 1`
		local path = vim.env.PATH
		vim.api.nvim_create_autocmd({ "User" }, {
			group = group,
			pattern = "DBExecutePre",
			callback = function()
				path = vim.env.PATH -- Update the path directly before executing
				vim.env.PATH = vim.fn.expand("~/.local/bin") .. ":" .. vim.env.PATH
			end,
		})

		vim.api.nvim_create_autocmd({ "User" }, {
			group = group,
			pattern = "DBExecutePost",
			callback = function()
				vim.env.PATH = path
			end,
		})
		]]
	end,
}
