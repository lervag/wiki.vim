augroup filetypedetect
  autocmd BufRead,BufNewFile *.wiki call s:set_filetype()
augroup END

function! s:set_filetype()
  let l:fileroot = strpart(expand('%:p'), 0, strlen(g:wiki.root))

  if l:fileroot ==# g:wiki.root
    set filetype=wiki
  endif
endfunction
