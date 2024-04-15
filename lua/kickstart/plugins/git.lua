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
        map('n', '<leader>gss', gs.stage_buffer)
        map('n', '<leader>gsa', gs.stage_hunk)
        map('n', '<leader>gsu', gs.undo_stage_hunk)
        map('n', '<leader>gsr', gs.reset_buffer)
        map('n', '<leader>gsp', gs.preview_hunk)
        map('n', '<leader>gsb', function() gs.blame_line { full = true } end)
        map('n', '<leader>gsB', gs.toggle_current_line_blame)
        map('n', '<leader>gsd', gs.diffthis)
        map('n', '<leader>gsD', function() gs.diffthis('~') end)

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
        vim.keymap.set('n', keys, func, { silent = true, noremap = true, desc = '[G]it: ' .. desc, })
      end

      map("<leader>gg", ":Neogit<CR>", " Neo[G]it")
      map("<leader>gc", ":Neogit commit<CR>", "[C]ommit")
      map("<leader>gpl", ":Neogit pull<CR>", "[P]ul[L]")
      map("<leader>gps", ":Neogit push<CR>", "[P]u[S]h")
      map("<leader>gbr", ":Telescope git_branches<CR>", "[BR]anch")
      map("<leader>gbl", ":G blame<CR>", "[BL]ame")
      map("<leader>gd", ":DiffviewOpen<CR>", "[D]iffview")
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
