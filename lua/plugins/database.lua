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
    -- appends `-W` and a unit-separator column separator, so query results trim
    -- columns to content; align_result_tables below realigns them into a table.
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

    -- SQL Server result tables (mssqlfmt adapter: sqlcmd -W, unit separator).
    -- sqlcmd ends every row with CRLF, but values may contain bare line breaks,
    -- so one database row can span several buffer lines. align_result_tables
    -- rebuilds each row, shortens every cell to its column width (ending in '…',
    -- line breaks shown as '↵') and pads it with spaces into a fixed-width table.
    -- The full values are kept in cells_by_buffer for the hover window and yc.
    -- Every column except the last is padded one extra character (dash run
    -- included) so columns look two spaces apart while the underline keeps the
    -- single-space separator vim-dadbod-ui's yank-header (yh) expects.
    local cell_width_cap = 12

    -- ASCII unit separator (U+001F): the column separator the mssqlfmt adapter
    -- passes to sqlcmd. Real text never contains it, unlike tabs.
    local separator = string.char(31)

    local function count_separators(text)
      return #vim.split(text, separator, { plain = true }) - 1
    end

    -- Split a database row into exactly column_count cells. Should a value ever
    -- contain the separator, the surplus pieces are joined back into the last
    -- column instead of shifting every later cell one column to the right.
    local function split_row(text, column_count)
      local cells = vim.split(text, separator, { plain = true })
      if #cells > column_count then
        local tail = table.concat(cells, ' ', column_count)
        for index = #cells, column_count + 1, -1 do
          cells[index] = nil
        end
        cells[column_count] = tail
      end
      return cells
    end

    -- cells_by_buffer[buffer][line] = list of { first, last, value, truncated },
    -- where first/last are the screen columns the cell occupies.
    local cells_by_buffer = {}

    local function flatten(value)
      return (value:gsub('\r?\n', '↵'):gsub('[\r\t]', ' '))
    end

    -- Returns the value shortened to `width` screen cells, and whether the
    -- displayed text differs from the full value.
    local function fit_cell(value, width)
      local flat = flatten(value)
      if vim.api.nvim_strwidth(flat) <= width then
        return flat, flat ~= value
      end
      local kept, used = {}, 0
      for _, character in ipairs(vim.fn.split(flat, [[\zs]])) do
        local character_width = vim.api.nvim_strwidth(character)
        if used + character_width > width - 1 then
          break
        end
        kept[#kept + 1] = character
        used = used + character_width
      end
      return table.concat(kept) .. '…', true
    end

    local function pad(text, width)
      return text .. string.rep(' ', width - vim.api.nvim_strwidth(text))
    end

    local function align_result_tables(buffer)
      -- Skip if this exact buffer content was already aligned (FileType can fire
      -- again without a reload, and the original values would then be lost).
      if vim.b[buffer].dbout_aligned_tick == vim.api.nvim_buf_get_changedtick(buffer) then
        return
      end

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      local output, cells = {}, {}
      local line_index = 1
      while line_index <= #lines do
        local header_raw = lines[line_index]
        local header = (header_raw:gsub('\r$', ''))
        local underline = ((lines[line_index + 1] or ''):gsub('\r$', ''))
        if header ~= '' and underline:match('^%-[%-' .. separator .. ']*$') then
          local uses_carriage_return = header_raw:sub(-1) == '\r'
          local column_count = count_separators(underline) + 1
          local headers = vim.split(header, separator, { plain = true })

          -- Rebuild database rows: a row is complete once it holds every column
          -- separator and (when sqlcmd wrote CRLF) its line ends in '\r'.
          local rows = {}
          local current, current_separators = nil, 0
          local next_index = line_index + 2
          while next_index <= #lines do
            local raw = lines[next_index]
            local ends_row = raw:sub(-1) == '\r'
            local text = ends_row and raw:sub(1, -2) or raw
            if current == nil and text == '' then
              break
            end
            current = current and (current .. '\n' .. text) or text
            current_separators = current_separators + count_separators(text)
            next_index = next_index + 1
            if current_separators >= column_count - 1 and (ends_row or not uses_carriage_return) then
              rows[#rows + 1] = split_row(current, column_count)
              current, current_separators = nil, 0
            end
          end
          if current then
            rows[#rows + 1] = split_row(current, column_count)
          end

          -- Column width: the header, or the widest value capped at cell_width_cap.
          local widths = {}
          for column = 1, column_count do
            local widest = 1
            for _, row in ipairs(rows) do
              widest = math.max(widest, vim.api.nvim_strwidth(flatten(row[column] or '')))
            end
            widths[column] = math.max(vim.api.nvim_strwidth(headers[column] or ''), math.min(widest, cell_width_cap), 1)
          end
          local function padded_width(column)
            return widths[column] + (column < column_count and 1 or 0)
          end

          local header_parts, underline_parts = {}, {}
          for column = 1, column_count do
            header_parts[column] = pad(headers[column] or '', padded_width(column))
            underline_parts[column] = string.rep('-', padded_width(column))
          end
          output[#output + 1] = (table.concat(header_parts, ' '):gsub('%s+$', ''))
          output[#output + 1] = table.concat(underline_parts, ' ')

          for _, row in ipairs(rows) do
            local parts, row_cells, first = {}, {}, 1
            for column = 1, column_count do
              local value = row[column] or ''
              local shown, truncated = fit_cell(value, widths[column])
              parts[column] = pad(shown, padded_width(column))
              local last = first + padded_width(column)
              row_cells[column] = { first = first, last = last, value = value, truncated = truncated }
              first = last + 1
            end
            output[#output + 1] = (table.concat(parts, ' '):gsub('%s+$', ''))
            cells[#output] = row_cells
          end

          line_index = next_index
        else
          output[#output + 1] = header
          line_index = line_index + 1
        end
      end

      cells_by_buffer[buffer] = cells
      if table.concat(output, '\n') ~= table.concat(lines, '\n') then
        -- Rewrite without an undo step and keep the buffer unmodified, so the
        -- result window never prompts to save.
        local buffer_options = vim.bo[buffer]
        local modifiable, undolevels = buffer_options.modifiable, buffer_options.undolevels
        buffer_options.modifiable = true
        buffer_options.undolevels = -1
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, output)
        buffer_options.undolevels = undolevels
        buffer_options.modifiable = modifiable
        buffer_options.modified = false
      end
      vim.b[buffer].dbout_aligned_tick = vim.api.nvim_buf_get_changedtick(buffer)
    end

    local function cell_under_cursor()
      local buffer_cells = cells_by_buffer[vim.api.nvim_get_current_buf()]
      local row = buffer_cells and buffer_cells[vim.fn.line '.']
      if not row then
        return nil
      end
      local screen_column = vim.fn.virtcol '.'
      for _, cell in ipairs(row) do
        if screen_column >= cell.first and screen_column <= cell.last then
          return cell
        end
      end
    end

    -- Show the full value of the cell under the cursor in a floating window.
    -- Automatic (focus = false): only for shortened cells. K (focus = true):
    -- always, and moves into the window so long values can be scrolled.
    local function show_cell(focus)
      local cell = cell_under_cursor()
      if not cell or (not focus and not cell.truncated) then
        return
      end
      local syntax = cell.value:match '^%s*<' and 'html' or 'text'
      local _, float_window = vim.lsp.util.open_floating_preview(vim.split(cell.value, '\r?\n'), syntax, {
        border = 'rounded',
        focus_id = 'dbout_cell_value',
        focus = focus,
        max_width = math.floor(vim.o.columns * 0.8),
        max_height = math.floor(vim.o.lines * 0.6),
        close_events = { 'CursorMoved', 'BufLeave', 'InsertEnter' },
      })
      if focus and float_window and vim.api.nvim_win_is_valid(float_window) then
        vim.api.nvim_set_current_win(float_window)
      end
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
        -- Yank the full (not shortened) value of the cell under the cursor.
        vim.keymap.set('n', 'yc', function()
          local cell = cell_under_cursor()
          if not cell then
            vim.notify('No result cell under cursor', vim.log.levels.WARN)
            return
          end
          vim.fn.setreg(vim.v.register, cell.value)
        end, { buffer = true, desc = 'Yank full cell value' })
        vim.keymap.set('n', 'K', function()
          show_cell(true)
        end, { buffer = true, desc = 'Show full cell value' })

        -- Hover: show the full value of a shortened cell when the cursor rests.
        local hover_group = vim.api.nvim_create_augroup('DadbodCellHover' .. args.buf, { clear = true })
        vim.api.nvim_create_autocmd('CursorHold', {
          group = hover_group,
          buffer = args.buf,
          callback = function()
            show_cell(false)
          end,
        })
        vim.api.nvim_create_autocmd('BufWipeout', {
          group = hover_group,
          buffer = args.buf,
          callback = function()
            cells_by_buffer[args.buf] = nil
          end,
        })
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
