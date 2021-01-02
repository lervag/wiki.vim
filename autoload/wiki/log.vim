" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#log#warn(message) abort " {{{1
  echohl Title
  echo 'wiki: '
  echohl NONE
  echon a:message
endfunction

" }}}1
