local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt

local function get_namespace()
    -- Get the current buffer's file path
    local file_path = vim.fn.expand("%:p")
    -- Get the project root (assuming it contains .sln or .csproj file)
    local project_root = vim.fn.fnamemodify(vim.fn.findfile(".sln", ".;"), ":h")
    if project_root == "" then
        project_root = vim.fn.fnamemodify(vim.fn.findfile(".csproj", ".;"), ":h")
    end
    
    -- Get relative path from project root to current file
    local rel_path = file_path:sub(#project_root + 2)
    -- Remove the filename
    local dir_path = vim.fn.fnamemodify(rel_path, ":h")
    -- Convert directory separators to dots and remove any special characters
    local namespace = dir_path:gsub("[/\\]", "."):gsub("[^%w.]", "")
    
    -- If we're in the root, use the project name
    if namespace == "" then
        namespace = vim.fn.fnamemodify(project_root, ":t")
    else
        namespace = vim.fn.fnamemodify(project_root, ":t") .. "." .. namespace
    end
    
    return namespace
end

ls.add_snippets("cs", {
    s("class", fmt([[
using System;

namespace {}
{{
    public class {} {}
    {{
        {}
    }}
}}
    ]], {
        f(get_namespace),
        i(1, "ClassName"),
        i(2, ": IDisposable"),
        i(0)
    }))
})
