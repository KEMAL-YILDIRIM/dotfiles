return {
	{ -- Tree-sitter highlight, edit, and navigate code
		'nvim-treesitter/nvim-treesitter',
		build = ':TSUpdate',
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require('nvim-treesitter.configs').setup {
				ensure_installed = {
					'bash', 'c', 'rust',
					'html', 'css', "markdown", "markdown_inline",
					'lua', 'vim', 'latex', 'vimdoc',
					'sql',
					'json', 'regex', 'javascript'
				},
				-- Autoinstall languages that are not installed
				auto_install = true,
				highlight = {
					enable = true,
					disable = function(lang, buf)
						local max_filesize = 200 * 1024 -- 200 KB
						local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
				},
				indent = { enable = true },
				textobjects = {
					select = {
						enable = false,
					}
				}
			}

			--[[ ---@class parser_config
      local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
      parser_config.cshtml = {
        install_info = {
          url = "D:/Nvim/tree-sitter-cshtml",          -- local path or git repo
          files = { "src/parser.c", "src/scanner.c" }, -- note that some parsers also require src/scanner.c or src/scanner.cc
          -- optional entries:
          -- branch = "main",                           -- default branch in case of git repo if different from master
          generate_requires_npm = false,         -- if stand-alone parser without npm dependencies
          requires_generate_from_grammar = true, -- if folder contains pre-generated src/parser.c
        },
        filetype = "cshtml",                     -- if filetype does not match the parser name
        used_by = { "razor", "aspnetcorerazor" },

        -- Experimental: Use multiple parsers
        used_parsers = { "html", "c_sharp" },
      }

      vim.filetype.add({ extension = { cshtml = "cshtml" } })
      vim.treesitter.language.register('cshtml', { 'cshtml', 'razor' }) ]]
			-- There are additional nvim-treesitter modules that you can use to interact
			-- with nvim-treesitter. You should go explore a few and see what interests you:
			--
			--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
			--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
			--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
		end,
	},
	{ -- playground
		'nvim-treesitter/playground',
		enable = false
	}
}
-- vim: ts=2 sts=2 sw=2 et
