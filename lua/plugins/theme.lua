return {
  --[[ {
    "folke/zen-mode.nvim",
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
  }, ]]
  {
    'onsails/lspkind.nvim', -- adds vscode-like pictograms
    config = function()
      local lspkind = require('lspkind')
      lspkind.init()
    end,
  },
  {
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
  {
    -- show colors in badges
    'norcalli/nvim-colorizer.lua',
    config = function()
      require 'colorizer'.setup();
    end
  },
  {
    'catppuccin/nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('catppuccin').setup({
        color_overrides = {
          macchiato = {
            mauve = "#229cc3",
            blue = "#dcdcaa",
            yellow = "#94ddcf",
            overlay0 = "#646432",
            text = "#9bdbfd",

            rosewater = "#efc9c2",
            flamingo = "#ebb2b2",
            pink = "#c295b6",
            red = "#ea7183",
            maroon = "#ea838c",
            peach = "#f39967",
            green = "#9d775e",
            teal = "#78cec1",
            sky = "#91d7e3",
            sapphire = "#68bae0",
            lavender = "#a0a8f6",
            subtext1 = "#a6b0d8",
            subtext0 = "#959ec2",
            overlay2 = "#848cad",
            overlay1 = "#717997",
            surface2 = "#505469",
            surface1 = "#3e4255",
            surface0 = "#2c2f40",
            base = "#1a1c2a",
            mantle = "#141620",
            crust = "#0e0f16",
          }
        }
      })

      vim.cmd.colorscheme 'catppuccin-macchiato'

      vim.cmd.hi 'Comment gui=none'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
