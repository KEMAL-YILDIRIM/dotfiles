local FileHistory = function()
  -- Custom file history that handles renames properly
  local file_path = vim.fn.expand('%:.') -- relative path
  local cmd = { 'git', 'log', '--follow', '--pretty=format:%H %ad %s', '--date=short', '--', file_path }
  local result = F.safe_systemlist(cmd)

  if vim.v.shell_error ~= 0 or #result == 0 then
    vim.notify('No git history found for ' .. file_path, vim.log.levels.WARN)
    return
  end

  local commits = {}
  for _, line in ipairs(result) do
    local hash, date, message = line:match('^(%x+)%s+(%d%d%d%d%-%d%d%-%d%d)%s+(.*)$')
    if hash and date then
      table.insert(commits, { hash = hash, date = date, message = message or '', path = file_path })
    end
  end

  if #commits == 0 then
    vim.notify('Could not parse git history', vim.log.levels.WARN)
    return
  end

  require('telescope.pickers').new({}, {
    prompt_title = 'File History: ' .. vim.fn.fnamemodify(file_path, ':t'),
    finder = require('telescope.finders').new_table({
      results = commits,
      entry_maker = function(entry)
        return {
          value = entry.hash,
          display = entry.date .. ' ' .. entry.hash:sub(1, 7) .. ' ' .. entry.message,
          ordinal = entry.hash .. entry.date .. entry.message,
          path = entry.path,
        }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd('Gedit ' .. selection.value .. ':' .. selection.path)
      end)
      return true
    end,
    previewer = require('telescope.previewers').new_buffer_previewer({
      title = 'File at commit',
      get_buffer_by_name = function(_, entry)
        return entry.value .. ':' .. entry.path
      end,
      define_preview = function(self, entry)
        if self.state.bufname == entry.value .. ':' .. entry.path then
          return
        end
        local content = F.safe_system('git --no-pager show ' .. entry.value .. ':"' .. entry.path .. '"')
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(content, '\n'))
        require('telescope.previewers.utils').highlighter(self.state.bufnr, vim.filetype.match({ filename = entry.path }))
      end,
    }),
  }):find()
end 
return {
  { "tpope/vim-fugitive" },
  { "sindrets/diffview.nvim" },
  {
    dir = "D:/Nvim/repos.nvim",
    name = "repos",
    dev = true,
    config = function()
      vim.opt.rtp:append("D:/Nvim/repos.nvim")
      local options = { debug_enabled = true }
      require("repos").setup(options)
    end,
  },
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- Navigation
        vim.keymap.set("n", "<leader>ghn", function()
          if vim.wo.diff then
            return "<leader>ghl"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Git Signs: next hunk" })

        vim.keymap.set("n", "<leader>ghp", function()
          if vim.wo.diff then
            return "<leader>ghh"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Git Signs: previous hunk" })

        -- Actions
        vim.keymap.set("n", "<leader>g", "<NOP>", { desc = "Git" })
        vim.keymap.set("n", "<leader>ghs", gs.stage_buffer, { desc = "Git Signs: stage buffer" })
        vim.keymap.set("n", "<leader>ght", gs.stage_hunk, { desc = "Git Signs: stage hunk toggle" })
        vim.keymap.set("n", "<leader>gha", gs.reset_buffer, { desc = "Git Signs: reset buffer" })
        vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { desc = "Git Signs: preview hunk" })
        vim.keymap.set( "n", "<leader>ghb", gs.toggle_current_line_blame, { desc = "Git Signs: blame current line" })
        vim.keymap.set("n", "<leader>ghd", function() gs.diffthis("~") end, { desc = "Git Signs: diff this ~" })
        vim.keymap.set("n", "<leader>ghl", function() gs.blame_line({ full = true }) end, { desc = "Git Signs: blame line" })
        vim.keymap.set("n", "<leader>gd", function() vim.cmd("DiffviewOpen") end, { desc = "Git Signs: diff this" })
        vim.keymap.set("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Git Signs: Reset hunk" })

        -- Text object
        vim.keymap.set( { "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Gitsigns select hunk", silent = true })

        -- Setup key mappings for git operations
        vim.keymap.set("n", "<leader>gts", ":Telescope git_status<CR>", { noremap = true })
        vim.keymap.set(
          "n",
          "<leader>gl",
          ":Telescope git_commits<CR>",
          { noremap = true, desc = "Git Log" }
        )
        vim.keymap.set("n", "<leader>gc", FileHistory, { noremap = true, desc = 'Git File History' })
        vim.keymap.set("n", "<leader>gb", ":Telescope git_branches<CR>", { noremap = true })
        vim.keymap.set(
          "n",
          "<leader>gtw",
          "<CMD>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
          { desc = "Telescope Git Worktrees", silent = true }
        )
        vim.keymap.set(
          "n",
          "<leader>gtW",
          "<CMD>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
          { desc = "Telescope git create worktrees", silent = true }
        )
      end,
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
      { "<leader>gg", "<CMD>:LazyGitCurrentFile<CR>", desc = "Git LazyGit" },
    },
  },
  { -- Neo git
    "NeogitOrg/neogit",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua", -- optional
    },
    config = function()
      require("neogit").setup({})
      vim.keymap.set("n", "<leader>gg", ":Neogit<CR>", { silent = true, noremap = true, desc = "Neo Git: " })
      vim.keymap.set(
        "n",
        "<leader>gc",
        ":Neogit commit<CR>",
        { silent = true, noremap = true, desc = "Neo Git: Commit" }
      )
      vim.keymap.set(
        "n",
        "<leader>gp",
        ":Neogit pull<CR>",
        { silent = true, noremap = true, desc = "Neo Git: Pull" }
      )
      vim.keymap.set(
        "n",
        "<leader>gh",
        ":Neogit push<CR>",
        { silent = true, noremap = true, desc = "Neo Git: PuSh" }
      )
      vim.keymap.set(
        "n",
        "<leader>gl",
        ":G blame<CR>",
        { silent = true, noremap = true, desc = "Neo Git: bLame" }
      )
      vim.keymap.set(
        "n",
        "<leader>gd",
        ":DiffviewOpen<CR>",
        { silent = true, noremap = true, desc = "Neo Git: Diffview" }
      )
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
