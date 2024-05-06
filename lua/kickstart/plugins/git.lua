-- Here is a more advanced example where we pass configuration
-- options to `gitsigns.nvim`. This is equivalent to the following lua:
--    require('gitsigns').setup({ ... })
--
-- See `:help gitsigns` to understand what the configuration keys do
return {
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

        -- Mapping
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true })

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true })

        -- Actions
        map('n', '<leader>g', "<NOP>", { desc = '[G]it Signs: ' })
        map('n', '<leader>gs', gs.stage_buffer, { desc = '[G]it Signs: stage buffer' })
        map('n', '<leader>ga', gs.stage_hunk, { desc = '[G]it Signs: stage hunk' })
        map('n', '<leader>gu', gs.undo_stage_hunk, { desc = '[G]it Signs: undo stage hunk' })
        map('n', '<leader>gr', gs.reset_buffer, { desc = '[G]it Signs: reset buffer' })
        map('n', '<leader>gw', gs.preview_hunk, { desc = '[G]it Signs: preview hunk' })
        map('n', '<leader>gB', function() gs.blame_line { full = true } end, { desc = '[G]it Signs: blame line' })
        map('n', '<leader>gm', gs.toggle_current_line_blame, { desc = '[G]it Signs: blame current line' })
        map('n', '<leader>gt', gs.diffthis, { desc = '[G]it Signs: diff this' })
        map('n', '<leader>g~', function() gs.diffthis('~') end, { desc = '[G]it Signs: diff this ~' })

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      end
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",  -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua",              -- optional
    },
    config = function()
      require("neogit").setup {}

      local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { silent = true, noremap = true, desc = 'Neo [G]it: ' .. desc, })
      end

      map('<leader>gg', ':Neogit<CR>', '')
      map('<leader>gc', ':Neogit commit<CR>', '[C]ommit')
      map('<leader>gp', ':Neogit pull<CR>', '[P]ull')
      map('<leader>gh', ':Neogit push<CR>', 'Pu[S]h')
      map('<leader>gb', ':Telescope git_branches<CR>', '[B]ranch')
      map('<leader>gl', ':G blame<CR>', 'b[L]ame')
      map('<leader>gd', ':DiffviewOpen<CR>', '[D]iffview')
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
