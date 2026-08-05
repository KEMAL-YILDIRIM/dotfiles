return {
  {
    'conductor.nvim',
    dir = 'D:/projects/conductor.nvim', -- local development checkout
    dependencies = { 'nvim-telescope/telescope.nvim', 'folke/snacks.nvim' },
    cmd = 'Conductor',
    keys = {
      { '<leader>ac', '<CMD>Conductor browse<CR>', desc = 'Agent session browser (cwd)' },
      { '<leader>aa', '<CMD>Conductor browse_all<CR>', desc = 'Agent session browser (all projects)' },
      { '<leader>as', '<CMD>Conductor sessions<CR>', desc = 'Agent sessions fuzy (all projects)' },
      { '<leader>af', '<CMD>Conductor here<CR>', desc = 'Agent sessions fuzy (cwd)' },
      { '<leader>al', '<CMD>Conductor panel<CR>', desc = 'Agent live sessions' },
      { '<leader>an', '<CMD>Conductor new<CR>', desc = 'Agent new session' },
    },
    opts = {
      terminal = {
        backend = 'external',
        open = function(o)
          -- On Windows, `wezterm cli spawn -- pi ...` runs pi.cmd, a batch shim
          -- that re-expands %* and mangles arguments containing spaces (e.g.
          -- session paths under "C:\Users\Kemal Yildirim\"). Hand the command to
          -- PowerShell so argv is parsed once, cleanly.
          local function pwsh_quote(s)
            return "'" .. tostring(s):gsub("'", "''") .. "'"
          end
          local parts = {}
          for _, a in ipairs(o.argv) do
            parts[#parts + 1] = pwsh_quote(a)
          end
          local cmd = '& ' .. table.concat(parts, ' ')
          return vim
            .system({ 'wezterm', 'cli', 'spawn', '--cwd', o.cwd, '--', 'pwsh', '-NoLogo', '-NoExit', '-Command', cmd })
            :wait().code == 0
        end,
      },
      keymaps = {
        browser_list = {
          open = '<CR>', -- open session content in the main window
          resume = 'gr', -- resume in a terminal
          toggle_cwd = 'gc', -- toggle cwd-only / all-projects filter
          refresh = 'g.', -- refresh the session list
        },
      },
    },
    config = function(_, opts)
      require('conductor').setup(opts)
      require('telescope').load_extension 'conductor'
    end,
  },
}
