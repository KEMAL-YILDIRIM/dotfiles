-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'utils'

-- [[ Basic Keymaps ]]
require 'keymap'

-- Patch a known crash in nvim's built-in pull-diagnostics handler before any
-- LSP server attaches. See lua/lsp-diagnostic-guard.lua for the rationale.
require 'lsp-diagnostic-guard'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

-- [[ Auto Commands ]]
require 'commands'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
