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

      -- NOTE: vim.snippet.* overrides removed — blink.cmp handles the LuaSnip
      -- bridge via `snippets = { preset = 'luasnip' }` and monkey-patching
      -- vim.snippet conflicts with blink's internal wiring.

      ls.config.set_config {
        history = true,
        updateevents = 'TextChanged,TextChangedI',
        override_builtin = true,
      }

      for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/snippets/*.lua', true)) do
        loadfile(ft_path)()
      end

      -- TODO: decide whether to keep these or rely solely on blink's <C-l>/<C-h>
      -- snippet_forward / snippet_backward bindings (they do the same thing).
      -- vim.keymap.set({ 'i', 's' }, '<C-l>', function()
      --   return ls.expand_or_jumpable() and ls.expand_or_jump()
      -- end, { silent = true })
      -- vim.keymap.set({ 'i', 's' }, '<C-h>', function()
      --   return ls.jumpable(-1) and ls.jump(-1)
      -- end, { silent = true })

      -- NOTE: ls.setup { snip_env = ... } block removed — it used getfenv(2)
      -- which is a fragile Lua 5.1-ism. Our snippet files (cs.lua, lua.lua,
      -- js.lua) all use ls.add_snippets() directly and don't rely on snip_env.

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
