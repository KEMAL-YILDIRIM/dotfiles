" Custom SQL Server adapter for vim-dadbod.
" Delegates to the bundled sqlserver adapter and only appends formatting flags:
"   -W           strip trailing whitespace / trim columns to content width
"   -s "\t"      use a tab column separator (sqlcmd only accepts one character)
" The tab-separated output is realigned into a fixed-width table by the
" `FileType dbout` autocommand in lua/plugins/database.lua.
" Activated via `let g:db_adapter_sqlserver = 'db#adapter#mssqlfmt#'`.
" Lives in the config repo (not the plugin dir) so it survives plugin updates.

function! db#adapter#mssqlfmt#canonicalize(url) abort
  return db#adapter#sqlserver#canonicalize(a:url)
endfunction

function! db#adapter#mssqlfmt#interactive(url) abort
  return db#adapter#sqlserver#interactive(a:url) + ['-W', '-s', "\t"]
endfunction

function! db#adapter#mssqlfmt#input(url, in) abort
  return db#adapter#mssqlfmt#interactive(a:url) + ['-i', a:in]
endfunction

function! db#adapter#mssqlfmt#dbext(url) abort
  return db#adapter#sqlserver#dbext(a:url)
endfunction

function! db#adapter#mssqlfmt#tables(url) abort
  return db#adapter#sqlserver#tables(a:url)
endfunction

function! db#adapter#mssqlfmt#complete_database(url) abort
  return db#adapter#sqlserver#complete_database(a:url)
endfunction
