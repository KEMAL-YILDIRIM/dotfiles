-- [[ Basic Keymaps ]]
--  See `:help map.set()`

local map = vim.keymap

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
map.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear highlight search in normal mode' })




-- TIP: Disable arrow tabKeys in normal mode
-- map.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- map.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- map.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- map.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
map.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- visual mode > move selected lines
map.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })


-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})


map.set("v", "<leader>+", "mzJ`z", { desc = "Adds up the next line to the current" })


-- keep the cursor in the center of page while navigating page up or down
map.set("n", "<C-d>", "<C-d>zz", { desc = "Page down while keeping cursor at the middle of the page" })
map.set("n", "<C-u>", "<C-u>zz", { desc = "Page down while keeping cursor at the middle of the page" })


-- preserve paste buffer
map.set("x", "<leader>p", [["_dP]], { desc = "Preserve [P]aste buffer" })

-- coppy to system clipboard so not loose it while navigate between files
map.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard text" })


map.set("n", "Q", "<nop>", { desc = "No map for Q" })


-- quick fix navigation
map.set('n', '<leader>qq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
map.set("n", "<leader>qn", "<cmd>cnext<CR>zz", { desc = "[Q]uickfix [N]ext error list" })
map.set("n", "<leader>qp", "<cmd>cprev<CR>zz", { desc = "[Q]uickfix [P]revious error list" })

-- tabs
local function tab_actions()
  -- move between tab commands without unnecessary repetations 
  local ns_id = vim.api.nvim_create_namespace("");
  print("Entered tab mode " .. ns_id)
  vim.on_key(function(_, key)
    if key == "n" then vim.cmd("tabnew") end
    if key == "c" then vim.cmd("tabc") end
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

map.set("n", "<leader>tm", tab_actions, { desc = "[t]ab [m]ode" })
map.set("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "[t]ab open [n]ew" })         -- open new tab
map.set("n", "<leader>tc", "<cmd>tabc<cr>", { desc = "[t]ab close [c]urrent" })      -- close current tab
map.set("n", "<leader>ta", "<cmd>tabo<cr>", { desc = "[t]ab close [a]ll but this" }) -- close current tab
map.set("n", "<leader>tl", "<cmd>tabn<cr>", { desc = "[t]ab [n]ext" })               --  go to next tab
map.set("n", "<leader>th", "<cmd>tabp<cr>", { desc = "[t]ab [p]revious" })           --  go to previous tab
map.set("n", "<leader>td", "<cmd>tabnew %<CR>", { desc = "[t]ab [d]uplicate current buffer in new tab" })
map.set("n", "<leader>tt", "<cmd>g:lasttat <CR>", { desc = "[t]ab open last used [t]ab" })
map.set("n", "<leader>t", "<nop>", { desc = "[t]ab" })

-- buffers
map.set("n", "<leader>b", "<NOP>", { desc = "[B]uffer" })
map.set("n", "<leader>bo", ":%bd|e#", { desc = "[B]uffer close all but [O]ne" })
map.set({ "n", "v" }, "<leader>bs", ":cd %:h<CR>", { desc = "[B]uffer [S]et path to current " })
