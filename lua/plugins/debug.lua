return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      -- creates a beautiful debugger ui
      'rcarriga/nvim-dap-ui',

      -- display text as you step throughout the code
      'theHamsta/nvim-dap-virtual-text',

      -- you can install the debug adapters with 'williamboman/mason.nvim',
      -- to auto include some debug predefined configs 'jay-babu/mason-nvim-dap.nvim',

      -- lua debug
      'jbyuki/one-small-step-for-vimkind',

      -- async io operations
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local dap, daputils = require("dap"), require("dap.utils")


      -- https://github.com/mfussenegger/nvim-dap/wiki/Cookbook#making-debugging-net-easier
      vim.g.dotnet_build_project = function()
        local default_path = vim.fn.getcwd() .. "/"
        if vim.g["dotnet_last_proj_path"] ~= nil then
          default_path = vim.g["dotnet_last_proj_path"]
        end
        local path = vim.fn.input("Path to your *proj file", default_path, "file")
        vim.g["dotnet_last_proj_path"] = path
        local cmd = "dotnet build -c Debug " .. path .. " > /dev/null"
        print("")
        print("Cmd to execute: " .. cmd)
        local f = os.execute(cmd)
        if f == 0 then
          print("\nBuild: ✔️ ")
        else
          print("\nBuild: ❌ (code: " .. f .. ")")
        end
      end

      vim.g.dotnet_get_dll_path = function()
        local request = function()
          return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file")
        end

        if vim.g["dotnet_last_dll_path"] == nil then
          vim.g["dotnet_last_dll_path"] = request()
        else
          if
              vim.fn.confirm(
                "Do you want to change the path to dll?\n" .. vim.g["dotnet_last_dll_path"],
                "&yes\n&no",
                2
              ) == 1
          then
            vim.g["dotnet_last_dll_path"] = request()
          end
        end

        return vim.g["dotnet_last_dll_path"]
      end


      require("mason").setup()
      local mason_registry = require('mason-registry')
      local package = mason_registry.get_package("netcoredbg")

      if not package:is_installed() then
        package:install()
      end

      local path = string.gsub(package:get_install_path(), "\\", "/") .. "/netcoredbg/netcoredbg.exe"

      -- C# / .NET
      dap.adapters.coreclr = {
        type = "executable",
        -- command = '/usr/local/netcoredbg',
        -- command = "netcoredbg",
        command = path,
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "launch .NET",
          request = "launch",
          program = function()
            if vim.fn.confirm("Should I recompile first?", "&yes\n&no", 2) == 1 then
              vim.g.dotnet_build_project()
            end
            return vim.g.dotnet_get_dll_path()
          end,
        },
        {
          type = "coreclr",
          name = "attach .NET",
          request = "attach",
          processId = daputils.pick_process,
        },
        {
          type = "coreclr",
          name = "attach to Azure Function",
          request = "attach",
          processId = function()
            local pid = nil
            while not pid do
              pid = require("azure-functions").get_process_id()
            end
            return pid
          end,
        },
      }


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

      require('nvim-dap-virtual-text').setup()
      -- dap ui setup for more information, see |:help nvim-dap-ui|
      local dapui = require 'dapui'
      dapui.setup {}
      -- dap.set_log_level("DEBUG")

      -- basic debugging keymaps, feel free to change to your liking!
      vim.keymap.set('n', '<f5>', dap.continue, { desc = 'debug: start/continue' })
      vim.keymap.set('n', '<f11>', dap.step_into, { desc = 'debug: step into' })
      vim.keymap.set('n', '<f10>', dap.step_over, { desc = 'debug: step over' })
      vim.keymap.set('n', '<s-f10>', dap.step_back, { desc = 'debug: step over' })
      vim.keymap.set('n', '<s-f11>', dap.step_out, { desc = 'debug: step out' })
      vim.keymap.set('n', '<f9>', dap.toggle_breakpoint, { desc = 'debug: toggle breakpoint' })
      vim.keymap.set('n', '<s-f9>', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
        { desc = 'debug: conditional breakpoint' })
      vim.keymap.set('n', '<f12>', dapui.toggle, { desc = 'debug: see last session result.' })

      -- Eval var under cursor
      vim.keymap.set("n", "<s-f12>", function()
        require("dapui").eval(nil, { enter = true })
      end)



      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
    end,
  },
}
