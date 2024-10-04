
function ClearUndoHistory ()
  local old_undolevels = vim.opt_local.undolevels
  vim.opt_local.undolevels=-1
  vim.cmd(vim.api.nvim_replace_termcodes('normal! a <BS><Esc>',true,true,true))
  vim.opt_local.undolevels = old_undolevels
end

return {

}
