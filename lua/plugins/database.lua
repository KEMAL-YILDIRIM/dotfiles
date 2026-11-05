local _ft = { 'dbout', 'dbui', '*sql' }
return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', ft = _ft, event = 'BufEnter' },
    { 'kristijanhusak/vim-dadbod-completion', ft = _ft, event = 'BufEnter' },
  },
  lazy = true,
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    -- Use a custom SQL Server adapter (autoload/db/adapter/mssqlfmt.vim) that
    -- appends `-W -s '  '` so query results trim columns to content and separate
    -- them with two spaces instead of sqlcmd's wide fixed-width padding.
    vim.g.db_adapter_sqlserver = 'db#adapter#mssqlfmt#'

    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_disable_mappings = 1
    vim.g.db_ui_execute_on_save = 0
    -- Your DBUI configuration

    vim.g.db_ui_winwidth = 40
    vim.g.db_ui_use_nvim_notify = 1
    vim.g.db_ui_icons = {
      expanded = '',
      collapsed = '',
      saved_query = '',
      new_query = '󰎔',
      tables = '󰓫',
      buffers = '',
      connection_ok = '✓',
      connection_error = '✕',
    }

    local group = vim.api.nvim_create_augroup('DadbodMappings', { clear = true })

    -- Seed stored-procedure helper queries into each DBUI connection's save folder.
    -- vim-dadbod-ui's drawer only lists tables/views, never procedures, so we expose
    -- catalog queries as saved queries instead. Runs on every DBUIOpened, keyed off
    -- connections.json, so any newly added connection gets the helpers automatically.
    -- NOTE: only covers file-based connections (connections.json), not g:dbs.
    local function seed_dbui_helpers()
      local save_loc = vim.fn.fnamemodify(vim.g.db_ui_save_location or '~/.local/share/db_ui', ':p')
      save_loc = save_loc:gsub('[\\/]$', '')
      local conn_file = save_loc .. '/connections.json'
      if vim.fn.filereadable(conn_file) == 0 then
        return
      end
      local ok, conns = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(conn_file), '\n'))
      if not ok or type(conns) ~= 'table' then
        return
      end

      local helpers = {
        ['list-procedures'] = table.concat({
          'SELECT ROUTINE_SCHEMA, ROUTINE_NAME',
          'FROM INFORMATION_SCHEMA.ROUTINES',
          "WHERE ROUTINE_TYPE = 'PROCEDURE'",
          'ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME;',
        }, '\n'),
        ['proc-definition'] = table.concat({
          '-- Replace with your procedure name, then execute (<leader>dbe)',
          "EXEC sp_helptext N'dbo.YourProcName';",
        }, '\n'),
        ['search-procedures'] = table.concat({
          "-- Replace 'SearchText', then execute (<leader>dbe)",
          'SELECT ROUTINE_SCHEMA, ROUTINE_NAME',
          'FROM INFORMATION_SCHEMA.ROUTINES',
          "WHERE ROUTINE_TYPE = 'PROCEDURE'",
          "  AND ROUTINE_DEFINITION LIKE '%SearchText%'",
          'ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME;',
        }, '\n'),
      }

      for _, conn in ipairs(conns) do
        local name = conn.name
        if type(name) == 'string' and name ~= '' then
          local dir = save_loc .. '/' .. name
          if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, 'p')
          end
          for fname, content in pairs(helpers) do
            local path = dir .. '/' .. fname
            if vim.fn.filereadable(path) == 0 then
              vim.fn.writefile(vim.split(content, '\n'), path)
            end
          end
        end
      end
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'DBUIOpened',
      group = group,
      callback = seed_dbui_helpers,
      desc = 'Seed stored-procedure helper queries into each DBUI connection',
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*sql',
      group = group,
      callback = function()
        vim.keymap.set('n', '<leader>dbs', '<Plug>(DBUI_SaveQuery)', { buffer = true })
        vim.keymap.set('n', '<leader>dbe', '<Plug>(DBUI_ExecuteQuery)', { buffer = true })
        vim.keymap.set('n', '<leader>db.', '<Plug>(DBUI_ToggleResultLayout)', { buffer = true })
        vim.keymap.set('n', '<leader>dbq', '<Plug>(DBUI_Quit)', { buffer = true })
        vim.keymap.set('n', '<leader>dbr', '<Plug>(DBUI_Redraw)', { buffer = true })
      end,
      desc = 'Set keymaps for sql',
    })

    -- Realign the tab-separated sqlcmd output produced by the mssqlfmt adapter
    -- (-W -s "\t") into a fixed-width table made of real spaces. vim-dadbod-ui's
    -- yank-header (yh) and yank-cell (yc) read column boundaries from character
    -- positions in the `-----` underline, so the alignment must live in the
    -- buffer text, not only on screen. Every column except the last is padded
    -- one extra character (its dash run included) so columns look two spaces
    -- apart while the underline keeps a single-space separator, as yh expects.
    local function align_result_tables(buffer)
      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      local changed = false
      local line_index = 1
      while line_index < #lines do
        local header = lines[line_index]
        local underline = lines[line_index + 1]
        if header ~= '' and underline:match '^%-[%-\t]*$' then
          -- A result block is header, underline, then rows up to a blank line.
          local block_last = line_index + 1
          while block_last < #lines and lines[block_last + 1] ~= '' do
            block_last = block_last + 1
          end

          local rows = {}
          local widths = {}
          for row_index = line_index, block_last do
            local cells = vim.split(lines[row_index], '\t', { plain = true })
            rows[#rows + 1] = cells
            if row_index ~= line_index + 1 then
              for column, cell in ipairs(cells) do
                widths[column] = math.max(widths[column] or 1, vim.fn.strdisplaywidth(cell))
              end
            end
          end

          local column_count = math.max(#widths, #rows[2])
          for column = 1, column_count do
            widths[column] = (widths[column] or 1) + (column < column_count and 1 or 0)
          end

          for offset, cells in ipairs(rows) do
            local parts = {}
            for column = 1, column_count do
              if offset == 2 then
                parts[column] = string.rep('-', widths[column])
              else
                local cell = cells[column] or ''
                parts[column] = cell .. string.rep(' ', widths[column] - vim.fn.strdisplaywidth(cell))
              end
            end
            local aligned = (table.concat(parts, ' '):gsub('%s+$', ''))
            local target = line_index + offset - 1
            if aligned ~= lines[target] then
              lines[target] = aligned
              changed = true
            end
          end

          line_index = block_last + 1
        else
          line_index = line_index + 1
        end
      end

      if not changed then
        return
      end
      -- Rewrite without an undo step and keep the buffer unmodified, so the
      -- result window never prompts to save.
      local buffer_options = vim.bo[buffer]
      local modifiable, undolevels = buffer_options.modifiable, buffer_options.undolevels
      buffer_options.modifiable = true
      buffer_options.undolevels = -1
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
      buffer_options.undolevels = undolevels
      buffer_options.modifiable = modifiable
      buffer_options.modified = false
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'dbout',
      group = group,
      callback = function(args)
        -- Runs after every query: vim-dadbod reloads the result buffer with
        -- `edit!`, which fires FileType again on the final output.
        vim.opt_local.wrap = false
        align_result_tables(args.buf)

        local original_max_var_type_width = vim.env.SQLCMDMAXVARTYPEWIDTH
        local original_max_fixed_type_width = vim.env.SQLCMDMAXFIXEDTYPEWIDTH

        -- Toggle the per-cell width cap between original and unlimited (0).
        -- Columns are trimmed to content by the mssqlfmt adapter (-W) and
        -- realigned above; this only lifts the length cap so long
        -- text columns (e.g. stored-procedure bodies) print in full.
        vim.keymap.set('n', '<leader>dbw', function()
          if vim.env.SQLCMDMAXVARTYPEWIDTH == original_max_var_type_width then
            vim.env.SQLCMDMAXFIXEDTYPEWIDTH = '0'
            vim.env.SQLCMDMAXVARTYPEWIDTH = '0'
            vim.notify 'Column width: unlimited'
          else
            vim.env.SQLCMDMAXFIXEDTYPEWIDTH = original_max_fixed_type_width
            vim.env.SQLCMDMAXVARTYPEWIDTH = original_max_var_type_width
            vim.notify 'Column width: original'
          end
        end, { desc = 'Toggle unlimited column width' })

        vim.keymap.set('n', 'yh', '<Plug>(DBUI_YankHeader)', { buffer = true })
        vim.keymap.set('n', 'yc', '<Plug>(DBUI_YankCellValue)', { buffer = true })
      end,
      desc = 'Set keymaps for dbout',
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'dbui',
      group = group,
      callback = function()
        vim.keymap.set('n', 'l', '<Plug>(DBUI_SelectLine)', { buffer = true })
        vim.keymap.set('n', 'L', '<Plug>(DBUI_SelectLineVsplit)', { buffer = true })
        vim.keymap.set('n', 'd', '<Plug>(DBUI_DeleteLine)', { buffer = true })
        vim.keymap.set('n', 'fk', '<Plug>(DBUI_JumpToForeignKey)', { buffer = true })
        vim.keymap.set('n', 'a', '<Plug>(DBUI_AddConnection)', { buffer = true })
        vim.keymap.set('n', 'r', '<Plug>(DBUI_RenameLine)', { buffer = true })
      end,
      desc = 'Set keymaps for dbui',
    })

    --[[
		-- HACK: Override `sqlcmd` just when about to execute a query and restore it after execution
		-- I want to have `-k` argument for sqlcmd: `/path/to/sqlcmd $@ -k 1`
		local path = vim.env.PATH
		vim.api.nvim_create_autocmd({ "User" }, {
			group = group,
			pattern = "DBExecutePre",
			callback = function()
				path = vim.env.PATH -- Update the path directly before executing
				vim.env.PATH = vim.fn.expand("~/.local/bin") .. ":" .. vim.env.PATH
			end,
		})

		vim.api.nvim_create_autocmd({ "User" }, {
			group = group,
			pattern = "DBExecutePost",
			callback = function()
				vim.env.PATH = path
			end,
		})
		]]
  end,
}
