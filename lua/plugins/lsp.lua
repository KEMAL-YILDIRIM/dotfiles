local lsp_modules = {}
table.insert(lsp_modules, require 'plugins.lsp.mason')
table.insert(lsp_modules, require 'plugins.lsp.csharp-lsp')
table.insert(lsp_modules, require 'plugins.lsp.config')
table.insert(lsp_modules, require 'plugins.lsp.lua-lsp')
return  lsp_modules
