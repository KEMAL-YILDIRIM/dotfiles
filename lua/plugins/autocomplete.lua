return {
  {
    'L3MON4D3/LuaSnip',
    version = "v2.3.0",
    dependencies = { 'molleweide/LuaSnip-snippets.nvim' },
    build = 'make install_jsregexp CC=gcc.exe SHELL=C:/path/to/sh.exe .SHELLFLAGS=-c',
    config = function()
      local ls = require("luasnip")
      vim.snippet.expand = ls.lsp_expand

      ---@diagnostic disable-next-line: duplicate-set-field
      vim.snippet.active = function(filter)
        filter = filter or {}
        filter.direction = filter.direction or 1

        if filter.direction == 1 then
          return ls.expand_or_jumpable()
        else
          return ls.jumpable(filter.direction)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      vim.snippet.jump = function(direction)
        if direction == 1 then
          if ls.expandable() then
            return ls.expand_or_jump()
          else
            return ls.jumpable(1) and ls.jump(1)
          end
        else
          return ls.jumpable(-1) and ls.jump(-1)
        end
      end

      vim.snippet.stop = ls.unlink_current


      ls.config.set_config {
        history = true,
        updateevents = "TextChanged,TextChangedI",
        override_builtin = true,
      }

      for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/custom/*.lua", true)) do
        loadfile(ft_path)()
      end

      vim.keymap.set({ "i", "s" }, "<c-l>", function()
        return vim.snippet.active { direction = 1 } and vim.snippet.jump(1)
      end, { silent = true })

      vim.keymap.set({ "i", "s" }, "<c-h>", function()
        return vim.snippet.active { direction = -1 } and vim.snippet.jump(-1)
      end, { silent = true })

      ls.setup({
        snip_env = {
          s = function(...)
            local snip = ls.s(...)
            -- we can't just access the global `ls_file_snippets`, since it will be
            -- resolved in the environment of the scope in which it was defined.
            table.insert(getfenv(2).ls_file_snippets, snip)
          end,
          parse = function(...)
            local snip = ls.parser.parse_snippet(...)
            table.insert(getfenv(2).ls_file_snippets, snip)
          end,
          -- remaining definitions.
        },
      })

      require("luasnip.loaders.from_vscode").lazy_load()
    end
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {

      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',

      'neovim/nvim-lspconfig',
      'saadparwaiz1/cmp_luasnip',

    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'

      cmp.setup {
        snippet = {
          expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },
        formatting = {
          format = require('lspkind').cmp_format({
            symbol_map = { Codeium = "", },
            mode = "symbol_text",
            menu = {
              nvim_lsp = "[LSP]",
              buffer = "[Buffer]",
              luasnip = "[Luasnip]",
              path = "[Path]",
              crates = "[Crates]",
            },
            maxwidth = 90,
            ellipsis_char = "...",
          })
        },
        -- For an understanding of why these keymaps were
        -- chosen, you will need to read `:help ins-completion`
        mapping = {
          ['<c-space>'] = cmp.mapping.open_docs(),
          ['<c-b>'] = cmp.mapping.scroll_docs(-4),
          ['<c-f>'] = cmp.mapping.scroll_docs(4),
          ['<c-j>'] = cmp.mapping.select_next_item(),
          ['<c-k>'] = cmp.mapping.select_prev_item(),
          ['<c-x>'] = cmp.mapping.close(),
          ['<Tab>'] = cmp.mapping.confirm { select = true },
          --[[ ['<c-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<c-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }) ]]
        },
        sources = {
          { name = 'codeium' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        },
      }


      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = {
          ['<c-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
          ['<c-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' }),
          ['<Tab>'] = cmp.mapping(cmp.mapping.confirm { select = true, behavior = cmp.ConfirmBehavior.Replace }, { 'c' }),
        },
        sources = cmp.config.sources(
          { { name = 'path' } },
          { { name = 'cmdline' } }),
      })



      -- Setup up vim-dadbod
      cmp.setup.filetype({ "sql" }, {
        sources = {
          { name = "vim-dadbod-completion" },
          { name = "buffer" },
        },
      })
    end,
  },
  {
    -- Autoclose parentheses, brackets, quotes, etc.
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    opts = {},
  },
}
-- vim: ts=2 sts=2 sw=2 et
