F = {}
F.log = function(v)
	print(vim.inspect(v))
	return v
end

F.reload = function(v)
	require("plenary.reload").reload_module(v)
	return require(v)
end

local random = math.random
F.uuid = function()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

F.index_of = function(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
	return nil
end

-- Return a key with the given value (or nil if not found).  If there are
-- multiple keys with that value, the particular key returned is arbitrary.
F.key_of = function(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return nil
end

---Read file from the path
---@param path string
---@return string | nil
F.read_file = function(path)
	path = vim.fs.normalize(path)
	local file, content = nil, nil
	local success, err = pcall(function()
		file = io.open(path, "r")
		assert(file, "File not found!")
		content = file:read("*all")
		file:close()
	end)

	if not success then
		print("Error reading file:", err)
	end

	return content
end
