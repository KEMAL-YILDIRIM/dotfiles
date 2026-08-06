local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))

-- Windows libuv fs_event (ReadDirectoryChangesW) crashes on network/UNC paths
-- (vim/_watch.lua:75, async UNKNOWN error). Disable LSP dynamic file watching
-- so servers never register Neovim-side watchers.
capabilities.workspace = capabilities.workspace or {}
capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }

return capabilities
