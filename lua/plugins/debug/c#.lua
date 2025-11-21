local dap = require("dap")

local netcoredbg_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"),
  "mason/packages/netcoredbg/netcoredbg/netcoredbg.exe"))
local netcoredbg_adapter = {
  type = "executable",
  command = netcoredbg_path,
  args = { "--interpreter=vscode" },
}
dap.adapters.coreclr = netcoredbg_adapter
dap.adapters.netcoredbg = netcoredbg_adapter

dap.configurations.cs = {
  -- Debug specific test (configured dynamically via F.debug_test_under_cursor)
  {
    type = "coreclr",
    name = "Debug Test",
    request = "launch",
    program = "dotnet",
    args = {}, -- Will be set dynamically
    cwd = "${workspaceFolder}",
    stopAtEntry = false,
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
      F.build_project(project_path)
      local filename = vim.fn.fnamemodify(project_path, ":t:r") .. ".dll"
      local debug_path = string.format("%s/bin/Debug/.*/", vim.fn.fnamemodify(project_path, ":h"))
      local dll = vim.fn.findfile(filename, debug_path, 1)
      vim.notify("debug dll -> " .. dll)
      return dll
    end,
  },
  {
    type = "coreclr",
    name = "attach - netcoredbg",
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
return {}
