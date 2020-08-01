" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#date#matcher() abort " {{{1
  return {
        \ 'type' : 'date',
        \ 'scheme' : 'journal',
        \ 'toggle' : function('wiki#link#wiki#template'),
        \ 'rx' : g:wiki#rx#date,
        \}
endfunction

" }}}1
