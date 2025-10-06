-- [[ Basic Keymaps ]]
--  See `:help map.set()`

vim.g.mapleader = " "
local map = vim.keymap

-- Set highlight on search, but clear on pressing CTRL + x in normal mode
vim.opt.hlsearch = true
map.set("n", "<C-c>", "<CMD>nohlsearch<CR>", { desc = "Clear highlight search in normal mode" })

-- return to normal mode
map.set("i", "<C-c>", "<esc><esc><esc>", { desc = "Press ESC" })

-- jump to lsp document window
map.set("i", "<C-l>", function()
    vim.cmd.stopinsert()
    vim.lsp.buf.signature_help()
    vim.defer_fn(function() vim.cmd.wincmd("w") end, 100)
    vim.keymap.set("n", "q", ":close<CR>", { buffer = true })
end)

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
map.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- indentation while stay in indent mode
vim.keymap.set("v", "<", "<gv", { desc = "Decrease the indent" })
vim.keymap.set("v", ">", ">gv", { desc = "Increase the indent" })


-- visual mode > move selected lines
map.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })


-- keep the cursor in the center of page while navigating page up or down
map.set("n", "<C-d>", "<C-d>zz", { desc = "Page down while keeping cursor at the middle of the page" })
map.set("n", "<C-u>", "<C-u>zz", { desc = "Page down while keeping cursor at the middle of the page" })


-- preserve paste buffer
map.set("x", "<leader>p", [["_dP]], { desc = "Preserve [P]aste buffer" })

-- coppy to system clipboard so not loose it while navigate between files
map.set({ "n", "v" }, "<leader>y", "<nop>", { desc = "Copy" })
map.set({ "n", "v" }, "<leader>yy", [["+y]], { desc = "Copy text to system clipboard" })
map.set({ "n", "v" }, "<leader>ya", "ggVGy", { desc = "Copy all on page" })
map.set({ "n", "v" }, "<leader>yp", function()
	local results = {
		vim.fn.expand("%:p"),
		vim.fn.expand("%:h"),
		vim.fn.expand("%:t"),
		vim.fn.expand("%:t:r"),
		vim.fn.expand("%:e"),
	}

	vim.ui.select({
		"1. Absolute: " .. results[1],
		"2. Directory: " .. results[2],
		"3. Filename: " .. results[3],
		"4. Filename only: " .. results[4],
		"5. Extension: " .. results[5],
	}, { prompt = "Choose to copy to clipboard:" }, function(choice)
		local i = tonumber(string.sub(choice, 1, 1)) or 1
		local result = results[i]
		vim.fn.setreg('+y', result)
		vim.notify('Copied: ' .. result)
	end)
end, { desc = "Copy current buffer path to system clipboard" })


-- save and quit
map.set("n", "<C-s>", "<nop>", { desc = "[S]ave" })
map.set("n", "<C-s>f", "<CMD>:w!<CR>", { noremap = true, desc = "[S]ave [F]ile" })
map.set("n", "<C-s>a", "<CMD>:wa!<CR>", { noremap = true, desc = "[S]ave [A]ll buffers" })
map.set("n", "<C-s>o", "<CMD>:w!<CR><cmd>:so<cr>", { noremap = true, desc = "[S]ave and [S]ource out" })
map.set("n", "<C-s>q", "<CMD>:wq!<CR>", { noremap = true, desc = "[S]ave and [Q]uit" })
map.set("n", "Q", "<nop>", { desc = "No map for Q" })

-- quickfix
map.set("n", "<leader>qn", "<CMD>:cn<CR>", { noremap = true, desc = "[Q]uickfix [N]ext" })
map.set("n", "<leader>qp", "<CMD>:cp<CR>", { noremap = true, desc = "[Q]uickfix [P]revious" })
map.set("n", "<leader>qq", function()
	local qf_exists = false
	for _, win in pairs(vim.fn.getwininfo()) do
		if win["quickfix"] == 1 then
			qf_exists = true
		end
	end
	if qf_exists == true then
		vim.cmd "cclose"
		return
	end
	if not vim.tbl_isempty(vim.fn.getqflist()) then
		vim.cmd "copen"
	end
end, { noremap = true, desc = "[Q]uickfix Toggle" })


-- tabs
local tab_mode_active = false

local function tab_actions()
	if tab_mode_active then
		return -- Prevent multiple activations
	end

	tab_mode_active = true
	vim.notify("Tab mode active - press n/x/a/l/h/d or any other key to exit", vim.log.levels.INFO)

	-- Create temporary keymaps only for tab mode
	local temp_maps = {
		{ 'n', 'n', function() vim.cmd("tabnew"); tab_mode_active = false end },
		{ 'n', 'x', function() vim.cmd("tabc"); tab_mode_active = false end },
		{ 'n', 'a', function() vim.cmd("tabo"); tab_mode_active = false end },
		{ 'n', 'l', function() vim.cmd("tabn"); tab_mode_active = false end },
		{ 'n', 'h', function() vim.cmd("tabp"); tab_mode_active = false end },
		{ 'n', 'd', function() vim.cmd("tabnew %"); tab_mode_active = false end },
	}

	-- Set temporary maps
	for _, map_def in ipairs(temp_maps) do
		vim.keymap.set(map_def[1], map_def[2], map_def[3], { buffer = true })
	end

	-- Set up one-time autocmd to clean up on any other key or mode change
	local group = vim.api.nvim_create_augroup("TabModeCleanup", { clear = true })
	vim.api.nvim_create_autocmd({"InsertEnter", "CmdlineEnter", "VisualEnter"}, {
		group = group,
		once = true,
		callback = function()
			tab_mode_active = false
			vim.notify("Tab mode exited", vim.log.levels.INFO)
			vim.api.nvim_del_augroup_by_id(group)
		end
	})
end

map.set("n", "tm", tab_actions, { desc = "[T]ab [M]ode" })
map.set("n", "tn", "<CMD>tabnew<CR>", { desc = "[T]ab open [N]ew" })         -- open new tab
map.set("n", "tx", "<CMD>tabc<CR>", { desc = "[T]ab close [C]urrent" })      -- close current tab
map.set("n", "to", "<CMD>tabo<CR>", { desc = "[T]ab close [A]ll but this" }) -- close current tab
map.set("n", "tl", "<CMD>tabn<CR>", { desc = "[T]ab Next" })                 --  go to next tab
map.set("n", "th", "<CMD>tabp<CR>", { desc = "[T]ab Previous" })             --  go to previous tab
map.set("n", "td", "<CMD>tabnew %<CR>", { desc = "[T]ab [D]uplicate current buffer in new tab" })
map.set("n", "tt", "<CMD>g:lasttat <CR>", { desc = "[T]ab open last used [T]ab" })
map.set("n", "t", "<nop>", { desc = "[T]ab" })

-- buffers
map.set("n", "<leader>b", "<NOP>", { desc = "Buffer" })
map.set("n", "<leader>bo", ":%bd|e#", { desc = "[B]uffer close all but [O]ne" })
map.set("n", "<leader>bn", ":bn<CR>", { desc = "Next [B]uffer" })
map.set("n", "<leader>bp", ":bp<CR>", { desc = "Previous [B]uffer" })
map.set({ "n", "v" }, "<leader>bs", ":cd %:h<CR>", { desc = "[B]uffer [S]et path to current " })
