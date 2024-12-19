vim.opt.rtp:append("D:/Razor/nvim.razorls")
vim.opt.rtp:append("D:/Razor/rzls.nvim")
vim.opt.rtp:append("D:/Razor/roslyn.nvim")
vim.api.nvim_create_user_command("Test", function()
	package.loaded.razorls = nil
	require("razorls").test()
end, { desc = "Lsp test" })

return {

  {
    'jlcrochet/vim-razor',
		enabled = false,
    ft = { 'cshtml', 'razor' },
  },


  {
    -- "seblj/roslyn.nvim",
    dir = "D:/Nvim/roslyn.nvim",
    name = "roslyn",
    dev = true,
    -- ft = "cs",
    opts = {},

  },


  {
    -- "tris203/rzls.nvim",
    dir = "D:/Nvim/rzls.nvim",
    dev = true,
    name = "rzls",

    config = function()
      local attach = require 'plugins.lsp.attach'
      local capabilities = require "plugins.lsp.capabilities"
      local nvim_data_path = string.gsub(vim.fn.stdpath "data" .. "/mason/packages", "\\", "/")

      -- Lsp hint display
      -- vim.lsp.inlay_hint.enable()

      require('roslyn').setup {
        args = {
          '--logLevel=Information',
          '--extensionLogDirectory=' .. string.gsub(vim.fs.dirname(vim.lsp.get_log_path()),"\\","/"),
          '--razorSourceGenerator=' ..
          nvim_data_path .. '/roslyn/libexec/Microsoft.CodeAnalysis.Razor.Compiler.dll',
          '--razorDesignTimePath=' ..
          nvim_data_path .. '/rzls/libexec/Targets/Microsoft.NET.Sdk.Razor.DesignTime.targets',
        },
        filewatching = false,
        -- broad_search = true,
        exe = {
          "dotnet",
          nvim_data_path .. "/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll",
        },
        config = {
          handlers = require 'rzls.roslyn_handlers',
        },
      }

      require('rzls').setup {
        on_attach = attach,
        capabilities = capabilities,
        -- path = nvim_data_path .. "/rzls/libexec/rzls.exe",
      }
    end
  },


}
