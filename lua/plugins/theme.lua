-- color scheme
vim.o.termguicolors = true
vim.o.background = 'dark'
vim.o.signcolumn = 'yes'

-- How much foreground colors are blended toward the background in dimmed mode
-- (0 = unchanged, 1 = invisible). Default only: :ThemeDim [0-100] overrides it
-- and the last choice is remembered in stdpath('state')/theme-dim.json
local dim_amount = 0.10

return {
  { -- zen mode
    'folke/zen-mode.nvim',
    enabled = false,
    dependencies = {
      'folke/twilight.nvim',
    },
    opts = {
      window = {
        width = 1,
      },
      wezterm = {
        enabled = true,
      },
    },
  },
  { -- rainbow delimiter
    'HiPhish/rainbow-delimiters.nvim',
    enabled = false,
    config = function()
      -- This module contains a number of default definitions
      local rainbow_delimiters = require 'rainbow-delimiters'

      vim.g.rainbow_delimiters = {
        strategy = {
          [''] = rainbow_delimiters.strategy['global'],
          commonlisp = rainbow_delimiters.strategy['local'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
        priority = {
          [''] = 110,
          lua = 210,
        },
        highlight = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        },
        blacklist = { 'c', 'cpp' },
      }
    end,
  },
  { -- lspkind adds vscode-like pictograms
    'onsails/lspkind.nvim',
    config = function()
      local lspkind = require 'lspkind'
      lspkind.init()
    end,
  },
  { -- nvim-colorizer show colors in badges
    'catgoose/nvim-colorizer.lua',
    ft = { 'css', 'scss', 'sass', 'less', 'html', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'lua', 'conf', 'toml', 'yaml' },
    config = function()
      require('colorizer').setup {
        options = {
          parsers = {
            css = true, -- preset: enables names, hex, rgb, hsl, oklch
            tailwind = { enable = true },
          },
          display = {
            mode = 'virtualtext',
            virtualtext = { position = 'after' },
          },
        },
      }
    end,
  },
  { -- catppuccin
    'catppuccin/nvim',
    lazy = false,
    priority = 1000,
    config = function()
      local colors = F.get_colors 'custom'
      local palette = {
            mauve = colors.green[600],
            blue = colors.yellow[500],
            yellow = colors.green[500],
            overlay0 = colors.green[650],
            text = colors.blue[100], -- brighter main text (contrast 11.0 vs 7.8)

            rosewater = colors.red[300],
            flamingo = colors.pink[700],
            pink = colors.pink[500],
            red = colors.red[600],
            maroon = colors.purple[500],
            peach = colors.red[700],
            green = colors.brown[400],
            teal = colors.green[400],
            sky = colors.grey[550],
            sapphire = colors.blue[300],
            lavender = colors.blue[200],
            subtext1 = colors.grey[500],
            subtext0 = colors.grey[550],
            overlay2 = colors.grey[600],
            overlay1 = colors.grey[700],
            surface2 = colors.grey[800],
            surface1 = colors.grey[900],
            surface0 = colors.black[300],
            base = colors.black[350],
            mantle = colors.black[400],
            crust = colors.black[500],
      }

      -- Blend a '#rrggbb' color toward the background by `amount`
      local function blend(hex, background, amount)
        local pattern = '^#%x%x%x%x%x%x$'
        if type(hex) ~= 'string' or type(background) ~= 'string' or not hex:match(pattern) or not background:match(pattern) then
          return hex
        end
        local result = '#'
        for i = 2, 6, 2 do
          local foreground_channel = tonumber(hex:sub(i, i + 1), 16)
          local background_channel = tonumber(background:sub(i, i + 1), 16)
          result = result .. string.format('%02x', math.floor(foreground_channel * (1 - amount) + background_channel * amount + 0.5))
        end
        return result
      end

      -- Background colors keep their value; only foreground colors are dimmed
      local background_keys = { base = true, mantle = true, crust = true, surface0 = true, surface1 = true, surface2 = true }

      -- Last used dim amount and on/off state, remembered across restarts
      local state_file = vim.fs.joinpath(vim.fn.stdpath 'state', 'theme-dim.json')
      local state = { amount = dim_amount, dimmed = true }

      local function load_state()
        if vim.fn.filereadable(state_file) == 0 then
          return
        end
        local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(state_file), '\n'))
        if not ok or type(decoded) ~= 'table' then
          return
        end
        if type(decoded.amount) == 'number' and decoded.amount > 0 and decoded.amount <= 1 then
          state.amount = decoded.amount
        end
        if type(decoded.dimmed) == 'boolean' then
          state.dimmed = decoded.dimmed
        end
      end

      local function save_state()
        pcall(vim.fn.writefile, { vim.json.encode(state) }, state_file)
      end

      local function build_palette()
        if not state.dimmed then
          return palette
        end
        local result = {}
        for key, value in pairs(palette) do
          result[key] = background_keys[key] and value or blend(value, palette.base, state.amount)
        end
        return result
      end

      local function apply()
        vim.g.theme_dimmed = state.dimmed
        require('catppuccin').setup {
          color_overrides = {
            macchiato = build_palette(),
          },
        }
        vim.cmd.colorscheme 'catppuccin-macchiato'
        vim.cmd.hi 'Comment gui=none'
      end

      load_state()
      apply()

      -- :ThemeDim        toggle dimmed / normal
      -- :ThemeDim <0-100> dim by that percentage (0 = normal)
      vim.api.nvim_create_user_command('ThemeDim', function(command)
        if command.args == '' then
          state.dimmed = not state.dimmed
        else
          local percentage = tonumber(command.args)
          if not percentage or percentage < 0 or percentage > 100 then
            vim.notify('ThemeDim: expected a number from 0 to 100', vim.log.levels.ERROR)
            return
          end
          if percentage == 0 then
            state.dimmed = false
          else
            state.amount = percentage / 100
            state.dimmed = true
          end
        end
        save_state()
        apply()
        vim.notify(string.format('Theme colors: %s', state.dimmed and string.format('dimmed %g%%', state.amount * 100) or 'normal'))
      end, { nargs = '?', desc = 'Toggle dimmed theme colors, or set dim percentage (0-100)' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
