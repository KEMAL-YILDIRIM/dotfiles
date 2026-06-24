-- Guard against an upstream Neovim bug in vim.lsp.diagnostic.on_diagnostic
-- (runtime/lua/vim/lsp/diagnostic.lua:296, nvim 0.11.x / 0.12.x).
--
-- When a pull-diagnostics response arrives after the buffer's internal
-- bufstate has been cleaned up (buffer wiped, LSP detached, pull-kind
-- switched, etc.), the handler indexes a nil bufstate and crashes with:
--
--   attempt to index local 'bufstate' (a nil value)
--
-- We wrap both the module function and the registered LSP handler so the
-- response is dropped silently in that race. Remove once upstream patches it.

local diag = vim.lsp and vim.lsp.diagnostic
if not diag or type(diag.on_diagnostic) ~= 'function' then
  return
end

local original = diag.on_diagnostic

local function safe_on_diagnostic(err, result, ctx)
  if err ~= nil then
    return original(err, result, ctx)
  end
  if result == nil then
    return
  end
  local bufnr = ctx and ctx.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  -- We can't peek at the private `bufstates` table directly, so wrap in
  -- pcall as a last line of defence. The early validity check covers the
  -- common case; pcall covers the rest.
  local ok, perr = pcall(original, err, result, ctx)
  if not ok then
    vim.schedule(function()
      vim.notify('lsp diagnostic handler suppressed error: ' .. tostring(perr), vim.log.levels.DEBUG)
    end)
  end
end

diag.on_diagnostic = safe_on_diagnostic
if vim.lsp.handlers then
  vim.lsp.handlers['textDocument/diagnostic'] = safe_on_diagnostic
end
