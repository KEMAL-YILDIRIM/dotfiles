-- [[ Basic Keymaps ]]
--  See `:help map.set()`

vim.g.mapleader = ' '
local map = vim.keymap

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
map.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear highlight search in normal mode' })


-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
map.set('n', '<c-h>', '<c-w><c-h>', { desc = 'Move focus to the left window' })
map.set('n', '<c-l>', '<c-w><c-l>', { desc = 'Move focus to the right window' })
map.set('n', '<c-j>', '<c-w><c-j>', { desc = 'Move focus to the lower window' })
map.set('n', '<c-k>', '<c-w><c-k>', { desc = 'Move focus to the upper window' })

-- indentation while stay in indent mode
vim.keymap.set('v', '<', '<gv', { desc = 'Decrease the indent' })
vim.keymap.set('v', '>', '>gv', { desc = 'Increase the indent' })


-- visual mode > move selected lines
map.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })


-- keep the cursor in the center of page while navigating page up or down
map.set("n", "<c-d>", "<c-d>zz", { desc = "Page down while keeping cursor at the middle of the page" })
map.set("n", "<c-u>", "<c-u>zz", { desc = "Page down while keeping cursor at the middle of the page" })


-- preserve paste buffer
map.set("x", "<leader>p", [["_dP]], { desc = "Preserve [P]aste buffer" })

-- coppy to system clipboard so not loose it while navigate between files
map.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard text" })


-- save and quit
map.set("n", "<c-s>", "<nop>", { desc = "[S]ave" })
map.set("n", "<c-s>f", "<cmd>:w<cr>", { noremap = true, desc = "[S]ave [F]ile" })
map.set("n", "<c-s>o", "<cmd>:w<cr><cmd>:so<cr>", { noremap = true, desc = "[S]ave and [S]ource out" })
map.set("n", "<c-s>q", "<cmd>:wq<cr>", { noremap = true, desc = "[S]ave and [Q]uit" })
map.set("n", "Q", "<nop>", { desc = "No map for Q" })

-- quickfix
map.set("n", "<leader>qn", "<cmd>:cn<cr>", { noremap = true, desc = "[Q]uickfix [N]ext" })
map.set("n", "<leader>qp", "<cmd>:cp<cr>", { noremap = true, desc = "[Q]uickfix [P]revious" })
map.set("n", "<leader>qt", function()
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
end, { noremap = true, desc = "[Q]uickfix [T]oggle" })


-- tabs
local function tab_actions()
  -- move between tab commands without unnecessary repetations
  local ns_id = vim.api.nvim_create_namespace("");
  print("Entered tab mode " .. ns_id)
  vim.on_key(function(_, key)
    if key == "n" then vim.cmd("tabnew") end
    if key == "q" then vim.cmd("tabc") end
    if key == "a" then vim.cmd("tabo") end
    if key == "l" then vim.cmd("tabn") end
    if key == "h" then vim.cmd("tabp") end
    if key == "d" then vim.cmd("tabnew %") end
    if key == "\27" then
      vim.on_key(nil, ns_id)
      print("Exited tab mode " .. ns_id)
    end
  end, ns_id)
end

map.set("n", "tm", tab_actions, { desc = "[T]ab [M]ode" })
map.set("n", "tn", "<cmd>tabnew<cr>", { desc = "[T]ab open [N]ew" })         -- open new tab
map.set("n", "tc", "<cmd>tabc<cr>", { desc = "[T]ab close [C]urrent" })      -- close current tab
map.set("n", "ta", "<cmd>tabo<cr>", { desc = "[T]ab close [A]ll but this" }) -- close current tab
map.set("n", "tl", "<cmd>tabn<cr>", { desc = "[T]ab Next" })                 --  go to next tab
map.set("n", "th", "<cmd>tabp<cr>", { desc = "[T]ab Previous" })             --  go to previous tab
map.set("n", "td", "<cmd>tabnew %<CR>", { desc = "[T]ab [d]uplicate current buffer in new tab" })
map.set("n", "tt", "<cmd>g:lasttat <CR>", { desc = "[T]ab open last used [T]ab" })
map.set("n", "t", "<nop>", { desc = "[T]ab" })

-- buffers
map.set("n", "<leader>b", "<NOP>", { desc = "Buffer" })
map.set("n", "<leader>bo", ":%bd|e#", { desc = "[B]uffer close all but [O]ne" })
map.set({ "n", "v" }, "<leader>bs", ":cd %:h<CR>", { desc = "[B]uffer [S]et path to current " })
