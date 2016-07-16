" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#nav#next_link() "{{{1
  call search(vimwiki#rx#link(), 's')
endfunction

" }}}1
function! vimwiki#nav#prev_link() "{{{1
  if vimwiki#u#in_syntax('wikiLink.*')
        \ && vimwiki#u#in_syntax('wikiLink.*', line('.'), col('.')-1)
    call search(vimwiki#rx#link(), 'sb')
  endif
  call search(vimwiki#rx#link(), 'sb')
endfunction

" }}}1
function! vimwiki#nav#return() "{{{1
  if exists('b:vimwiki.prev_link')
    let [l:file, l:pos] = b:vimwiki.prev_link
    execute ':e ' . substitute(l:file, '\s', '\\\0', 'g')
    call setpos('.', l:pos)
  else
    silent! pop!
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
