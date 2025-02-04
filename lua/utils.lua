P = function(v)
	print(vim.inspect(v))
	return v
end

R = function(v)
	require("plenary.reload").reload_module(v)
	return require(v)
end

---Read file from the path
---@param path string
---@return string | nil
ReadFile = function(path)
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
