vim.cmd [[
augroup SqlRecordsFiletype
  autocmd!
  autocmd BufRead,BufNewFile * if search('-\\[ RECORD \\d\\+ \\]---\\+\\%$', 'nw') | set filetype=sql_records | endif
augroup END
]]

