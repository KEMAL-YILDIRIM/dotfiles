-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins, you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup {

  -- modular approach: using `require 'path/name'` will
  -- include a plugin definition from file lua/path/name.lua

  { import = 'kickstart.plugins' },
  { import = 'custom.plugins' },
}

-- vim: ts=2 sts=2 sw=2 et
