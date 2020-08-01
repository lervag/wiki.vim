" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#url#matcher() abort " {{{1
  return {
        \ 'type' : 'url',
        \ 'toggle' : function('wiki#link#md#template'),
        \ 'rx' : g:wiki#rx#url,
        \}
endfunction

" }}}1
