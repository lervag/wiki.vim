" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#doi#handler(url) abort " {{{1
  return wiki#url#generic#handler({
        \ 'url' : 'http://dx.doi.org/' . a:url.stripped,
        \})
endfunction

" }}}1
