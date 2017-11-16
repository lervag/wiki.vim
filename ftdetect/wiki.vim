augroup filetypedetect
  autocmd BufRead,BufNewFile *.wiki call s:set_filetype()
augroup END

function! s:set_filetype()
  let l:wikiroot = resolve(g:wiki.root)
  let l:fileroot = strpart(resolve(expand('%:p')), 0, strlen(l:wikiroot))

  if l:fileroot ==# l:wikiroot
    set filetype=wiki
  endif
endfunction
