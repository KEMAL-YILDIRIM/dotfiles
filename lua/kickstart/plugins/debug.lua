return {
  {
    -- NOTE: Yes, you can install new plugins here!
    'mfussenegger/nvim-dap',
    -- NOTE: And you can specify dependencies as well
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio'

      -- Installs the debug adapters for you
      -- 'williamboman/mason.nvim',
      -- 'jay-babu/mason-nvim-dap.nvim',

      -- Add your own debuggers here

    },    
    config = function()

      local getprojpath = function()
        local default_path = vim.fn.expand('%:p') .. '\\'

        if vim.g['dotnet_last_proj_path'] ~= nil then
          default_path = vim.g['dotnet_last_proj_path']
        end

        vim.g['dotnet_last_proj_path'] = vim.fn.input('Input your *cs.proj folder path | ', default_path, 'file')
        return vim.g['dotnet_last_proj_path']
      end

      vim.g.dotnet_build_project = function()

        local path = getprojpath()
        -- local cmd = 'dotnet build -c debug ' .. path .. ' > /dev/null'
        local cmd = 'dotnet build -c debug ' .. path
        print('')
        print('cmd to execute: ' .. cmd)
        local f = os.execute(cmd)
        if f == 0 then
          print('\nbuild: ✔️ ')
        else
          print('\nbuild: ❌ (code: ' .. f .. ')')
        end
      end

      vim.g.dotnet_get_dll_path = function()

        if vim.g['dotnet_last_proj_path'] == nil then
          print('\nroot cs.proj path missing')
          vim.g['dotnet_last_proj_path'] = getprojpath()
        end

        local request = function()
          return vim.fn.input('input your project dll file path | ', vim.g['dotnet_last_proj_path'] .. 'bin\\debug\\', 'file')
        end

        if vim.g['dotnet_last_dll_path'] == nil then
          vim.g['dotnet_last_dll_path'] = request()
        else
          if vim.fn.confirm('would you like to change your dll file path?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
            vim.g['dotnet_last_dll_path'] = request()
          end
        end

        return vim.g['dotnet_last_dll_path']
      end
      -- require('mason-nvim-dap').setup { ensure_installed = { "coreclr" }}

      local dap = require 'dap'

      dap.adapters.coreclr = {
        type = 'executable',
        command = "C:/Users/Kemal Yildirim/AppData/Local/nvim-data/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe",
        args = {'--interpreter=vscode'}
      }


      local config = {
        {
          type = "coreclr",
          name = "launch albert qa",
          request = "launch",
          env = {
            ASPNETCORE_ENVIRONMENT = "Development",
            ASPNETCORE_URLS = "http://localhost:5050",
          }, 
          program = function()
            if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
              vim.g.dotnet_build_project()
            end
            return vim.g.dotnet_get_dll_path()
          end,
        },
        {
          type = "coreclr",
          name = "attach albert",
          request = "attach",
          processId = require('dap.utils').pick_process,
          program = function ()
            vim.g.dotnet_get_dll_path()
          end,
        },
      }
      dap.configurations.cs = config



      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      local dapui = require 'dapui'
      dapui.setup {
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
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

      -- Basic debugging keymaps, feel free to change to your liking!
      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<F12>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<S-F11>', dap.step_out, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<F9>', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
      vim.keymap.set('n', '<S-F9>', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Debug: Set Breakpoint' })

      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })


      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close


    end,
  },
}
