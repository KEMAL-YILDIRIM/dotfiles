local ls = require("luasnip")
local _snippet = ls.snippet   -- creator
local _input = ls.insert_node --nodes
local _text = ls.text_node
local _func = ls.function_node
local _format = require("luasnip.extras.fmt").fmt



local function get_namespace()
    local file_path    = vim.fn.expand("%:p:h")
    local project_path = F.find_csproj_file(file_path)

    local project_root = vim.fn.fnamemodify(project_path, ":h") or "/"
    local rel_path     = vim.fs.relpath(project_root, file_path) or "/"
    local namespace    = string.gsub(vim.fs.normalize(rel_path), '/', '.')

    -- If we're in the root, use the project name
    if namespace == "" then
        namespace = vim.fn.fnamemodify(project_root, ":t")
    end

    return namespace
end


-- Function to get class information from Roslyn LSP
local function get_class_info()
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = vim.lsp.util.make_position_params(0, 'utf-8').position
    }

    local symbols = vim.lsp.buf_request_sync(0, 'textDocument/documentSymbol', params, 1000)

    if not symbols then return nil end

    for _, res in pairs(symbols) do
        if res.result then
            for _, symbol in ipairs(res.result) do
                if symbol.kind == 5 then -- ClassSymbol
                    return {
                        name = symbol.name,
                        range = symbol.range,
                        detail = symbol.detail
                    }
                end
            end
        end
    end
    return nil
end

-- Function to get class fields from Roslyn LSP
local function get_class_fields()
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = vim.lsp.util.make_position_params(0, 'utf-8').position
    }

    local result = vim.lsp.buf_request_sync(0, 'textDocument/documentSymbol', params, 1000)
    local fields = {}

    if not result then return fields end

    for _, res in pairs(result) do
        if res.result then
            for _, symbol in ipairs(res.result) do
                if symbol.kind == 5 then -- Class
                    -- Process children of the class
                    if symbol.children then
                        for _, child in ipairs(symbol.children) do
                            if child.kind == 8 then -- Field
                                table.insert(fields, {
                                    name = child.name,
                                    detail = child.detail,
                                    range = child.range
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    return fields
end

-- Parse Roslyn field detail into components
local function parse_field_detail(detail)
    -- Roslyn provides details in format like "private string _name"
    local pattern = "(%w+)%s+([%w%.<>]+)%s+([_%w]+)"
    local access, type, name = detail:match(pattern)

    if access and type and name then
        return {
            access = access,
            type = type,
            name = name:gsub("^_", "") -- Remove leading underscore if present
        }
    end
    return nil
end

local function generate_constructor_params()
    local fields = get_class_fields()
    local params = {}

    for _, field in ipairs(fields) do
        local parsed = parse_field_detail(field.detail)
        if parsed and parsed.access == "private" then -- Only include private fields
            table.insert(params, parsed.type .. " " .. parsed.name)
        end
    end

    return table.concat(params, ", ")
end

local function generate_assignments()
    local fields = get_class_fields()
    local assignments = {}

    for _, field in ipairs(fields) do
        local parsed = parse_field_detail(field.detail)
        if parsed and parsed.access == "private" then -- Only include private fields
            local fieldName = parsed.name
            local thisRef = "_" .. fieldName          -- Use backing field if it exists
            table.insert(assignments, string.format("        this.%s = %s;", thisRef, fieldName))
        end
    end

    return #assignments > 0 and "\n" .. table.concat(assignments, "\n") or ""
end

ls.add_snippets("cs", {

    _snippet("interface_snip", _format([[
using System;

namespace {}
{{
    public interface {}
    {{
        {}
    }}
}}
    ]], {
        _func(get_namespace),
        _func(function() return "I" .. vim.fn.expand("%:t:r") end),
        _input(0)
    })),

    _snippet("class_snip", _format([[
using System;

namespace {}
{{
    public class {}
    {{
        {}
    }}
}}
    ]], {
        _func(get_namespace),
        _func(function() return vim.fn.expand("%:t:r") end),
        _input(0)
    })),

    _snippet("ctor", {
        _text({ "    /// <summary>", "    /// Initializes a new instance of the " }),
        _func(function()
            local class_info = get_class_info()
            return class_info and class_info.name or vim.fn.expand("%:t:r")
        end, {}),
        _text({ " class.", "    /// </summary>" }),
        -- Generate parameter documentation
        _func(function()
            local fields = get_class_fields()
            local docs = {}
            for _, field in ipairs(fields) do
                local parsed = parse_field_detail(field.detail)
                if parsed and parsed.access == "private" then
                    table.insert(docs, string.format("    /// <param name=\"%s\">The %s.</param>",
                        parsed.name, parsed.name:gsub("([A-Z])", " %1"):lower():trim()))
                end
            end
            return #docs > 0 and "\n" .. table.concat(docs, "\n") or ""
        end, {}),
        _text({ "", "    public " }),
        -- Class name
        _func(function()
            local class_info = get_class_info()
            return class_info and class_info.name or vim.fn.expand("%:t:r")
        end, {}),
        _text("("),
        -- Constructor parameters
        _func(generate_constructor_params, {}),
        _text({ ") {", "" }),
        -- Field assignments
        _func(generate_assignments, {}),
        _text({ "", "    }" })
    })

})
