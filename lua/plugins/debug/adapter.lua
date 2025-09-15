return {
  {
    'mfussenegger/nvim-dap',
    lazy = true,
    dependencies = {
      -- creates a beautiful debugger ui
      'rcarriga/nvim-dap-ui',
      -- display text as you step throughout the code
      'theHamsta/nvim-dap-virtual-text',
      -- lua debug
      'jbyuki/one-small-step-for-vimkind',
      -- async io operations
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local dap = require("dap")
      require "plugins/debug/c#"
      require "plugins/debug/lua"
      require "plugins/debug/ui"
      require('nvim-dap-virtual-text').setup()
      require "plugins.debug.keymap"
    end,
  },
}
