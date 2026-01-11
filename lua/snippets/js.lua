local ls = require("luasnip")
local _snippet = ls.snippet -- creator
local _input = ls.insert_node --nodes
local _text = ls.text_node
local _func = ls.function_node
local _format = require("luasnip.extras.fmt").fmt

ls.add_snippets("javascript", {

	_snippet(
		"function",
		_format(
[[function {}() {{
{}
}}]],
			{_input(1),_input(0)}
		)
	),
})
