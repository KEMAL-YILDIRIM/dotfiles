local nvim_data_path = vim.fn.stdpath "data"
return {

  -- {
  --   'jlcrochet/vim-razor',
  --   ft = { 'cshtml', 'razor' },
  -- },


  -- {
  --   dir = "D:/Razor/rzls.nvim",
  --   dev = true,
  --   name = "rzls",
  --   config = function ()
  --
  --     require('roslyn').setup {
  --       args = {
  --         '--logLevel=Information',
  --         '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
  --         '--razorSourceGenerator=' ..
  --         nvim_data_path .. '/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.Razor.Compiler.dll',
  --         '--razorDesignTimePath=' ..
  --         nvim_data_path .. '/mason/packages/rzls/libexec/Targets/Microsoft.NET.Sdk.Razor.DesignTime.targets',
  --       },
  --       config = {
  --         on_attach = lsp_attach,
  --         capabilities = capabilities,
  --         handlers = require 'rzls.roslyn_handlers'
  --       }
  --     }
  --
  --
  --     require('rzls').setup {
  --       on_attach = lsp_attach,
  --       capabilities = capabilities,
  --     }
  --   end
  -- },


  {
    "seblj/roslyn.nvim",
    -- dir = "D:/Razor/roslyn.nvim",
    -- dev = true,
    ft = "cs",
    opts = {
      -- exe = {
      --   "dotnet",
      --   nvim_data_path .. "/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll",
      -- },
      filewatching = false,
      -- broad_search = true,
      settings = {
        -- ["csharp|background_analysis"] = {
        --   dotnet_analyzer_diagnostics_scope = "openFiles",
        --   dotnet_compiler_diagnostics_scope = "openFiles",
        -- },
        -- ["csharp|completion"] = {
        --   dotnet_provide_regex_completions = true,
        --   dotnet_show_completion_items_from_unimported_namespaces = true,
        --   dotnet_show_name_completion_suggestions = true,
        -- },
        -- ["csharp|inlay_hints"] = {
        --   csharp_enable_inlay_hints_for_implicit_object_creation = true,
        --   csharp_enable_inlay_hints_for_implicit_variable_types = true,
        --   csharp_enable_inlay_hints_for_lambda_parameter_types = true,
        --   csharp_enable_inlay_hints_for_types = true,
        --   dotnet_enable_inlay_hints_for_indexer_parameters = true,
        --   dotnet_enable_inlay_hints_for_literal_parameters = true,
        --   dotnet_enable_inlay_hints_for_object_creation_parameters = true,
        --   dotnet_enable_inlay_hints_for_other_parameters = true,
        --   dotnet_enable_inlay_hints_for_parameters = true,
        --   dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
        --   dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
        --   dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        -- },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
          dotnet_enable_tests_code_lens = true
        },
        choose_sln = function(sln)
          return vim.iter(sln):find(function(item)
            if string.match(item, "*.sln") then
              return item
            end
          end)
        end
      },
    },
  },
}
