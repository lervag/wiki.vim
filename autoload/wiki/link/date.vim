" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#date#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), {
        \ 'type': 'date',
        \ 'scheme': 'journal',
        \ 'rx': g:wiki#rx#date,
        \})
endfunction

" }}}1
