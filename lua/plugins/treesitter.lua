return {
  { -- Tree-sitter highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      -- Let find-msvc-tools (used by tree-sitter's cc crate) auto-detect the MSVC toolset
      -- version, headers, and libs. Setting only VCINSTALLDIR is enough to trigger its
      -- fast path without hardcoding any version-specific paths.
      if not vim.env.VCINSTALLDIR then
        vim.env.VCINSTALLDIR = 'C:\\Program Files (x86)\\Microsoft Visual Studio\\18\\BuildTools\\VC\\'
      end

      require('nvim-treesitter').setup {}

      require('nvim-treesitter').install {
        'bash', 'c', 'rust', 'c_sharp',
        'html', 'css', 'markdown', 'markdown_inline',
        'lua', 'vim', 'latex', 'vimdoc',
        'sql', 'json', 'regex', 'javascript',
      }

      -- Enable highlight with large-file guard
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
        callback = function(ev)
          local max_filesize = 200 * 1024 -- 200 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
          if ok and stats and stats.size > max_filesize then
            vim.treesitter.stop(ev.buf)
          else
            pcall(vim.treesitter.start, ev.buf)
          end
        end,
      })

      -- Enable treesitter-based indentation
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-indent', { clear = true }),
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
