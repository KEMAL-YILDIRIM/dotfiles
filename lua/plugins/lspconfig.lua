local capabilities = vim.lsp.protocol.make_client_capabilities()
local servers = {
  lemminx = {},
  stylua = {},
  ts_ls = {},
  pyright = {},
  rust_analyzer = {},



  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = {
          checkThirdParty = false,
          library = {
            '${3rd}/luv/library',
            unpack(vim.api.nvim_get_runtime_file('', true)),
          },
        },
        completion = {
          callSnippet = 'Replace',
        },
        diagnostics = {
          globals = { "vim" },
          disable = { 'missing-fields' }
        },
      },
    },
  },
}


return {

  {
    "seblj/roslyn.nvim",
    event = { "bufreadpre", "bufnewfile" },
    ft = "cs",
    opts = {
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
    }
  },

  {
    'williamboman/mason.nvim',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
        PATH = "prepend", -- "skip" seems to cause the spawning error
      })

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'jsonls',
        'prettier', -- prettier formatter
        'stylua',   -- lua formatter
        'powershell_es',
        'css-lsp',
        'html-lsp',
        "pyright",
        "typescript-language-server",
        "tailwindcss-language-server",
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      local lsp = vim.lsp
      local api = vim.api

      api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          vim.keymap.set('n', '<leader>l', '<NOP>', { desc = '[L]SP' })
          --  To jump back, press <C-T>.
          map('<leader>ld', require('telescope.builtin').lsp_definitions, 'Goto [D]efinition')
          map('<leader>lf', require('telescope.builtin').lsp_references, 'Goto Re[F]erences')
          map('<leader>li', require('telescope.builtin').lsp_implementations, 'Goto [I]mplementation')
          map('<leader>lt', require('telescope.builtin').lsp_type_definitions, '[T]ype Definition')
          map('<leader>ls', require('telescope.builtin').lsp_document_symbols, 'Document [S]ymbols')
          map('<leader>lw', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace Symbols')
          map('<leader>lr', lsp.buf.rename, '[R]ename')
          map('<leader>la', lsp.buf.code_action, 'Code [A]ction')
          map( "<space>li", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
          end, 'Enable [I]nlay hints')

          -- Opens a popup that displays documentation about the word under your cursor
          --  See `:help K` for why this keymap
          map('K', lsp.buf.hover, 'Hover Documentation')

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header
          map('<leader>lc', lsp.buf.declaration, 'Goto De[C]laration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              callback = lsp.buf.document_highlight,
            })

            api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              callback = lsp.buf.clear_references,
            })
          end
        end,
      })

      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      lsp.inlay_hint.enable(true)
    end,
  },
}
