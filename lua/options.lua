-- See `:help.o.

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true
vim.o.cpo = "aABceFsn_"

-- fold settings
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldcolumn = "0"
vim.o.foldtext = ""
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = "a"

-- Don't show the mode, since it's already in status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this.o.on if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Autosave
vim.o.autowriteall = true

-- Save undo history
vim.o.undofile = true

-- force all horizontal splits to go below current window
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.swapfile = false

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- File list style into tree mode
vim.cmd("let g:netrw_liststyle = 3")

-- Windows 10 cmd shell pipe
vim.o.shellpipe = ">"

-- Check if nushell is installed before setting it
if vim.fn.executable("nu") == 1 then
	vim.opt.shell = "nu"

	-- -c tells nushell to run the following string as a command
	vim.opt.shellcmdflag = "-c"

	-- Reset quoting settings that are often specific to cmd.exe
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""

	-- Configure how Neovim pipes and redirects output for Nushell
	-- Nushell uses 'err>' for stderr redirection
	vim.opt.shellpipe = "| save %s --force"
	vim.opt.shellredir = "out> %s"
end

-- vim: ts=2 sts=2 sw=2 et
