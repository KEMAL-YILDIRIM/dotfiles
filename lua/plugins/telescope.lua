return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires special font.
      --  If you already have a Nerd Font, or terminal set up with fallback fonts
      --  you can enable this
      { 'nvim-tree/nvim-web-devicons' },
      -- { 'rcarriga/nvim-notify' }
    },
    config = function()
      -- Two important keymaps to use while in telescope are:
      --  - Insert mode: <C-/>
      --  - Normal mode: ?

      -- Limit the color of the path to two
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "TelescopeResults",
        callback = function(ctx)
          vim.api.nvim_buf_call(ctx.buf, function()
            vim.fn.matchadd("TelescopeParent", "\t\t.*$")
            vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
          end)
        end,
      })

      -- Set the filename and the ext to the first part of path
      local function filenameFirst(_, path)
        local tail = vim.fs.basename(path)
        local parent = vim.fs.dirname(path)
        if parent == "." then return tail end
        return string.format("%s\t\t%s", tail, parent)
      end


      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local telescope = require('telescope')
      local actions = require('telescope.actions')
      local pickers = require "telescope.pickers"
      local finders = require "telescope.finders"
      local make_entry = require "telescope.make_entry"
      local conf = require "telescope.config".values

      local live_multigrep = function(opts)
        opts = opts or {}
        opts.cwd = opts.cwd or vim.uv.cwd()

        local finder = finders.new_async_job {
          command_generator = function(prompt)
            if not prompt or prompt == "" then
              return nil
            end

            local pieces = vim.split(prompt, "  ")
            local args = { "rg" }
            if pieces[1] then
              table.insert(args, "-e")
              table.insert(args, pieces[1])
            end

            if pieces[2] then
              table.insert(args, "-g")
              table.insert(args, pieces[2])
            end

            ---@diagnostic disable-next-line: deprecated
            return vim.tbl_flatten {
              args,
              { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
            }
          end,
          entry_maker = make_entry.gen_from_vimgrep(opts),
          cwd = opts.cwd,
        }

        pickers.new(opts, {
          debounce = 100,
          prompt_title = "Multi Grep",
          finder = finder,
          previewer = conf.grep_previewer(opts),
          sorter = require("telescope.sorters").empty(),
        }):find()
      end

      telescope.setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          path_display = filenameFirst,
          layout_strategy = "vertical",
          layout_config = {
            vertical = {
              height = 0.9,
              preview_height = 0.7,
              resolve_height = 0.3,
              prompt_position = "top",
              preview_cutoff = 0,
              width = 0.9
            },
            horizontal = {
              height = 0.9,
              preview_width = 0.7,
              prompt_position = "bottom",
              width = 0.9
            },
          },
          mappings = {
            -- n = {
            --   ["<C-c>"] = actions.close,
            -- },
            i = {
              -- ["<C-c>"] = actions.close,
              ['<C-f>'] = 'to_fuzzy_refine',

              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,

              -- ["<M-k>"] = actions.preview_scrolling_up,
              -- ["<M-j>"] = actions.preview_scrolling_down,
              -- ["<M-h>"] = actions.preview_scrolling_left,
              -- ["<M-l>"] = actions.preview_scrolling_right,

              ["<C-p>"] = actions.results_scrolling_up,
              ["<C-n>"] = actions.results_scrolling_down,
              -- ["<C-h>"] = actions.results_scrolling_left,
              -- ["<C-l>"] = actions.results_scrolling_right,
            },
          },
        },
        pickers = {
          -- find_files = {
          -- 	theme = "ivy"
          -- },
          buffers = {
            mappings = {
              i = { ["<C-x>"] = actions.delete_buffer, desc = { "Telescope [D]elete buffer" } },
              n = { ["<C-x>"] = actions.delete_buffer, desc = { "Telescope [D]elete buffer" } },
            },
          },
        },
        extensions = {
          fzf = {},
          -- ['ui-select'] = {
          --   require('telescope.themes').get_dropdown(),
          -- },
        },
      }

      -- Enable telescope extensions, if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>s', '<nop>', { desc = '[S]earch Telescope' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files[.]' })
      vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch existing [B]uffers' })
      vim.keymap.set("n", "<leader>st", ":TodoTelescope<CR>", { desc = '[S]earch [T]odo marks' })
      vim.keymap.set("n", "<leader>sm", live_multigrep, { desc = '[S]earch [M]ultigrep' })



      vim.keymap.set("n", "<leader>so", function()
        builtin.find_files({ cwd = 'C:/Users/Kemal Yildirim/OneDrive/Dokumanlar/Obsidian' })
      end, { desc = "[S]earch [O]bsidian" })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })

      vim.keymap.set('n', '<leader>sp', function()
        builtin.find_files { cwd = vim.fn.stdpath 'data' .. '/lazy' }
      end, { desc = '[S]earch Neovim [P]lugin files' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>sc', function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        -- p
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[S]earch in [c]urrent buffer' })

      -- Also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
