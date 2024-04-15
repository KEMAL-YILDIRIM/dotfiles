-- [[ Basic Keymaps ]]
--  See `:help map.set()`

local map = vim.keymap

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
map.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear highlight search in normal mode' })

-- Diagnostic keymaps
map.set('n', '<leader>-m', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
map.set('n', '<leader>-m', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
map.set('n', '<leader>--', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })


-- TIP: Disable arrow keys in normal mode
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


map.set({ "n", "v" },"<leader>cd", ":cd %:h<CR>", { desc = "Set path to current buffer" })
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
map.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "[T]ab [O]pen new" })        -- open new tab
map.set("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "[T]ab [C]lose current" }) -- close current tab
map.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "[T]ab go to next" })          --  go to next tab
map.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "[T]ab go to previous" })      --  go to previous tab
map.set("n", "<leader>tb", "<cmd>tabnew %<CR>", { desc = "[T]ab open current [B]uffer in new tab" })
