return {
	{ -- LuaSnip
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		enabled = true,
		lazy = true,
		dependencies = { "molleweide/LuaSnip-snippets.nvim" },
		-- build = 'make install_jsregexp CC=gcc.exe SHELL=C:/path/to/sh.exe .SHELLFLAGS=-c',
		build = "make install_jsregexp CC=gcc",
		config = function()
			local ls = require("luasnip")
			vim.snippet.expand = ls.lsp_expand

			---@diagnostic disable-next-line: duplicate-set-field
			vim.snippet.active = function(filter)
				filter = filter or { direction = 1 }

				if filter.direction == 1 then
					return ls.expand_or_jumpable()
				else
					return ls.jumpable(filter.direction)
				end
			end

			---@diagnostic disable-next-line: duplicate-set-field
			vim.snippet.jump = function(direction)
				if direction == 1 then
					if ls.expandable() then
						return ls.expand_or_jump()
					else
						return ls.jumpable(1) and ls.jump(1)
					end
				else
					return ls.jumpable(-1) and ls.jump(-1)
				end
			end

			vim.snippet.stop = ls.unlink_current

			ls.config.set_config({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				override_builtin = true,
			})

			for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/snippets/*.lua", true)) do
				loadfile(ft_path)()
			end

			vim.keymap.set({ "i", "s" }, "<C-l>", function()
				return vim.snippet.active({ direction = 1 }) and vim.snippet.jump(1)
			end, { silent = true })

			vim.keymap.set({ "i", "s" }, "<C-h>", function()
				return vim.snippet.active({ direction = -1 }) and vim.snippet.jump(-1)
			end, { silent = true })

			ls.setup({
				snip_env = {
					s = function(...)
						local snip = ls.s(...)
						-- we can't just access the global `ls_file_snippets`, since it will be
						-- resolved in the environment of the scope in which it was defined.
						table.insert(getfenv(2).ls_file_snippets, snip)
					end,
					parse = function(...)
						local snip = ls.parser.parse_snippet(...)
						table.insert(getfenv(2).ls_file_snippets, snip)
					end,
					-- remaining definitions.
				},
			})

			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	--[[ { -- Autocompletion NvimCmp
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    enabled = true,
    lazy = true,
    dependencies = {

      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',

      'neovim/nvim-lspconfig',
      'saadparwaiz1/cmp_luasnip',

    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local ls = require 'luasnip'

      cmp.setup {
        snippet = {
          expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body)
            ls.lsp_expand(args.body)
          end,
        },
        preselect = cmp.PreselectMode.None,
        completion = {
          completeopt = 'menu,menuone,preview',
          keyword_length = 1
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          expandable_indicator = true,
          format = function(entry, vim_item)
            local kind = require("lspkind").cmp_format({
              symbol_map = { Codeium = "", },
              mode = "symbol_text",
              menu = {
                nvim_lsp = "[LSP]",
                luasnip = "[Luasnip]",
                buffer = "[Buffer]",
                path = "[Path]",
                crates = "[Crates]",
              },
              maxwidth = 90,
              ellipsis_char = "...",
            })(entry, vim_item)
            local strings = vim.split(kind.kind, "%s", { trimempty = true })
            kind.kind = " " .. (strings[1] or "") .. " "
            kind.menu = "    (" .. (strings[2] or "") .. ")"

            return kind
          end,
        },
        -- For an understanding of why these keymaps were
        -- chosen, you will need to read `:help ins-completion`
        mapping = {
          ['<C-.>'] = cmp.mapping.open_docs(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-j>'] = cmp.mapping.select_next_item(),
          ['<C-k>'] = cmp.mapping.select_prev_item(),
          ['<C-x>'] = cmp.mapping.close(),
          ['<Tab>'] = cmp.mapping.confirm { select = true },
        },
        sources = {
          { name = 'luasnip',                 priority = 1, group_index = 1 },
          { name = 'nvim_lsp',                priority = 2, group_index = 2 },
          { name = 'nvim_lsp_signature_help', priority = 3, group_index = 3 },
          { name = 'buffer',                  priority = 4, group_index = 4 },
          { name = 'path',                    priority = 5, group_index = 5 },
          { name = 'lazydev',                 priority = 6, group_index = 6 },
          { name = 'codeium',                 priority = 7, group_index = 7 },
        },
        window = {
          completion = cmp.config.window.bordered({
            -- col_offset = -3,
            side_padding = 0,
            -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:Visual,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:Visual,Search:None",
          }),
        },
        -- sorting = {
        --   priority_weight = 2,
        --   comparators = {
        --     lspkind_comparator({
        --       kind_priority = {
        --         Snippet = 12,
        --         Field = 11,
        --         Property = 11,
        --         Constant = 10,
        --         Enum = 10,
        --         EnumMember = 10,
        --         Event = 10,
        --         Function = 10,
        --         Method = 10,
        --         Operator = 10,
        --         Reference = 10,
        --         Struct = 10,
        --         Variable = 9,
        --         File = 8,
        --         Folder = 8,
        --         Class = 5,
        --         Color = 5,
        --         Module = 5,
        --         Keyword = 3,
        --         Constructor = 2,
        --         Interface = 2,
        --         TypeParameter = 2,
        --         Unit = 2,
        --         Value = 2,
        --         Text = 1,
        --       },
        --     }),
        --     label_comparator,
        --   },
        -- }
      }


      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = {
          ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
          ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' }),
          ['<Tab>'] = cmp.mapping(cmp.mapping.confirm { select = true, behavior = cmp.ConfirmBehavior.Replace }, { 'c' }),
        },
        sources = cmp.config.sources(
          { { name = 'path' } },
          { { name = 'cmdline' } }),
      })



      -- Setup up vim-dadbod
      cmp.setup.filetype({ "sql" }, {
        sources = {
          { name = "vim-dadbod-completion" },
          { name = "buffer" },
        },
      })
    end,
  }, ]]
	{ -- Autocompletion Blink
		"saghen/blink.cmp",
		dependencies = {
			-- { "L3MON4D3/LuaSnip", version = "v2.*" },
			{ "saghen/blink.compat", lazy = true, verson = false },
		},
		version = "1.*",
		enabled = true,
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "none",

				["<C-.>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-c>"] = { "cancel", "fallback" },
				["<Tab>"] = { "select_and_accept" },

				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },

				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },

				["<C-l>"] = { "snippet_forward", "fallback" },
				["<C-h>"] = { "snippet_backward", "fallback" },
			},

			completion = {
				menu = {
          border = "rounded",
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
					--[[ draw = {
						padding = 1,
						components = {
							kind_icon = {
								text = function(ctx)
									if vim.tbl_contains({ "Path" }, ctx.source_name) then
										local mini_icon, _ =
											require("mini.icons").get_icon(ctx.item.data.type, ctx.label)
										if mini_icon then
											return mini_icon .. ctx.icon_gap
										end
									end

									local icon = require("lspkind").symbolic(ctx.kind, { mode = "symbol" })
									return icon .. ctx.icon_gap
								end,

								-- Optionally, use the highlight groups from mini.icons
								-- You can also add the same function for `kind.highlight` if you want to
								-- keep the highlight groups in sync with the icons.
								highlight = function(ctx)
									if vim.tbl_contains({ "Path" }, ctx.source_name) then
										local mini_icon, mini_hl =
											require("mini.icons").get_icon(ctx.item.data.type, ctx.label)
										if mini_icon then
											return mini_hl
										end
									end
									return ctx.kind_hl
								end,
							},
							kind = {
								-- Optional, use highlights from mini.icons
								highlight = function(ctx)
									if vim.tbl_contains({ "Path" }, ctx.source_name) then
										local mini_icon, mini_hl =
											require("mini.icons").get_icon(ctx.item.data.type, ctx.label)
										if mini_icon then
											return mini_hl
										end
									end
									return ctx.kind_hl
								end,
							},
						},
						-- columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } }, --cmp like display
					}, ]]
				},
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			fuzzy = {
				sorts = {
					"exact",
					"score",
					"sort_text",
				},
			},

			cmdline = {
				keymap = { preset = "inherit" },
				completion = { menu = { auto_show = true } },
			},

			snippets = { preset = "luasnip" },

			sources = {
				default = { "lsp", "path", "snippets", "buffer", "obsidian", "obsidian_new", "obsidian_tags" },
				per_filetype = {
					sql = { "dadbod" },
				},
				providers = {
					dadbod = { module = "vim_dadbod_completion.blink" },
					obsidian = { name = "obsidian", module = "blink.compat.source" },
					obsidian_new = { name = "obsidian_new", module = "blink.compat.source" },
					obsidian_tags = { name = "obsidian_tags", module = "blink.compat.source" },
				},
			},
		},
	},
}
-- vim: ts=2 sts=2 sw=2 et
