return {
  { 'tpope/vim-fugitive', },
  {
    dir = "D:/Nvim/repos.nvim",
    name = "repos",
    dev = true,
    config = function()
      vim.opt.rtp:append("D:/Nvim/repos.nvim")
      local options = { debug_enabled = true }
      require("repos").setup(options)
    end
  },
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns


        -- Navigation
        vim.keymap.set('n', '<leader>gl', function()
          if vim.wo.diff then return '<leader>gl' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = '[G]it Signs: next hunk' })

        vim.keymap.set('n', '<leader>gh', function()
          if vim.wo.diff then return '<leader>gh' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = '[G]it Signs: previous hunk' })

        -- Actions
        vim.keymap.set('n', '<leader>g', "<NOP>", { desc = '[G]it Signs: ' })
        vim.keymap.set('n', '<leader>gS', gs.stage_buffer, { desc = '[G]it Signs: stage buffer' })
        vim.keymap.set('n', '<leader>gs', gs.stage_hunk, { desc = '[G]it Signs: stage hunk toggle' })
        vim.keymap.set('n', '<leader>gr', gs.reset_buffer, { desc = '[G]it Signs: reset buffer' })
        -- vim.keymap.set('n', '<leader>gp', gs.preview_hunk, { desc = '[G]it Signs: preview hunk' })
        vim.keymap.set('n', '<leader>gb', gs.toggle_current_line_blame, { desc = '[G]it Signs: blame current line' })
        vim.keymap.set('n', '<leader>gd', gs.diffthis, { desc = '[G]it Signs: diff this' })
        vim.keymap.set('n', '<leader>gb', function() gs.blame_line { full = true } end,
          { desc = '[G]it Signs: blame line' })
        vim.keymap.set('n', '<leader>gT', function() gs.diffthis('~') end, { desc = '[G]it Signs: diff this ~' })
        vim.keymap.set('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end)

        vim.keymap.set("n", "<leader>gw", "<CMD>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
          { desc = 'Telescope [G]it [W]orktrees', silent = true })
        vim.keymap.set("n", "<leader>gW",
          "<CMD>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
          { desc = 'Telescope [G]it create [W]orktrees', silent = true })

        -- Text object
        vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>',
          { desc = '[G]itsigns select hunk', silent = true })

        -- Setup key mappings for git operations
        vim.keymap.set('n', '<leader>ga', ':Telescope git_status<CR>', { noremap = true })
        vim.keymap.set('n', '<leader>gc', ':Telescope git_commits<CR>', { noremap = true })
        vim.keymap.set('n', '<leader>gB', ':Telescope git_branches<CR>', { noremap = true })
      end
    },
  },
  { -- Lazy git
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension("lazygit")
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = { "*" },
        command = ":lua require('lazygit.utils').project_root_dir()",
      })
    end,
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "[G]it Lazy[G]it" }
    }
  },
  { -- Neo git
    "NeogitOrg/neogit",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua",           -- optional
    },
    config = function()
      require("neogit").setup {}
      vim.keymap.set('n', '<leader>gg', ':Neogit<CR>', { silent = true, noremap = true, desc = 'Neo [G]it: ' })
      vim.keymap.set('n', '<leader>gc', ':Neogit commit<CR>',
        { silent = true, noremap = true, desc = 'Neo [G]it: [C]ommit' })
      vim.keymap.set('n', '<leader>gp', ':Neogit pull<CR>', { silent = true, noremap = true, desc = 'Neo [G]it: [P]ull' })
      vim.keymap.set('n', '<leader>gh', ':Neogit push<CR>', { silent = true, noremap = true, desc = 'Neo [G]it: Pu[S]h' })
      vim.keymap.set('n', '<leader>gb', ':Telescope git_branches<CR>',
        { silent = true, noremap = true, desc = 'Neo [G]it: [B]ranch' })
      vim.keymap.set('n', '<leader>gl', ':G blame<CR>', { silent = true, noremap = true, desc = 'Neo [G]it: b[L]ame' })
      vim.keymap.set('n', '<leader>gd', ':DiffviewOpen<CR>',
        { silent = true, noremap = true, desc = 'Neo [G]it: [D]iffview' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
