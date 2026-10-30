return {
  {
    'olimorris/codecompanion.nvim',
    event = 'InsertEnter',
    opts = {
      adapters = {
        acp = {
          claude_code = function()
            return require('codecompanion.adapters').extend('claude_code', {
              env = {
                CLAUDE_CODE_OAUTH_TOKEN = os.getenv 'CLAUDE_CODE_OAUTH_TOKEN',
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          -- Use your Claude subscription via the ACP adapter (needs CLAUDE_CODE_OAUTH_TOKEN
          -- and the `claude-agent-acp` bridge on PATH). ACP is chat-only.
          adapter = 'claude_code',
          keymaps = {
            close = { modes = { n = '<C-x>', i = '<C-x>' }, opts = {} },
          },
        },
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    init = function()
      vim.keymap.set('n', '<leader>ai', '<CMD>CodeCompanionChat Toggle<CR>', { desc = 'AI Code Companion Chat Toggle' })
    end,
  },
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    enabled = false,
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        panel = {
          keymap = {
            jump_prev = '[[',
            jump_next = ']]',
            accept = '<Tab>',
            refresh = 'gr',
            open = '<C-a>',
          },
        },
        suggestion = {
          keymap = {
            accept = '<C-y>',
            accept_word = false,
            accept_line = false,
            next = '<C-n>',
            prev = '<C-p>',
            dismiss = '<C-c>',
          },
        },
      }
    end,
  },
}
