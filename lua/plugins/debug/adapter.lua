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
      -- utils must be loaded before since it defines dependent functions
      require "plugins.debug.utils"
      require "plugins/debug/c#"
      require "plugins/debug/lua"
      require "plugins/debug/ui"
      require "plugins.debug.keymap"
    end,
  },
}
