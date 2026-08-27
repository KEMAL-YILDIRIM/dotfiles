return {
  {
    'oysandvik94/curl.nvim',
    cmd = { 'CurlOpen' },
  },
  {
    'mistweaverco/kulala.nvim',
    ft = { 'http', 'rest' },
    -- kulala ships its own lazy.lua that adds `event = { 'SessionLoadPost', 'VimLeavePre' }`.
    -- lazy merges that in, so the plugin gets loaded *at exit*. Loading runs setup(), which
    -- calls Backend.ensure_installed() and downloads the ~118MB kulala-core binary whenever the
    -- installed version is stale (e.g. right after a kulala update) -- a multi-second hang on
    -- every :q. Giving `event` as a function overrides (rather than concatenates) the merged
    -- list, so kulala loads only on the http/rest filetype, when it's actually used.
    event = function()
      return {}
    end,
    opts = {
      global_keymaps = true,
      global_keymaps_prefix = '<leader>r',
      ft = { 'http', 'rest' },
    },
  },
}
