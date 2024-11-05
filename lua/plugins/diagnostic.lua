return {
    {
        "folke/trouble.nvim",
        opts = { function()
        end, },
        cmd = "Trouble",
        keys = {},
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            {
                "folke/todo-comments.nvim",
                config = function()
                    -- Debug keymap
                    vim.keymap.set('n', '<leader>xp', vim.diagnostic.goto_prev,
                        { desc = 'Go to [P]revious diagnostic message' })
                    vim.keymap.set('n', '<leader>xn', vim.diagnostic.goto_next,
                        { desc = 'Go to [N]ext diagnostic message' })
                    vim.keymap.set('n', '<leader>xm', vim.diagnostic.open_float,
                        { desc = 'Show diagnostic error [M]essages' })

                    vim.keymap.set('n', '<leader>xx', "<cmd>Trouble diagnostics toggle<cr>",
                        { desc = "Open/close trouble list" })
                    vim.keymap.set('n', '<leader>xw', "<cmd>Trouble symbols toggle focus=false<cr>",
                        { desc = "Open trouble [W]orkspace diagnostics" })
                    vim.keymap.set('n', '<leader>xd', "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                        { desc = "Open trouble [D]ocument diagnostics" })
                    vim.keymap.set('n', '<leader>xq', "<cmd>Trouble qflist toggle<cr>",
                        { desc = "Open trouble [Q]uickfix list" })
                    vim.keymap.set('n', '<leader>xl', "<cmd>Trouble loclist toggle<cr>",
                        { desc = "Open trouble [L]ocation list" })
                    vim.keymap.set('n', "<leader>xt", "<cmd>Trouble todo<CR>", { desc = "Open [T]odos in trouble" })
                    vim.keymap.set('n', '<leader>xr', "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                        { desc = "Open [R]eferences/definitions in trouble" })
                end
            },
        },
    },
}
