local M = {}
require("plugins.lsp.utils")
require("plugins.lsp.commands")

table.insert(M, require("plugins.lsp.mason"))
table.insert(M, require("plugins.lsp.c#"))
table.insert(M, require("plugins.lsp.config"))
table.insert(M, require("plugins.lsp.lua"))
return M
