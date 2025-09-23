return {
  {
    'nvim-lua/plenary.nvim',
    config = function()
      -- planary test
      vim.keymap.set("n", "<leader>up", "<Plug>PlenaryTestFile", { desc = "[P]lenary Test" })
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
          require("neotest-dotnet")
        }
      })
      vim.keymap.set("n", "<leader>ur", function() neotest.run.run() end, { desc = "[R]un Test" })
      vim.keymap.set("n", "<leader>ut", function() neotest.summary.toggle() end, { desc = "[T]oggle Summary" })
      vim.keymap.set("n", "<leader>uf", function() neotest.run.run(vim.fn.exp("%")) end,
        { desc = "[R]un all tests on the [F]ile" })
      vim.keymap.set("n", "<leader>ud", function() neotest.run.run({ strategy = "dap" }) end,
        { desc = "[D]ebug Test" })
      vim.keymap.set("n", "<leader>us", function() neotest.run.stop() end, { desc = "[S]top Test" })
    end
  }
}
