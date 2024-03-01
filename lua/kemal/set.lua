vim.opt.guicursor = ""

-- line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- tab settings
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false


-- undo file
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- highlight search expressions
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true


-- keep scroll at a min 8 lines
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"
