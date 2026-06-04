-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end

vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--  To check the current status of your plugins, run
--    :Lazy
require("lazy").setup({

	-- modular approach: using `require 'path/name'` will
	-- include a plugin definition from file lua/path/name.lua

	{ import = "plugins" },
}, {
	rocks = { hererocks = false },
})

-- vim: ts=2 sts=2 sw=2 et
