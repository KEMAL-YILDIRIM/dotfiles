return {

  --[[ {
    'jlcrochet/vim-razor',
    ft = { 'cshtml', 'razor' },
  }, ]]


  {
    "seblj/roslyn.nvim",
    -- dir = "D:/Razor/roslyn.nvim",
    -- dev = true,
    ft = "cs",
    opts = {},

  },


  {
    "tris203/rzls.nvim",
    -- dir = "D:/Razor/rzls.nvim",
    -- dev = true,
    -- name = "rzls",

    config = function()
      local attach = require 'plugins.lsp.attach'
      local capabilities = require "plugins.lsp.capabilities"
      local nvim_data_path = vim.fn.stdpath "data" .. "\\mason\\packages"

      -- Lsp hint display
      vim.lsp.inlay_hint.enable()

      require('roslyn').setup {
        args = {
          '--logLevel=Information',
          '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
          '--razorSourceGenerator=' ..
          nvim_data_path .. '\\roslyn\\libexec\\Microsoft.CodeAnalysis.Razor.Compiler.dll',
          '--razorDesignTimePath=' ..
          nvim_data_path .. '\\rzls\\libexec\\Targets\\Microsoft.NET.Sdk.Razor.DesignTime.targets',
        },
        filewatching = false,
        broad_search = true,
        exe = {
          "dotnet",
          nvim_data_path .. "\\roslyn\\libexec\\Microsoft.CodeAnalysis.LanguageServer.dll",
        },
        config = {
          handlers = require 'rzls.roslyn_handlers',
          settings = {
            ["csharp|completion"] = {
              dotnet_provide_regex_completions = true,
              dotnet_show_completion_items_from_unimported_namespaces = true,
              dotnet_show_name_completion_suggestions = true,
            },
            ["csharp|inlay_hints"] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,
              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_indexer_parameters = true,
              dotnet_enable_inlay_hints_for_literal_parameters = true,
              dotnet_enable_inlay_hints_for_object_creation_parameters = true,
              dotnet_enable_inlay_hints_for_other_parameters = true,
              dotnet_enable_inlay_hints_for_parameters = true,
              dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            },
            -- ["csharp|code_lens"] = {
            --   dotnet_enable_references_code_lens = true,
            --   dotnet_enable_tests_code_lens = true
            -- },
            -- choose_sln = function(sln)
            --   return vim.iter(sln):find(function(item)
            --     if string.match(item, "*.sln") then
            --       return item
            --     end
            --   end)
            -- end
          }
        },
      }

      require('rzls').setup {
        on_attach = attach,
        capabilities = capabilities,
        path = nvim_data_path .. "\\rzls\\libexec\\rzls.dll",
      }
    end
  },


}
