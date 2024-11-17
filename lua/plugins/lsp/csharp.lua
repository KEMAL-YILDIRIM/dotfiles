local nvim_data_path = vim.fn.stdpath "data"
return {

  {
    'jlcrochet/vim-razor',
    ft = { 'cshtml', 'razor' },
  },

  {
    -- "seblj/roslyn.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dir = "D:/Razor/roslyn.nvim",
    dev = true,
    name = "roslyn",
    ft = "cs",
    opts = {
      exe = {
        "dotnet",
        nvim_data_path .. "/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll",
      },
      filewatching = false,
      broad_search = true,
      settings = {
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
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
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

  {
    -- event = "VeryLazy",
    dir = "D:/Razor/rzls.nvim",
    name = 'rzls',
    dev = true,
  }
}
