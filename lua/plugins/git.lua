local G = {

  ShowGitInSplit = function(git_args, buf_name, filetype)
    local existing = vim.fn.bufnr(buf_name)
    if existing ~= -1 then
      vim.cmd 'vsplit'
      vim.api.nvim_set_current_buf(existing)
      return
    end
    local content = F.safe_system(git_args)
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))
    vim.api.nvim_buf_set_name(buf, buf_name)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].modifiable = false
    vim.cmd 'vsplit'
    vim.api.nvim_set_current_buf(buf)
    if filetype then
      vim.bo[buf].filetype = filetype
    end
  end,

  FileHistory = function()
    -- Custom file history that handles renames properly
    local abs_path = vim.fn.expand '%:p' -- absolute path of current file
    local file_dir = vim.fn.fnamemodify(abs_path, ':h') -- directory containing the file

    -- Find git root from file's directory
    local git_root = vim.fn.systemlist({ 'git', '-C', file_dir, 'rev-parse', '--show-toplevel' })[1]
    if vim.v.shell_error ~= 0 or not git_root then
      vim.notify('Not in a git repository: ' .. file_dir, vim.log.levels.WARN)
      return
    end

    -- Get path relative to git root
    git_root = git_root:gsub('\\', '/'):gsub('/$', '')
    abs_path = abs_path:gsub('\\', '/')
    local file_path = abs_path:sub(#git_root + 2) -- +2 to skip the trailing slash

    -- Use --name-only to get the actual file path at each commit (handles renames)
    local cmd = {
      'git',
      '-C',
      git_root,
      'log',
      '--follow',
      '--pretty=format:%H %ad %s',
      '--date=short',
      '--name-only',
      '--',
      file_path,
    }
    local result = F.safe_systemlist(cmd)

    if vim.v.shell_error ~= 0 or #result == 0 then
      vim.notify('No git history found for ' .. file_path, vim.log.levels.WARN)
      return
    end

    local commits = {}
    local i = 1
    while i <= #result do
      local line = result[i]
      local hash, date, message = line:match '^(%x+)%s+(%d%d%d%d%-%d%d%-%d%d)%s+(.*)$'
      if hash and date then
        -- Skip empty lines and get the file path (next non-empty line after commit info)
        i = i + 1
        while i <= #result and result[i] == '' do
          i = i + 1
        end
        local commit_path = (i <= #result and not result[i]:match '^%x+%s+%d%d%d%d%-%d%d%-%d%d') and result[i] or file_path
        table.insert(commits, { hash = hash, date = date, message = message or '', path = commit_path })
      end
      i = i + 1
    end

    if #commits == 0 then
      vim.notify('Could not parse git history', vim.log.levels.WARN)
      return
    end

    require('telescope.pickers')
      .new({}, {
        prompt_title = 'File History: ' .. vim.fn.fnamemodify(file_path, ':t'),
        finder = require('telescope.finders').new_table {
          results = commits,
          entry_maker = function(entry)
            return {
              value = entry.hash,
              display = entry.date .. ' ' .. entry.hash:sub(1, 7) .. ' ' .. entry.message,
              ordinal = entry.hash .. entry.date .. entry.message,
              path = entry.path,
              git_root = git_root,
            }
          end,
        },
        sorter = require('telescope.config').values.generic_sorter {},
        attach_mappings = function(prompt_bufnr)
          local actions = require 'telescope.actions'
          local action_state = require 'telescope.actions.state'
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            local ref = selection.value .. ':' .. selection.path
            local ft = vim.filetype.match { filename = selection.path }
            ShowGitInSplit({ 'git', '-C', selection.git_root, '--no-pager', 'show', ref }, ref, ft)
          end)
          return true
        end,
        
        previewer = require('telescope.previewers').new_buffer_previewer {
          title = 'File at commit',
          get_buffer_by_name = function(_, entry)
            return entry.value .. ':' .. entry.path
          end,
          define_preview = function(self, entry)
            if self.state.bufname == entry.value .. ':' .. entry.path then
              return
            end
            local content = F.safe_system {
              'git',
              '-C',
              entry.git_root,
              '--no-pager',
              'show',
              entry.value .. ':' .. entry.path,
            }
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(content, '\n'))
            require('telescope.previewers.utils').highlighter(self.state.bufnr, vim.filetype.match { filename = entry.path })
          end,
        },
      })
      :find()
  end,

  -- Retarget the live inline diff to a commit picked via Telescope, then
  -- force line highlight + show deleted (old) lines so NEW=blue / OLD=red show in-buffer.
  PickInlineDiffBase = function()
    local cwd = vim.fn.expand '%:p:h'
    require('telescope.builtin').git_bcommits {
      cwd = cwd,
      attach_mappings = function(prompt_bufnr)
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local gs = require 'gitsigns'
          gs.change_base(selection.value, true)
          gs.toggle_linehl(true)
          gs.preview_hunk_inline()
          gs.toggle_word_diff(true)
          vim.notify('Inline diff base -> ' .. selection.value:sub(1, 7), vim.log.levels.INFO)
        end)
        return true
      end,
    }
  end,

  -- Inline diff colors: NEW = blue, OLD = red (catppuccin-macchiato palette)
  SetInlineDiffColors = function()
    local colors = F.get_colors 'tailwind'
    local deleted, deleted_bg, modified, modified_bg, new, new_bg = colors.red[900], colors.red[200], colors.emerald[700], colors.emerald[200], colors.sky[500], colors.sky[200];
    vim.api.nvim_set_hl(0, 'GitSignsAddLn', { bg = new })
    vim.api.nvim_set_hl(0, 'GitSignsAddInline', { bg = new_bg })
    vim.api.nvim_set_hl(0, 'GitSignsChangeLn', { bg = modified })
    vim.api.nvim_set_hl(0, 'GitSignsChangeInline', { bg = modified_bg })
    vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = new })
    vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = modified })
    --------
    vim.api.nvim_set_hl(0, 'GitSignsDeleteLn', { bg = deleted })
    vim.api.nvim_set_hl(0, 'GitSignsDeleteVirtLn', { bg = deleted_bg })
    vim.api.nvim_set_hl(0, 'GitSignsDeleteInline', { bg = deleted_bg })
    vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = deleted })
    --------
    vim.api.nvim_set_hl(0, 'diffAdded', { fg = new })
    vim.api.nvim_set_hl(0, 'diffRemoved', { fg = deleted })
    vim.api.nvim_set_hl(0, 'diffChanged', { fg = modified })
    vim.api.nvim_set_hl(0, 'diffLine', { fg = modified_bg })
  end,
}

-- Apply inline diff colors now and re-apply whenever the colorscheme changes
-- (gitsigns highlights would otherwise be reset by a colorscheme reload).
G.SetInlineDiffColors()
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = G.SetInlineDiffColors,
  desc = 'Reapply gitsigns inline diff colors (new=blue / old=red)',
})

return {
  { 'tpope/vim-fugitive' },
  { 'sindrets/diffview.nvim' },
  { -- Git branch graph viewer (one commit per row, fugitive-integrated)
    'rbong/vim-flog',
    lazy = true,
    cmd = { 'Flog', 'Flogsplit', 'Floggit' },
    dependencies = {
      'tpope/vim-fugitive',
      'sindrets/diffview.nvim',
    },
    init = function()
      -- Static, per-column branch colors. Dynamic highlighting tints the bullet
      -- and its branch line the same hue, making lines/dots visually 'mix'.
      vim.g.flog_enable_dynamic_branch_hl = false

      vim.g.flog_default_opts = {
        -- Match the old gitgraph cap of 5000 commits.
        max_count = 5000,
        -- Date only (drop time + timezone).
        date = 'short',
        -- Default format with the author truncated to a 5-char column (3 visible
        -- letters + git's ".." ellipsis). The [..]/{..} markers are what flog uses
        -- for hash/author syntax highlighting.
        format = '%ad [%h] {%<(5,trunc)%an}%d %s',
      }

      -- Rewire commit selection to open diffview instead of fugitive, keeping
      -- the graph a pure navigator (mirrors the old gitgraph hooks).
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'floggraph',
        desc = 'Flog: open selected commit(s) in diffview',
        callback = function(args)
          -- The global 'trail:·' listchar renders flog's trailing-space line
          -- padding as dots, which mangles the graph. Disable 'list' here.
          vim.wo.list = false

          -- Single commit under cursor -> diff that commit against its parent.
          vim.keymap.set('n', '<CR>', function()
            local hash = vim.fn['flog#Format'] '%H'
            if hash ~= '' then
              vim.cmd('DiffviewOpen ' .. hash .. '^!')
            end
          end, { buffer = args.buf, desc = 'Diffview: selected commit' })

          -- Visual range -> diff between the two endpoint commits.
          vim.keymap.set('x', '<CR>', function()
            local from = vim.fn['flog#Format'] "%(h'<)"
            local to = vim.fn['flog#Format'] "%(h'>)"
            if from ~= '' and to ~= '' then
              vim.cmd('DiffviewOpen ' .. from .. '~1..' .. to)
            end
          end, { buffer = args.buf, desc = 'Diffview: selected range' })
        end,
      })
    end,
    keys = {
      -- flog resolves the repo from the current buffer via fugitive, so no path
      -- filter is needed. Avoid -path: it triggers git history simplification
      -- and hides branch fork/merge topology.
      { '<leader>gb', '<cmd>Flog -all<cr>', desc = 'Git Graph (branches)' },
    },
  },
  {
    dir = 'D:/Nvim/repos.nvim',
    name = 'repos',
    dev = true,
    config = function()
      vim.opt.rtp:append 'D:/Nvim/repos.nvim'
      local options = { debug_enabled = true }
      require('repos').setup(options)
    end,
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
      word_diff = false,
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- Navigation
        vim.keymap.set('n', '<leader>ghn', function()
          if vim.wo.diff then
            return '<leader>ghl'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, desc = 'Git Signs: next hunk' })

        vim.keymap.set('n', '<leader>ghp', function()
          if vim.wo.diff then
            return '<leader>ghh'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, desc = 'Git Signs: previous hunk' })

        -- Actions
        vim.keymap.set('n', '<leader>g', '<NOP>', { desc = 'Git' })
        vim.keymap.set('n', '<leader>ghs', gs.stage_buffer, { desc = 'Git Signs: stage buffer' })
        vim.keymap.set('n', '<leader>ght', gs.stage_hunk, { desc = 'Git Signs: stage hunk toggle' })
        vim.keymap.set('n', '<leader>ghr', gs.reset_buffer, { desc = 'Git Signs: reset buffer' })
        vim.keymap.set('n', '<leader>gp', gs.preview_hunk, { desc = 'Git Signs: preview hunk' })
        vim.keymap.set('n', '<leader>ghb', gs.toggle_current_line_blame, { desc = 'Git Signs: blame current line' })
        vim.keymap.set('n', '<leader>ghd', function()
          gs.diffthis '~'
        end, { desc = 'Git Signs: diff this ~' })
        vim.keymap.set('n', '<leader>ghl', function()
          gs.blame_line { full = true }
        end, { desc = 'Git Signs: blame line' })
        vim.keymap.set('n', '<leader>gd', function()
          vim.cmd 'DiffviewOpen'
        end, { desc = 'DiffviewOpen -- %' })

        -- Inline live-buffer diff (NEW=blue / OLD=red) against a chosen commit
        vim.keymap.set('n', '<leader>gi', G.PickInlineDiffBase, { desc = 'Git: inline diff vs picked commit' })
        vim.keymap.set('n', '<leader>g0', function()
          gs.change_base(nil, true)
          gs.toggle_deleted(false)
          vim.notify('Inline diff base reset to index/HEAD', vim.log.levels.INFO)
        end, { desc = 'Git: reset inline diff base' })
        vim.keymap.set('n', '<leader>gx', function()
          gs.toggle_deleted()
        end, { desc = 'Git: toggle deleted (old) lines inline' })
        vim.keymap.set('v', '<leader>gr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'Git Signs: Reset hunk' })

        -- Text object
        vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'Gitsigns select hunk', silent = true })

        -- Setup key mappings for git operations
        vim.keymap.set('n', '<leader>gs', function()
          require('telescope').extensions.repos.status()
        end, { noremap = true, desc = 'Git Status (Solution)' })
        vim.keymap.set('n', '<leader>gts', ':Telescope git_status<CR>', { noremap = true })
        vim.keymap.set('n', '<leader>gl', ':Telescope git_commits<CR>', { noremap = true, desc = 'Git Log' })
        vim.keymap.set('n', '<leader>gf', G.FileHistory, { noremap = true, desc = 'Git File History' })
        vim.keymap.set('n', '<leader>gc', function()
          local cwd = vim.fn.expand '%:p:h'
          require('telescope.builtin').git_bcommits {
            cwd = cwd,
            attach_mappings = function(prompt_bufnr)
              local actions = require 'telescope.actions'
              local action_state = require 'telescope.actions.state'
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local hash = selection.value
                local file = vim.fn.expand '%:t'
                G.ShowGitInSplit({ 'git', '-C', cwd, '--no-pager', 'show', hash, '--', file }, hash, 'diff')
              end)
              return true
            end,
          }
        end, { noremap = true, desc = 'Git Commits' })
        vim.keymap.set('n', '<leader>gtb', ':Telescope git_branches<CR>', { noremap = true })
        vim.keymap.set(
          'n',
          '<leader>gtw',
          "<CMD>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
          { desc = 'Telescope Git Worktrees', silent = true }
        )
        vim.keymap.set(
          'n',
          '<leader>gtW',
          "<CMD>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
          { desc = 'Telescope git create worktrees', silent = true }
        )
      end,
    },
  },
  { -- Lazy git
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('telescope').load_extension 'lazygit'
      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = { '*' },
        command = ":lua require('lazygit.utils').project_root_dir()",
      })
    end,
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>gg', '<CMD>:LazyGitCurrentFile<CR>', desc = 'Git LazyGit' },
      { '<leader>gR', "<CMD>:lua require('telescope').extensions.lazygit.lazygit()<CR>", desc = 'Git LazyGit' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
