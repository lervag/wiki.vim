" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#link#find_next() "{{{1
  call search(g:vimwiki_rxAnyLink, 's')
endfunction

" }}}1
function! vimwiki#link#find_prev() "{{{1
  if vimwiki#u#in_syntax('VimwikiLink')
        \ && vimwiki#u#in_syntax('VimwikiLink', line('.'), col('.')-1)
    call search(g:vimwiki_rxAnyLink, 'sb')
  endif
  call search(g:vimwiki_rxAnyLink, 'sb')
endfunction

" }}}1
function! vimwiki#link#go_back() "{{{1
  if exists('b:vimwiki_prev_link')
    let [l:file, l:pos] = b:vimwiki_prev_link
    execute ':e ' . substitute(l:file, '\s', '\\\0', 'g')
    call setpos('.', l:pos)
  else
    silent! pop!
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
