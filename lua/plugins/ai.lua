return {
	{ -- code companion
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		enabled = false,
		config = function()
			return true
		end
	},
	{ -- codeium
		"Exafunction/codeium.nvim",
		enabled = false,
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},
		config = function()
			require("codeium").setup({
				enable_cmp_source = true,
				virtual_text = {
					manual = true,
					key_bindings = {
            -- Accept the current completion.
            accept = "<C-y>",
            -- Accept the next word.
            accept_word = "<TAB>",
            -- Accept the next line.
            accept_line = false,
            -- Clear the virtual text.
            clear = "<C-c>",
            -- Cycle to the next completion.
            next = "<C-n>",
            -- Cycle to the previous completion.
            prev = "<C-p>",
        }
				}
			})
			-- Codeium Chat
			vim.api.nvim_create_user_command('Chat', function(opts)
					vim.api.nvim_call_function("codeium#Chat", {})
				end,
				{})
			require('codeium.virtual_text').set_statusbar_refresh(function()
				require('lualine').refresh()
			end)
		end
	},
	{ -- gen.nvim
		"David-Kunz/gen.nvim",
		enabled = false,
		opts = {
			model = "mistral", -- The default model to use.
			host = "localhost", -- The host running the Ollama service.
			port = "11434",   -- The port on which the Ollama service is listening.
			quit_map = "q",   -- set keymap for close the response window
			retry_map = "<c-r>", -- set keymap to re-send the current prompt
			init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
			-- Function to initialize Ollama
			command = function(options)
				local body = { model = options.model, stream = true }
				return "curl --silent --no-buffer -X POST http://" .. options.host .. ":" .. options.port .. "/api/chat -d $body"
			end,
			-- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
			-- This can also be a command string.
			-- The executed command must return a JSON object with { response, context }
			-- (context property is optional).
			-- list_models = '<omitted lua function>', -- Retrieves a list of model names
			display_mode = "float", -- The display mode. Can be "float" or "split".
			show_prompt = false, -- Shows the prompt submitted to Ollama.
			show_model = false,  -- Displays which model you are using at the beginning of your chat session.
			no_auto_close = false, -- Never closes the window automatically.
			debug = false        -- Prints errors and the command which is run.
		}
	},
	{ -- cmp-ai
		'tzachar/cmp-ai',
		enabled = false,
		dependencies = 'nvim-lua/plenary.nvim',
		config = function()
			local cmp_ai = require('cmp_ai.config')

			cmp_ai:setup({
				max_lines = 100,
				provider = 'Ollama',
				provider_options = {
					model = 'codellama:7b-code',
				},
				notify = true,
				notify_callback = function(msg)
					vim.notify(msg)
				end,
				run_on_every_keystroke = true,
				ignored_file_types = {
					-- default is not to ignore
					-- uncomment to ignore in lua:
					-- lua = true
				},
			})
		end
	},
}
