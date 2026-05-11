return {
  {
    'mfussenegger/nvim-dap',
    lazy = true,
    dependencies = {
      -- modern, tabbed single-panel debugger UI (replaces nvim-dap-ui)
      { 'igorlfs/nvim-dap-view', version = '1.*' },
      -- display text as you step throughout the code
      'theHamsta/nvim-dap-virtual-text',
      -- lua debug
      'jbyuki/one-small-step-for-vimkind',
    },
    config = function()
      -- utils must be loaded before since it defines dependent functions
      require "plugins.debug.utils"
      require "plugins.debug.c#"
      require "plugins.debug.lua"
      require "plugins.debug.ui"
      require "plugins.debug.keymap"
    end,
  },
}
