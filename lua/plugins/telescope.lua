return {
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons" },
		},
		config = function()
			-- Two important keymaps to use while in telescope are:
			--  - Insert mode: <C-/>
			--  - Normal mode: ?

			-- Limit the color of the path to two
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "TelescopeResults",
				callback = function(ctx)
					vim.api.nvim_buf_call(ctx.buf, function()
						vim.fn.matchadd("TelescopeParent", "\t\t.*$")
						vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
					end)
				end,
			})

			-- Set the filename and the ext to the first part of path
			local function filenameFirst(_, path)
				local tail = vim.fs.basename(path)
				local parent = vim.fs.dirname(path)
				if parent == "." then
					return tail
				end
				return string.format("%-80s |  %-20s", tail, parent)
			end

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local make_entry = require("telescope.make_entry")
			local conf = require("telescope.config").values

			local live_multigrep = function(opts)
				opts = opts or {}
				opts.cwd = opts.cwd or vim.uv.cwd()

				local finder = finders.new_async_job({
					command_generator = function(prompt)
						if not prompt or prompt == "" then
							return nil
						end

						local pieces = vim.split(prompt, "  ")
						local args = { "rg" }
						if pieces[1] then
							table.insert(args, "-e")
							table.insert(args, pieces[1])
						end

						if pieces[2] then
							table.insert(args, "-g")
							table.insert(args, pieces[2])
						end

						---@diagnostic disable-next-line: deprecated
						return vim.tbl_flatten({
							args,
							{
								"--color=never",
								"--no-heading",
								"--with-filename",
								"--line-number",
								"--column",
								"--smart-case",
							},
						})
					end,
					entry_maker = make_entry.gen_from_vimgrep(opts),
					cwd = opts.cwd,
				})

				pickers
					.new(opts, {
						debounce = 100,
						prompt_title = "Multi Grep",
						finder = finder,
						previewer = conf.grep_previewer(opts),
						sorter = require("telescope.sorters").empty(),
					})
					:find()
			end

			telescope.setup({
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				--
				defaults = {
					path_display = filenameFirst,
					layout_strategy = "vertical",
					layout_config = {
						vertical = {
							height = 0.9,
							preview_height = 0.7,
							resolve_height = 0.3,
							prompt_position = "top",
							preview_cutoff = 0,
							width = 0.9,
						},
						horizontal = {
							height = 0.9,
							preview_width = 0.7,
							prompt_position = "bottom",
							width = 0.9,
						},
					},
					mappings = {
						-- n = {
						--   ["<C-c>"] = actions.close,
						-- },
						i = {
							-- ["<C-c>"] = actions.close,
							["<C-f>"] = "to_fuzzy_refine",

							["<C-k>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,

							-- ["<M-k>"] = actions.preview_scrolling_up,
							-- ["<M-j>"] = actions.preview_scrolling_down,
							-- ["<M-h>"] = actions.preview_scrolling_left,
							-- ["<M-l>"] = actions.preview_scrolling_right,

							["<C-p>"] = actions.results_scrolling_up,
							["<C-n>"] = actions.results_scrolling_down,
							-- ["<C-h>"] = actions.results_scrolling_left,
							-- ["<C-l>"] = actions.results_scrolling_right,
						},
					},
				},
				pickers = {
					-- lsp_document_symbols = {
					--   theme = "ivy"
					-- },
					keymaps = {
						show_plug = false,
						entry_maker = function(entry)
							local entry_display = require("telescope.pickers.entry_display")

							-- Get file path info
							local file_path = ""
							if entry.sid and entry.sid > 0 then
								local ok, script_info = pcall(vim.fn.getscriptinfo, { sid = entry.sid })
								if ok and script_info and script_info[1] and script_info[1].name then
									file_path = vim.fs.normalize(script_info[1].name)
								end
							end

							-- Create displayer matching original format with file path column
							local displayer = entry_display.create({
								separator = "▏",
								items = {
									{ width = 2 },
									{ width = 10 },
									{ width = 40 },
									{ width = 40 },
									{ remaining = true },
								},
							})

							return {
								value = entry,
								ordinal = vim.fn.join({
									entry.mode or "",
									entry.lhs or "",
									entry.rhs or "",
									entry.desc or "",
									file_path or "",
								}, ""),
								display = function()
									return displayer({
										entry.mode or "",
										entry.lhs or "",
										entry.rhs or "",
										entry.desc or "",
										file_path or "",
									})
								end,
							}
						end,
					},
					buffers = {
						mappings = {
							i = { ["<C-x>"] = actions.delete_buffer, desc = { "Telescope Delete buffer" } },
							n = { ["<C-x>"] = actions.delete_buffer, desc = { "Telescope Delete buffer" } },
						},
					},
				},
				extensions = {
					fzf = {},
					-- ['ui-select'] = {
					--   require('telescope.themes').get_dropdown(),
					-- },
				},
			})

			-- Enable telescope extensions, if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>f", "<NOP>", { desc = "Search Telescope" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search Help" })
			vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Search Keymaps" })
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search Files" })
			vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Search grep Word" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search live Grep" })
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Search Diagnostics" })
			vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Search Resume" })
			vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = "Search Recent Files." })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Search existing Buffers" })
			vim.keymap.set("n", "<leader>ft", ":TodoTelescope<CR>", { desc = "Search Todo marks" })
			vim.keymap.set("n", "<leader>fm", live_multigrep, { desc = "Search Multigrep" })

			vim.keymap.set("n", "<leader>fo", function()
				builtin.find_files({ cwd = "C:/Users/Kemal Yildirim/OneDrive/Dokumanlar/Obsidian" })
			end, { desc = "Search Obsidian" })

			vim.keymap.set("n", "<leader>fn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "Search Neovim files" })

			vim.keymap.set("n", "<leader>fp", function()
				builtin.find_files({ cwd = vim.fn.stdpath("data") })
			end, { desc = "Search Neovim Plugin files" })

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>fc", function()
				-- You can pass additional configuration to telescope to change theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "Search in Current buffer" })

			-- Also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>f/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "Search / in Open Files" })
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
