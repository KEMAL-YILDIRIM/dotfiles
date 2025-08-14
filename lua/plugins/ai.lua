return {
  {
    "olimorris/codecompanion.nvim",
    event = "BufEnter",
    opts = {
      -- adapters = {
      --   anthropic = function()
      --     return require("codecompanion.adapters").extend("anthropic", {
      --       env = {
      --         api_key = vim.env.ANTHROPIC_API_KEY
      --       },
      --     })
      --   end,
      -- },
      strategies = {
        chat = {
          keymaps = {
            close = {
              modes = { n = "<C-x>", i = "<C-x>" },
              opts = {},
            },
          }
        }
      }
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = false,
          hide_during_completion = true,
          debounce = 75,
          trigger_on_accept = true,
          keymap = {
            accept = "<C-y>",
            accept_word = false,
            accept_line = false,
            next = "<C-n>",
            prev = "<C-p>",
            dismiss = "<C-c>",
          },
        },
      })
    end,
  }
}
