" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#url#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), {
        \ 'type': 'url',
        \ 'rx': g:wiki#rx#url,
        \})
endfunction

" }}}1
