if exists("s:did_ftdetect") | finish | endif
let s:did_ftdetect = 1

augroup filetypedetect
  autocmd BufRead,BufNewFile *.wiki call s:set_filetype()
augroup END

function! s:set_filetype() " {{{1
  if expand('%:p') =~# 'documents\/wiki'
    set filetype=vimwiki
  endif
endfunction

" }}}1
