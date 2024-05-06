return {
  {
    -- note: yes, you can install new plugins here!
    'mfussenegger/nvim-dap',
    -- note: and you can specify dependencies as well
    dependencies = {
      -- creates a beautiful debugger ui
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',

      -- installs the debug adapters for you
      'williamboman/mason.nvim',
      --'jay-babu/mason-nvim-dap.nvim',

      -- add your own debuggers here

    },
    config = function()

      local dap, daputils = require("dap"), require("dap.utils")

      -- dap.set_log_level("DEBUG")

      -- C# / .NET
      dap.adapters.coreclr = {
        type = "executable",
        -- command = '/usr/local/netcoredbg',
        command = "netcoredbg",
        args = { "--interpreter=vscode" },
      }

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
      dap.adapters.coreclr = {
        type = 'executable',
        command = path,
        args = { '--interpreter=vscode' }
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



      vim.fn.sign_define('DapBreakpoint',
        { text = '🔴', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })


      -- dap ui setup
      -- for more information, see |:help nvim-dap-ui|
      local dapui = require 'dapui'
      dapui.setup {
        -- set icons to characters that are more likely to work in every terminal.
        --    feel free to remove or use ones that you like more! :)
        --    don't feel like these are good choices.
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      }

      -- basic debugging keymaps, feel free to change to your liking!
      vim.keymap.set('n', '<f5>', dap.continue, { desc = 'debug: start/continue' })
      vim.keymap.set('n', '<f11>', dap.step_into, { desc = 'debug: step into' })
      vim.keymap.set('n', '<f10>', dap.step_over, { desc = 'debug: step over' })
      vim.keymap.set('n', '<s-f11>', dap.step_out, { desc = 'debug: step out' })
      vim.keymap.set('n', '<f9>', dap.toggle_breakpoint, { desc = 'debug: toggle breakpoint' })
      vim.keymap.set('n', '<s-f9>', function()
        dap.set_breakpoint(vim.fn.input 'breakpoint condition: ')
      end, { desc = 'debug: set breakpoint' })


      -- toggle to see last session result. without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', '<f7>', dapui.toggle, { desc = 'debug: see last session result.' })


      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
    end,
  },
}
