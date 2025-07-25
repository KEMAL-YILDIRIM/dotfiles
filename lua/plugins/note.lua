local baseWorkPath = "~/OneDrive/Dokumanlar/Obsidian"

return {
  { "nanotee/luv-vimdocs",  lazy = true },
  { "LunarVim/bigfile.nvim" },
  { "milisims/nvim-luaref", lazy = true },
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local keymaps = function()
        -- Obsidian
        vim.keymap.set("n", "<leader>oc", "<cmd>lua require('obsidian').util.toggle_checkbox()<CR>",
          { desc = "Obsidian Check Checkbox" })
        vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>", { desc = "Insert Obsidian Template" })
        vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<CR>", { desc = "Open in Obsidian App" })
        vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Show ObsidianBacklinks" })
        vim.keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>", { desc = "Show ObsidianLinks" })
        vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "Create New Note" })
        vim.keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick Switch" })
      end

      local options = {
        workspaces = {
          {
            name = "personal",
            path = baseWorkPath .. "/personal",
          },
          {
            name = "work",
            path = baseWorkPath .. "/work",
          },
        },

        completion = {
          nvim_cmp = true,
          min_chars = 2,
        },

        new_notes_location = "current_dir",

        wiki_link_func = function(opts)
          if opts.id == nil then
            return string.format("[[%s]]", opts.label)
          elseif opts.label ~= opts.id then
            return string.format("[[%s|%s]]", opts.id, opts.label)
          else
            return string.format("[[%s]]", opts.id)
          end
        end,

        mappings = {
          -- "Obsidian follow"
          ["<leader>op"] = {
            action = function()
              return require("obsidian").util.gf_passthrough()
            end,
            opts = { noremap = false, expr = true, buffer = true },
          },
        },

        note_frontmatter_func = function(note)
          -- This is equivalent to the default frontmatter function.
          local out = { id = note.id, aliases = note.aliases, tags = note.tags, area = "", project = "" }

          -- `note.metadata` contains any manually added fields in the frontmatter.
          -- So here we just make sure those fields are kept in the frontmatter.
          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end
          return out
        end,

        note_id_func = function(title)
          -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
          -- In this case a note with the title 'My new note' will be given an ID that looks
          -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
          local suffix = ""
          if title ~= nil then
            -- If title is given, transform it into valid file name.
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          else
            -- If title is nil, just add 4 random uppercase letters to the suffix.
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.time()) .. "-" .. suffix
        end,

        templates = {
          subdir = "templates",
          date_format = "%Y-%m-%d-%a",
          time_format = "%H:%M",
          tags = "",
        },
      }

      local obsidian = require("obsidian")
      obsidian.setup(options)

      keymaps()
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    lazy = true,     -- Recommended
    ft = "markdown", -- If you decide to lazy-load anyway

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      vim.keymap.set('n', '<leader>om', '<CMD>Markview splitToggle<CR>', { desc = "[M]arkdown Split and Toggle" })
    end
  }
}
