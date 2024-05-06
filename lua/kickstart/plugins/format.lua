vim.keymap.set("n", "<leader>==", vim.lsp.buf.format, { desc = "Equalize indent for current buffer" })
vim.keymap.set("n", "<leader>=-", "gg<M-v>G=<CR>:w<CR>", { desc = "Equalize indent for current buffer" })
return {
  {
    -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
    -- NOTE: Plugins can also be added by using a table,
    -- with the first argument being the link and the following
    -- keys can be used to configure plugin behavior/loading/etc.
    --
    -- Use `opts = {}` to force a plugin to be loaded.
    --
    --  This is equivalent to:
    --    require('Comment').setup({})

    -- "gc" to comment visual regions/lines
    --{ 'numToStr/Comment.nvim', opts = {} },
  },
}
-- vim: ts=2 sts=2 sw=2 et
