local func = require("vim.func")
--[[ local state = {
	terminal = {
		buf = -1,
		win = -1,
		job_id = -1
	}
}


local function create_terminal(opts)
	opts = opts or {}
	local buf = nil
	if vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
	end

	local win_config = {
		height = 20,
		split = "below"
	}

	state.terminal.job_id = vim.bo.channel;
	local win = vim.api.nvim_open_win(buf, true, win_config)
	return { buf = buf, win = win }
end

local toggle_terminal = function()
	if not vim.api.nvim_win_is_valid(state.terminal.win) then
		state.terminal = create_terminal({ buf = state.terminal.buf })
		if vim.bo[state.terminal.buf].buftype ~= "terminal" then
			vim.cmd(":terminal nu")
		end
	else
		vim.api.nvim_win_hide(state.terminal.win)
	end
end

vim.api.nvim_create_autocmd('TermOpen', {
	group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
	callback = function()
		-- Shell settings
		vim.o.number = false
		vim.o.relativenumber = false
		vim.cmd("startinsert")
	end,
})

vim.keymap.set({ 'n', 't' }, '<leader>tt', toggle_terminal, { desc = "[T]erminal [T]oggle" })
vim.keymap.set('t', '<leader>t/', '<c-\\><c-n><>')

vim.keymap.set('n', '<leader>ts', function()
	-- make
	-- dotnet run cwd
	vim.fn.chansend(state.terminal.job_id, { '\r\n' })
end, { desc = "[T]erminal [S]end command" }) ]]

return {
	{ -- Tmux

		"aserowy/tmux.nvim",
		enabled = false,
		config = function()
			local tmux = require("tmux")
			tmux.setup()

			vim.keymap.set("n", "<leader>th", tmux.NvimTmuxNavigateLeft)
			vim.keymap.set("n", "<leader>tj", tmux.NvimTmuxNavigateDown)
			vim.keymap.set("n", "<leader>tk", tmux.NvimTmuxNavigateUp)
			vim.keymap.set("n", "<leader>tl", tmux.NvimTmuxNavigateRight)
			vim.keymap.set("n", "<leader>tp", tmux.NvimTmuxNavigateLastActive)
			vim.keymap.set("n", "<leader>tn", tmux.NvimTmuxNavigateNext)
			vim.keymap.set("n", "<leader>to", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
		end,
	},
	--[[ {
		"akinsho/toggleterm.nvim",
		enabled = true,
		event = "VeryLazy",
		cmd = "ToggleTerm",
		version = "*",
		config = function()
			require("toggleterm").setup({

				start_in_insert = true,
				terminal_mappings = true,
				-- direction = 'float',
				-- shell = "pwsh.exe -NoLogo -NoProfile",
				shell = "nu",
				auto_scroll = true,
				-- persist_mode = true,
				persist_size = true,
				close_on_exit = true,
			})

			vim.keymap.set(
				{ "n", "t" },
				"<leader>tt",
				"<cmd>:3ToggleTerm direction=vertical size=80<CR>",
				{ desc = "[T]erminal [T]oggle" }
			)
		end,
	}, ]]
	--[[ {
		"folke/edgy.nvim",
		---@module 'edgy'
		---@param opts Edgy.Config
		opts = function(_, opts)
			for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
				opts[pos] = opts[pos] or {}
				table.insert(opts[pos], {
					ft = "snacks_terminal",
					size = { height = 0.4 },
					title = "%{b:snacks_terminal.id}: %{b:term_title}",
					filter = function(_buf, win)
						return vim.w[win].snacks_win
							and vim.w[win].snacks_win.position == pos
							and vim.w[win].snacks_win.relative == "editor"
							and not vim.w[win].trouble_preview
					end,
				})
			end
		end,
	}, ]]
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			terminal = {
				win = {
					position = "right",
					width = 0.4,
				},
				shell = "nu",
				bo = {
					filetype = "snacks_terminal",
				},
				wo = {},
				stack = true, -- when enabled, multiple split windows with the same position will be stacked together (useful for terminals)
				keys = {
					term_normal = {
						"<esc>",
						function(self)
							self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
							if self.esc_timer:is_active() then
								self.esc_timer:stop()
								vim.cmd("stopinsert")
							else
								self.esc_timer:start(200, 0, function() end)
								return "<esc>"
							end
						end,
						mode = "t",
						expr = true,
						desc = "Double escape to normal mode",
					},
				},
			},
		},
		init = function()
			vim.keymap.set({ "n", "t" }, "<leader>tt", function()
				Snacks.terminal()
			end, { desc = "Terminal Toggle" })
		end,
	},
}
