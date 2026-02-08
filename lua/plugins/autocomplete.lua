return {
  { -- LuaSnip
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    enabled = true,
    lazy = true,
    dependencies = { 'molleweide/LuaSnip-snippets.nvim' },
    -- build = 'make install_jsregexp CC=gcc.exe SHELL=C:/path/to/sh.exe .SHELLFLAGS=-c',
    build = 'make install_jsregexp CC=gcc',
    config = function()
      local ls = require 'luasnip'
      vim.snippet.expand = ls.lsp_expand

      ---@diagnostic disable-next-line: duplicate-set-field
      vim.snippet.active = function(filter)
        filter = filter or { direction = 1 }

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
        updateevents = 'TextChanged,TextChangedI',
        override_builtin = true,
      }

      for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/snippets/*.lua', true)) do
        loadfile(ft_path)()
      end

      vim.keymap.set({ 'i', 's' }, '<C-l>', function()
        return vim.snippet.active { direction = 1 } and vim.snippet.jump(1)
      end, { silent = true })

      vim.keymap.set({ 'i', 's' }, '<C-h>', function()
        return vim.snippet.active { direction = -1 } and vim.snippet.jump(-1)
      end, { silent = true })

      ls.setup {
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
      }

      require('luasnip.loaders.from_vscode').lazy_load()
    end,
  },
  { -- Autocompletion Blink
    'saghen/blink.cmp',
    dependencies = {
      { 'saghen/blink.compat', lazy = true, verson = false },
    },
    version = '1.*',
    enabled = true,
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'none',

        ['K'] = { 'show_signature', 'hide_signature', 'fallback' },
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-c>'] = {
          function(cmp)
            if cmp.is_visible() then
              cmp.hide()
              -- Defer the mode change to let blink finish cleanup
              vim.defer_fn(function()
                vim.cmd 'stopinsert'
              end, 0)
            else
              vim.cmd 'stopinsert'
            end
          end,
          'fallback',
        },
        ['<Tab>'] = { 'select_and_accept', 'fallback' },

        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },

        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },

        ['<C-l>'] = { 'snippet_forward', 'fallback' },
        ['<C-h>'] = { 'snippet_backward', 'fallback' },
      },

      completion = {
        menu = {
          border = 'rounded',
          draw = {
            columns = {
              { 'kind_icon' },
              { 'label', 'label_description', gap = 1 },
              { 'kind' },
              { 'source_name' },
            },
          },
        },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      fuzzy = {
        sorts = {
          'exact',
          'score',
          'sort_text',
        },
      },

      cmdline = {
        keymap = { preset = 'inherit' },
        completion = { menu = { auto_show = true } },
      },

      snippets = { preset = 'luasnip' },

      sources = {
        default = { 'lsp', 'snippets', 'buffer', 'path', 'obsidian', 'obsidian_new', 'obsidian_tags' },
        per_filetype = {
          sql = { 'dadbod', 'buffer' },
        },
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
          dadbod = { module = 'vim_dadbod_completion.blink' },
          obsidian = { name = 'obsidian', module = 'blink.compat.source' },
          obsidian_new = { name = 'obsidian_new', module = 'blink.compat.source' },
          obsidian_tags = { name = 'obsidian_tags', module = 'blink.compat.source' },
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
