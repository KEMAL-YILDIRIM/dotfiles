-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_user_command("FileInfo", function()
	local current_file = vim.fn.expand("%:p")
	local stat = vim.uv.fs_stat(current_file)
	if stat then
		local creation_time = os.date("%Y-%m-%d %H:%M:%S", stat.birthtime.sec)
		print(stat.type .. " / created_at: " .. creation_time .. " / size: " .. stat.size)
	else
		print("Could not get file information")
	end
end, { desc = "Get file info" })

vim.api.nvim_create_user_command("ResetHistory", function()
	local old_undolevels = vim.opt_local.undolevels
	vim.opt_local.undolevels = -1
	vim.cmd(vim.api.nvim_replace_termcodes("normal! a <BS><Esc>", true, true, true))
	vim.opt_local.undolevels = old_undolevels
end, { desc = "Set history level to -1" })

vim.api.nvim_create_user_command("ReloadPackage", function(opts)
	local packageName = opts.args
	package.loaded[packageName] = nil
	require(packageName)
end, {
	nargs = "?",
	desc = "Reload the plugin we are testing, need to update this command if you testing another plugin",
})

vim.api.nvim_create_user_command('ClearShada', function(opts)
	local permanent = opts.bang
	local target = opts.args ~= '' and opts.args or nil
	F.clear_shada({ permanent = permanent, target = target })
end, {
	bang = true,
	nargs = '?',
	complete = function()
		local suffixes = F.get_shada_tmp_suffixes()
		local completions = { 'tmp' }
		vim.list_extend(completions, suffixes)
		return completions
	end,
	desc = 'Clear shada files. No args: clear recent files. !: delete all. "tmp": delete all tmp. Single letter: delete specific tmp file',
})

-- open help in vertical split
vim.api.nvim_create_autocmd("FileType", {
	pattern = "help",
	-- command = "wincmd L", --vertical window
	command = "wincmd T",
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			-- defer centering slightly so it's applied after render
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd("VimResized", {
	command = "wincmd =",
})

-- no auto continue comments on new line
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("no_auto_comment", {}),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Treesitter folding: set window-local foldmethod/foldexpr only when a parser
-- is available for this filetype. Using vim.wo[0][0] scopes the option to the
-- current window+buffer combination, preventing special buffers (quickfix,
-- terminal, oil.nvim floats) from inheriting treesitter folding.
-- Falls back to indent folding for files without a treesitter parser.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_folds", { clear = true }),
	callback = function()
		local ft = vim.bo.filetype
		-- Skip special/non-file buffers that should never use expr folding
		if ft == "" or vim.bo.buftype ~= "" then
			return
		end
		local lang = vim.treesitter.language.get_lang(ft)
		local has_parser = lang and (pcall(vim.treesitter.get_parser, 0, lang))
		if has_parser then
			vim.wo[0][0].foldmethod = "expr"
			vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
		else
			vim.wo[0][0].foldmethod = "indent"
			vim.wo[0][0].foldexpr = ""
		end
	end,
	desc = "Set treesitter folding when parser available, indent folding otherwise",
})
