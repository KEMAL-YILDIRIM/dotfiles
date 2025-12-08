local ls = require("luasnip")
local _snippet, _input, _function = ls.snippet, ls.insert_node, ls.function_node
local _format = require("luasnip.extras.fmt").fmt

local same = function(index)
    return _function(function(arg)
        return arg[1]
    end, { index })
end

ls.add_snippets("all", {
    _snippet("sameTest", _format([[example:{}, function: {}]], { _input(1), same(1) }))
})

ls.add_snippets("lua", {
    _snippet("req", _format([[local {} = require "{}"]], {
        _function(function(import_name)
            local parts = vim.split(import_name[1][1], ".", { places = true, trimempty = true })
            return parts[#parts] or ""
        end, { 1 }),
        _input(1),
    })),
})
