" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#fold#level(lnum) " {{{1
  let l:line = getline(a:lnum)

  if vimwiki#u#is_code(a:lnum)
    return l:line =~# '^\s*```'
          \ ? (vimwiki#u#is_code(a:lnum+1) ? 'a1' : 's1')
          \ : '='
  endif

  if l:line =~# vimwiki#rx#header()
    return '>' . len(matchstr(l:line, '#*'))
  endif

  return '='
endfunction

" }}}1
function! vimwiki#fold#text() " {{{1
  let l:line = getline(v:foldstart)
  let l:text = substitute(l:line, '^\s*', repeat(' ',indent(v:foldstart)), '')
  return l:text
endfunction

" }}}1

" vim: fdm=marker sw=2
