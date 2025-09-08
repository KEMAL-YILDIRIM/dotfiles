M = {}

-- https://github.com/mfussenegger/nvim-dap/wiki/Cookbook#making-debugging-net-easier
M.build_project = function(csproj_path)
  local cmd = "dotnet build -c Debug " .. csproj_path .. " --nologo -v q"
  local result = "Build: ❗"

  local output = F.cmd(cmd)
  if output ~= nil then
    result = "Build: ✔️ "
  end

  vim.api.nvim_echo({
    { result,        "WarningMsg" },
    { "executed: " .. cmd, "MoreMsg" },
  }, true, {})
end

-- Custom function to build and get test assembly path
M.get_test_assembly_info = function()
  local cwd = vim.fn.getcwd()

  -- Find test project file
  local test_project = vim.fn.globpath(cwd, '**/*Test*.csproj', false, true)[1] or
      vim.fn.globpath(cwd, '**/*Tests.csproj', false, true)[1] or
      vim.fn.globpath(cwd, '**/Test*.csproj', false, true)[1]

  if not test_project then
    vim.notify("No test project found", vim.log.levels.ERROR)
    return nil
  end

  -- Build the project
  local build_result = vim.fn.system('dotnet build "' .. test_project .. '" --nologo -v q')
  if vim.v.shell_error ~= 0 then
    vim.notify("Build failed: " .. build_result, vim.log.levels.ERROR)
    return nil
  end

  -- Parse project file to get target framework and assembly name
  local project_content = vim.fn.readfile(test_project)
  local target_framework = "net8.0" -- default
  local assembly_name = vim.fn.fnamemodify(test_project, ':t:r')

  for _, line in ipairs(project_content) do
    local tf_match = line:match('<TargetFramework>(.-)</TargetFramework>')
    if tf_match then
      target_framework = tf_match
    end
    local an_match = line:match('<AssemblyName>(.-)</AssemblyName>')
    if an_match then
      assembly_name = an_match
    end
  end

  local project_dir = vim.fn.fnamemodify(test_project, ':h')
  local dll_path = project_dir .. '/bin/Debug/' .. target_framework .. '/' .. assembly_name .. '.dll'

  return {
    project_file = test_project,
    project_dir = project_dir,
    dll_path = dll_path,
    assembly_name = assembly_name,
    target_framework = target_framework
  }
end

-- Run all tests
function M.run_all_tests()
  local info = get_test_assembly_info()
  if not info then return end
  
  local cmd = string.format('dotnet test "%s" --logger "console;verbosity=detailed"', info.project_file)
  vim.cmd('split | resize 15 | terminal ' .. cmd)
end

-- Run tests in current file
function M.run_file_tests()
  local info = get_test_assembly_info()
  if not info then return end
  
  local current_file = vim.fn.expand('%:t:r')
  local cmd = string.format('dotnet test "%s" --filter "FullyQualifiedName~%s" --logger "console;verbosity=detailed"', 
                           info.project_file, current_file)
  vim.cmd('split | resize 15 | terminal ' .. cmd)
end

-- Run specific test method
function M.run_test_under_cursor()
  local test_info = find_test_method_under_cursor()
  if not test_info then
    vim.notify("No test method found under cursor", vim.log.levels.WARN)
    return
  end
  
  local info = get_test_assembly_info()
  if not info then return end
  
  local cmd = string.format('dotnet test "%s" --filter "FullyQualifiedName~%s" --logger "console;verbosity=detailed"', 
                           info.project_file, test_info.full_name)
  vim.cmd('split | resize 15 | terminal ' .. cmd)
end

-- Debug specific test method
function M.debug_test_under_cursor()
  local test_info = find_test_method_under_cursor()
  if not test_info then
    vim.notify("No test method found under cursor", vim.log.levels.WARN)
    return
  end
  
  local info = get_test_assembly_info()
  if not info then return end
  
  -- Update DAP configuration dynamically
  local dap = require 'dap'
  dap.configurations.cs[1].args = {
    "test", 
    info.dll_path, 
    "--filter", 
    "FullyQualifiedName=" .. test_info.full_name,
    "--logger", 
    "console;verbosity=detailed"
  }
  dap.configurations.cs[1].cwd = info.project_dir
  dap.configurations.cs[1].name = "Debug: " .. test_info.method_name
  
  -- Start debugging
  dap.run(dap.configurations.cs[1])
end

-- Debug all tests
function M.debug_all_tests()
  dap.run(dap.configurations.cs[2])
end

-- Function to find test method under cursor using treesitter
M.find_test_method_under_cursor = function()
  local ts = vim.treesitter
  local parser = ts.get_parser(0, 'c_sharp')
  if not parser then
    vim.notify("No C# parser available", vim.log.levels.ERROR)
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  cursor_row = cursor_row - 1 -- Convert to 0-based indexing

  -- Query to find test methods
  local query = ts.query.parse('c_sharp', [[
    (method_declaration
      (attribute_list
        (attribute
          name: (identifier) @attr_name (#match? @attr_name "^(Fact|Theory|Test)$")))
      name: (identifier) @method_name) @method
  ]])

  for id, node, metadata in query:iter_captures(root, 0) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()

    if name == "method" and start_row <= cursor_row and cursor_row <= end_row then
      -- Found the method containing the cursor
      local method_name_node = nil
      for child_id, child_node in query:iter_captures(node, 0) do
        if query.captures[child_id] == "method_name" then
          method_name_node = child_node
          break
        end
      end

      if method_name_node then
        local method_name = ts.get_node_text(method_name_node, 0)

        -- Get the full qualified name by finding the class
        local class_node = node:parent()
        while class_node and class_node:type() ~= "class_declaration" do
          class_node = class_node:parent()
        end

        local class_name = "UnknownClass"
        if class_node then
          for child in class_node:iter_children() do
            if child:type() == "identifier" then
              class_name = ts.get_node_text(child, 0)
              break
            end
          end
        end

        -- Get namespace
        local namespace_node = class_node and class_node:parent()
        while namespace_node and namespace_node:type() ~= "namespace_declaration" do
          namespace_node = namespace_node:parent()
        end

        local namespace_name = ""
        if namespace_node then
          for child in namespace_node:iter_children() do
            if child:type() == "qualified_name" or child:type() == "identifier" then
              namespace_name = ts.get_node_text(child, 0) .. "."
              break
            end
          end
        end

        return {
          method_name = method_name,
          class_name = class_name,
          full_name = namespace_name .. class_name .. "." .. method_name
        }
      end
    end
  end

  return nil
end
return M
