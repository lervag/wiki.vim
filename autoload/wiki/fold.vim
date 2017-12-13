" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#fold#level(lnum) abort " {{{1
  let l:line = getline(a:lnum)

  if wiki#u#is_code(a:lnum)
    return l:line =~# '^\s*```'
          \ ? (wiki#u#is_code(a:lnum+1) ? 'a1' : 's1')
          \ : '='
  endif

  if l:line =~# wiki#rx#header()
    return '>' . len(matchstr(l:line, '#*'))
  endif

  return '='
endfunction

" }}}1
function! wiki#fold#text() abort " {{{1
  let l:line = getline(v:foldstart)
  let l:text = substitute(l:line, '^\s*', repeat(' ',indent(v:foldstart)), '')
  return l:text
endfunction

" }}}1

" vim: fdm=marker sw=2
