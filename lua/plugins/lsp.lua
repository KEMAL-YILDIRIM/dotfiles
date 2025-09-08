local M = {}
table.insert(M, require 'plugins.lsp.mason')
table.insert(M, require 'plugins.lsp.csharp-lsp')
table.insert(M, require 'plugins.lsp.config')
table.insert(M, require 'plugins.lsp.lua-lsp')
return  M
