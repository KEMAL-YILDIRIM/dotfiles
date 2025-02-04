-- color scheme
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.signcolumn = "yes"

-- tailwind colors can be found at https://tailscan.com/_nuxt/colors.*.js
---Read the colors.json and gets the color palette
---@param theme string
---@return table
local function get_colors(theme)
  local cur_path = "~/AppData/Local/nvim/lua/colors.json"
  local content = ReadFile(cur_path)
  if content == nil then
    return {}
  end
  local colors = vim.json.decode(content)
  local formattedColors = {}
  for key, color in pairs(colors[theme]) do
    local item = {}
    for _, subColor in pairs(color) do
      if subColor ~= nil and subColor.value ~= nil and subColor.hex ~= nil then
        table.insert(item, subColor.value, subColor.hex)
      end
    end
    if key ~= nil then
      formattedColors[key] = item
    end
  end
  return formattedColors
end

return {
  { -- zen mode
    "folke/zen-mode.nvim",
    enabled = false,
    dependencies = {
      "folke/twilight.nvim",
    },
    opts = {
      window = {
        width = 1,
      },
      wezterm = {
        enabled = true,
      }
    }
  },
  { -- rainbow delimiter
    "HiPhish/rainbow-delimiters.nvim",
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
    end
  },
  { -- lspkind adds vscode-like pictograms
    'onsails/lspkind.nvim',
    config = function()
      local lspkind = require('lspkind')
      lspkind.init()
    end,
  },
  { -- lualine
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local lualine = require('lualine')
      -- local  options = {theme = 'palenight'}
      -- local  options = {theme = 'ayu_mirage'}
      local options = { theme = 'nightfly' }
      lualine.setup { options = options }
    end,
  },
  { -- nvim-colorizer show colors in badges
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    config = function()
      require('colorizer').setup({
        filetypes = {
          "*",
          css = { names = true },
          html = { names = true }
        },
        user_default_options = { css = true, css_fn = true, mode = 'foreground', names = false }
      })
    end
  },
  { -- catppuccin
    'catppuccin/nvim',
    lazy = false,
    priority = 1000,
    config = function()
      local colors = get_colors("custom")
      require('catppuccin').setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false
        },
        color_overrides = {
          macchiato = {
            mauve = colors.green[600],
            blue = colors.yellow[500],
            yellow = colors.green[500],
            overlay0 = colors.green[900],
            text = colors.blue[200],

            rosewater = colors.red[300],
            flamingo = colors.pink[700],
            pink = colors.pink[500],
            red = colors.red[500],
            maroon = colors.purple[500],
            peach = colors.red[700],
            green = colors.brown[500],
            teal = colors.green[400],
            sky = colors.blue[600],
            sapphire = colors.blue[700],
            lavender = colors.blue[500],
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
        }
      })

      vim.cmd.colorscheme 'catppuccin-macchiato'

      vim.cmd.hi 'Comment gui=none'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
