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
                    vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev,
                        { desc = 'Go to [P]revious diagnostic message' })
                    vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next,
                        { desc = 'Go to [N]ext diagnostic message' })
                    vim.keymap.set('n', '<leader>dm', vim.diagnostic.open_float,
                        { desc = 'Show diagnostic error [M]essages' })

                    vim.keymap.set('n', '<leader>dx', "<cmd>Trouble diagnostics toggle<cr>",
                        { desc = "Open/close trouble list" })
                    vim.keymap.set('n', '<leader>dw', "<cmd>Trouble symbols toggle focus=false<cr>",
                        { desc = "Open trouble [W]orkspace diagnostics" })
                    vim.keymap.set('n', '<leader>dd', "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                        { desc = "Open trouble [D]ocument diagnostics" })
                    vim.keymap.set('n', '<leader>dq', "<cmd>Trouble qflist toggle<cr>",
                        { desc = "Open trouble [Q]uickfix list" })
                    vim.keymap.set('n', '<leader>dl', "<cmd>Trouble loclist toggle<cr>",
                        { desc = "Open trouble [L]ocation list" })
                    vim.keymap.set('n', "<leader>dt", "<cmd>Trouble todo<CR>", { desc = "Open [T]odos in trouble" })
                    vim.keymap.set('n', '<leader>dr', "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                        { desc = "Open [R]eferences/definitions in trouble" })
                end
            },
        },
    },
}
