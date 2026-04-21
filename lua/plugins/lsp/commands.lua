local dotnet_utility_commands = {
	secrets = {
		invoke = function(args, opts)
			local current_dir = vim.fn.expand("%:p:h") -- Get the current buffer's directory
			local path = F.get_user_secrets(current_dir)
			vim.cmd("edit " .. path)
		end,
	},
	build = {
		invoke = function(args, opts)
			local current_dir = vim.fn.expand("%:p:h") -- Get the current buffer's directory
			local project_path = F.find_csproj_file(current_dir)
			F.build_project(project_path)
		end,
	},
}

-- user commands
vim.api.nvim_create_user_command("Dotnet", function(opts)
	local fargs = opts.fargs
	local cmd = fargs[1]
	local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
	local subcommand = dotnet_utility_commands[cmd]
	if type(subcommand) == "table" and type(subcommand.invoke) == "function" then
		subcommand.invoke(args, opts)
		return
	end
	vim.notify("Unknown command: " .. cmd, vim.log.levels.ERROR, { title = "Dotnet utility commands" })
end, {
	nargs = "+",
	range = true,
	desc = "Dotnet utility commands",
	complete = function(_, _, _)
		local all_commands = vim.tbl_keys(dotnet_utility_commands)
		return all_commands
	end,
})

-- auto commands
local group = vim.api.nvim_create_augroup("dotnet_utilities", { clear = false })

vim.api.nvim_create_autocmd({ "InsertLeave" }, {
	pattern = "*",
	group = group,
	callback = function()
		local clients = vim.lsp.get_clients({ name = "roslyn" })
		if not clients or #clients == 0 then
			return
		end

		local client = clients[1]
		for buf, _ in pairs(client.attached_buffers) do
			if vim.api.nvim_buf_is_loaded(buf) then
				local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
				client:request('textDocument/diagnostic', params, nil, buf)
			end
		end
	end,
})

--[[ vim.api.nvim_create_autocmd("FileType", {
	pattern = "cs",
	group = group,
	callback = function()
		vim.g.dotnet_errors_only = true
		vim.g.dotnet_show_project_file = false
		vim.o.makeprg = F.build_cmd()
	end,
	desc = "register dotnet related settings",
}) ]]
