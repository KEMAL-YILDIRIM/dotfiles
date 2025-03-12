local state = {
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
			vim.cmd(":terminal pwsh.exe --NoLogo")
		end
	else
		vim.api.nvim_win_hide(state.terminal.win)
	end
end

vim.api.nvim_create_autocmd('TermOpen', {
	group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
	callback = function()
		-- Shell settings
		vim.opt.number = false
		vim.opt.relativenumber = false
		vim.cmd("startinsert")
	end,
})

vim.keymap.set({ 'n', 't' }, '<leader>tt', toggle_terminal, { desc = "[T]erminal [T]oggle" })
vim.keymap.set('t', '<leader>t/', '<c-\\><c-n><>')

vim.keymap.set('n', '<leader>ts', function()
	-- make
	-- dotnet run cwd
	vim.fn.chansend(state.terminal.job_id, { '\r\n' })
end, { desc = "[T]erminal [S]end command" })


return {
	{ -- Tmux

		'aserowy/tmux.nvim',
		enabled = false,
		config = function()
			local tmux = require('tmux')
			tmux.setup()

			vim.keymap.set('n', "<leader>th", tmux.NvimTmuxNavigateLeft)
			vim.keymap.set('n', "<leader>tj", tmux.NvimTmuxNavigateDown)
			vim.keymap.set('n', "<leader>tk", tmux.NvimTmuxNavigateUp)
			vim.keymap.set('n', "<leader>tl", tmux.NvimTmuxNavigateRight)
			vim.keymap.set('n', "<leader>tp", tmux.NvimTmuxNavigateLastActive)
			vim.keymap.set('n', "<leader>tn", tmux.NvimTmuxNavigateNext)
			vim.keymap.set("n", "<leader>to", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
		end,

	},
	{
		'akinsho/toggleterm.nvim',
		enabled = false,
		event = "VeryLazy",
		cmd = "ToggleTerm",
		version = "*",
		config = function()
			require('toggleterm').setup({

				start_in_insert = true,
				terminal_mappings = true,
				-- direction = 'float',
				-- shell = "pwsh.exe -NoLogo -NoProfile",
				shell = "pwsh.exe -NoLogo",
				auto_scroll = true,
				-- persist_mode = true,
				persist_size = true,
				close_on_exit = true,
			})

			vim.keymap.set({ 'n', 't' }, '<c-\\>', '<cmd>:3ToggleTerm direction=vertical size=100<CR>',
				{ desc = "[T]erminal [T]oggle" })
		end
	}
}
