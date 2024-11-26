local ls = require 'luasnip'
local s, i, f = ls.snippet, ls.insert_node, ls.function_node
local fmt = require("luasnip.extras.fmt").fmt

local same = function(index)
    return f(function(arg)
        return arg[1]
    end, { index })
end

ls.add_snippet("all", {
    s("sameTest", fmt([[example:{}, function: {}]], { i(1), same(1) }))
})

ls.add_snippet("lua", {
    s("req", fmt([[local {} = require "{}"]], {
        f(function(import_name)
            local parts = vim.split(import_name[1][1], ".", { places = true, trimempty = true })
            return parts[#parts] or ""
        end, { 1 }),
        i(1),
    })),
})
