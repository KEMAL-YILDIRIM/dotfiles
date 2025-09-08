return {
  {
    'mfussenegger/nvim-dap',
    lazy = true,
    dependencies = {
      -- creates a beautiful debugger ui
      'rcarriga/nvim-dap-ui',
      -- display text as you step throughout the code
      'theHamsta/nvim-dap-virtual-text',
      -- lua debug
      'jbyuki/one-small-step-for-vimkind',
      -- async io operations
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local dap = require("dap")

      require("mason").setup()
      local mason_registry = require('mason-registry')
      local package = mason_registry.get_package("netcoredbg")

      if not package:is_installed() then
        package:install()
      end

      local netcoredbg_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "mason/packages/netcoredbg/netcoredbg/netcoredbg.exe"))
      -- C# / .NET
      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = require "plugins.debug.c#-congfig"
      dap.configurations.lua = {
        {
          type = 'nlua',
          request = 'attach',
          name = "Attach to running Neovim instance",
        }
      }

      dap.adapters.nlua = function(callback, config)
        callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
      end

      vim.fn.sign_define('DapBreakpoint',
        { text = '●', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })

      require('nvim-dap-virtual-text').setup(nil)
      dap.set_log_level("TRACE")
      require "plugins.debug.keymap".set()

      -- dap ui setup for more information, see |:help nvim-dap-ui|
      local dapui = require 'dapui'
      dapui.setup()
      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
    end,
  },
}
