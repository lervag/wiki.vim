" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#url#man#parse(url) abort " {{{1
  let l:url = {}

  function! l:url.open(...) abort dict
    execute 'edit' fnameescape(self.path)
  endfunction

  let l:url.path = 'man://' . matchstr(a:url.url, 'man:\(\/\/\)\?\zs.*')

  return l:url
endfunction

" }}}1
