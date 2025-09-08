local M = {
  -- Debug specific test (will be configured dynamically)
  {
    type = "coreclr",
    name = "Debug Specific Test",
    request = "launch",
    program = "dotnet",
    args = {}, -- Will be set dynamically
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    console = "integratedTerminal",
  },
  {
    type = "coreclr",
    name = "Debug All Tests",
    request = "launch",
    program = "dotnet",
    args = function()
      local info = require 'plugins.debug.utils'.get_test_assembly_info()
      if not info then return {} end
      return { "test", info.dll_path, "--logger", "console;verbosity=detailed" }
    end,
    cwd = function()
      local info = require 'plugins.debug.utils'.get_test_assembly_info()
      return info and info.project_dir or vim.fn.getcwd()
    end,
    stopOnEntry = false,
    console = "integratedTerminal",
  },
  {
    type = "coreclr",
    name = "launch - netcoredbg",
    request = "launch",
    program = function()
      -- path
      local current_dir = vim.fn.expand("%:p:h") -- Get the current buffer's directory
      local project_path = F.find_csproj_file(current_dir)
      if not project_path then
        vim.notify("Couldn't find the csproj path")
        return nil
      end

      -- pick
      require "plugins.debug.utils".build_project(project_path)
      local filter = string.format("Debug/.*/%s",
        vim.fn.fnamemodify(project_path, ":t:r"))
      local bin_path = string.format("%s/bin", vim.fn.fnamemodify(project_path, ":h"))
      vim.notify("Project path: " .. project_path)
      local selected = require("dap.utils").pick_file({
        filter      = filter,
        executables = false,
        path        = bin_path,
      })

      -- output message
      local info = {
        { " filter: " .. filter, "MoreMsg" },
        { " path: " .. bin_path, "MoreMsg" }
      }
      if type(selected) ~= type("v:t_string") then
        vim.notify("Invalid project name! " .. project_path)
        return nil
      end

      table.insert(info, 1,
        { " selected: " .. selected, "WarningMsg" })
      vim.fn.chdir(vim.fn.fnamemodify(selected, ":h")) -- important for setting debug path
      vim.api.nvim_echo(info, true, {})

      return selected
    end,
  },
  {
    type = "coreclr",
    name = "attach .NET",
    request = "attach",
    processId = require("dap.utils").pick_process,
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
  {
    type = "coreclr",
    name = "Attach (Smart)",
    request = "attach",
    processId = function()
      if not vim.g.roslyn_nvim_selected_solution then
        return vim.notify("No solution file found")
      end

      local solution_dir = vim.fs.dirname(vim.g.roslyn_nvim_selected_solution)

      local res = vim.system({ "dotnet", "sln", vim.g.roslyn_nvim_selected_solution, "list" }):wait()
      local csproj_files = vim.iter(vim.split(res.stdout, "\n"))
          :map(function(it)
            local fullpath = vim.fs.normalize(vim.fs.joinpath(
              solution_dir, it))
            if fullpath ~= solution_dir and vim.uv.fs_stat(fullpath) then
              return fullpath
            else
              return nil
            end
          end)
          :totable()

      return require("dap.utils").pick_process({
        filter = function(proc)
          return vim.iter(csproj_files):find(function(file)
            if vim.endswith(proc.name, vim.fn.fnamemodify(file, ":t:r")) then
              return true
            end
          end)
        end,
      })
    end,
  },
}
return M
