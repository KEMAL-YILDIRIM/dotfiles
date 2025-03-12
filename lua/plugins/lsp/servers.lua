
local servers = {
  lemminx = {},
  stylua = {},
  ts_ls = {},
  pyright = {},
  rust_analyzer = {},
  lua_ls = {
  --   settings = {
  --     Lua = {
  --       runtime = { version = 'LuaJIT' },
  --       workspace = {
  --         checkThirdParty = false,
  --         library = {
  --           '${3rd}/luv/library',
  --           unpack(vim.api.nvim_get_runtime_file('', true)),
  --         },
  --       },
  --       completion = {
  --         callSnippet = 'Replace',
  --       },
  --       diagnostics = {
  --         globals = { "vim" },
  --         disable = { 'missing-fields' }
  --       },
  --     },
  --   },
  },
}
return servers
