-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
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
  end, { desc = "Set history level to -1" })

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
  pattern = "*.cs",
  callback = function()
    if vim.lsp.codelens then
      vim.lsp.codelens.refresh({ bufnr = 0 })
    end
  end
})

vim.opt.rtp:append("D:/Razor/nvim.razorls")
vim.api.nvim_create_user_command("Test", function()
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

P = function(v)
  print(vim.inspect(v))
  return v
end

R = function(v)
  require("plenary.reload").reload_module(v)
  return require(v)
end
