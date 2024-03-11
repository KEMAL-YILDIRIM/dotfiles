return {
  {
    -- NOTE: Yes, you can install new plugins here!
    'mfussenegger/nvim-dap',
    -- NOTE: And you can specify dependencies as well
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',

      -- Installs the debug adapters for you
      -- 'williamboman/mason.nvim',
      -- 'jay-babu/mason-nvim-dap.nvim',

      -- Add your own debuggers here
          
    },    
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      -- require('mason-nvim-dap').setup { ensure_installed = { "coreclr" }}

    
      local netcoredbgPath = vim.fn.exepath('netcoredbg')
      dap.adapters.coreclr = {
        type = 'executable',
        command = "C:/Users/Kemal Yildirim/AppData/Local/nvim-data/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe",
        args = {'--interpreter=vscode'}
      }
      
      vim.g.dotnet_build_project = function()
        local default_path = vim.fn.getcwd() .. '/'
        if vim.g['dotnet_last_proj_path'] ~= nil then
            default_path = vim.g['dotnet_last_proj_path']
        end
        local path = vim.fn.input('Path to your *proj file', default_path, 'file')
        vim.g['dotnet_last_proj_path'] = path
        local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
        print('')
        print('Cmd to execute: ' .. cmd)
        local f = os.execute(cmd)
        if f == 0 then
            print('\nBuild: ✔️ ')
        else
            print('\nBuild: ❌ (code: ' .. f .. ')')
        end
      end
    
      vim.g.dotnet_get_dll_path = function()
        local request = function()
            return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
        end
    
        if vim.g['dotnet_last_dll_path'] == nil then
            vim.g['dotnet_last_dll_path'] = request()
        else
            if vim.fn.confirm('Do you want to change the path to dll?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
                vim.g['dotnet_last_dll_path'] = request()
            end
        end
    
        return vim.g['dotnet_last_dll_path']
      end
    
      local config = {
          {
            type = "coreclr",
            name = "launch - netcoredbg",
            request = "launch",
            program = function()
                if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
                    vim.g.dotnet_build_project()
                end
                return vim.g.dotnet_get_dll_path()
            end,
          },
      }
      dap.configurations.cs = config

      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
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
