return {
  {
    'nvim-lua/plenary.nvim',
    config = function()
      -- planary test
      vim.keymap.set("n", "<leader>tp", "<Plug>PlenaryTestFile", { desc = "Plenary Test" })
    end
  },
  {
    "nvim-neotest/neotest",
    -- commit = "52fca6717ef972113ddd6ca223e30ad0abb2800c",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "Issafalcon/neotest-dotnet",
    },
    lazy = true,
    config = function()
      local neotest = require("neotest")
      neotest.setup({
        log_level = 1,
        adapters = {
          require("neotest-dotnet")({
            dap = {
              adapter_name = "coreclr",
              args = { justMyCode = false },
            }
          })
        }
      })
      vim.keymap.set("n", "<leader>tr", function() neotest.run.run() end, { desc = "Run Test" })
      vim.keymap.set("n", "<leader>tt", function() neotest.summary.toggle() end, { desc = "Toggle Summary" })
      vim.keymap.set("n", "<leader>ta", function() neotest.run.run(vim.fn.exp("%")) end,
        { desc = "Run all tests on the File" })
      vim.keymap.set("n", "<leader>td", function() neotest.run.run({ strategy = "dap" }) end,
        { desc = "Debug Test" })
      vim.keymap.set("n", "<leader>ts", function() neotest.run.stop() end, { desc = "Stop Test" })
    end
  }
}
