-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_user_command('FileInfo', function()
	local current_file = vim.fn.expand('%:p')
	local stat = vim.loop.fs_stat(current_file)
	if stat then
		-- print(vim.inspect(stat))
		local creation_time = os.date('%Y-%m-%d %H:%M:%S', stat.birthtime.sec)
		print(stat.type .. " / " .. creation_time .. " / " .. stat.size)
	else
		print("Could not get file information")
	end
end, { desc = "Get file info" })

vim.api.nvim_create_user_command('ResetHistory',
	function()
		local old_undolevels = vim.opt_local.undolevels
		vim.opt_local.undolevels = -1
		vim.cmd(vim.api.nvim_replace_termcodes('normal! a <BS><Esc>', true, true, true))
		vim.opt_local.undolevels = old_undolevels
	end,
	{ desc = "Set history level to -1" })

vim.api.nvim_create_user_command('ReloadPackage',
	function(opts)
		local packageName = opts.args
		package.loaded[packageName] = nil
		require(packageName)
	end,
	{
		nargs = "?",
		desc = "Reload the plugin we are testing, need to update this command if you testing another plugin"
	})

vim.api.nvim_create_user_command("TestRazorls", function()
	package.loaded.razorls = nil
	require("razorls").test()
end, { desc = "Lsp test" })

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.txt",
	desc = 'Create a new tab and display help inside that',
	group = vim.api.nvim_create_augroup('help-display', { clear = true }),
	callback = function()
		if vim.bo.buftype == "help" then
			vim.cmd("wincmd T")
		end
	end,
})
