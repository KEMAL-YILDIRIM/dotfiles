-- Highlight todo, notes, etc in comments
return {
    {
        'folke/todo-comments.nvim',
        event = 'VimEnter',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = { signs = false }
    },
    {
        'numToStr/Comment.nvim',
        opts = {},
        config = function()
            local api = require('Comment.api')

            vim.keymap.set('n', '<leader>cl', api.toggle.linewise.current, { desc = '[C]omment out current [l]ine' })
            vim.keymap.set('n', '<leader>cb', api.toggle.blockwise.current, { desc = '[C]omment out current [b]lock' })

            local esc = vim.api.nvim_replace_termcodes(
                '<ESC>', true, false, true
            )

            -- Toggle selection (linewise)
            vim.keymap.set('x', '<leader>cl', function()
                vim.api.nvim_feedkeys(esc, 'nx', false)
                api.toggle.linewise(vim.fn.visualmode())
            end)

            -- Toggle selection (blockwise)
            vim.keymap.set('x', '<leader>cb', function()
                vim.api.nvim_feedkeys(esc, 'nx', false)
                api.toggle.blockwise(vim.fn.visualmode())
            end)

            vim.keymap.set({ 'n', 'v' }, '<leader>ci', '<cmd>cib<cr><leader>cl<cr>',
                { desc = '[C]omment [I]nside block' })
            vim.keymap.set({ 'n', 'v' }, '<leader>ca', '<cmd>cab<cr><leader>cl<cr>',
                { desc = '[C]omment [A]round block' })
        end
    },
}
