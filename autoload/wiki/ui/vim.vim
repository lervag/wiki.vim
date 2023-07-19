" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#ui#vim#confirm(prompt) abort " {{{1
  return wiki#ui#legacy#confirm(a:prompt)
endfunction

" }}}1
function! wiki#ui#vim#input(options) abort " {{{1
  return wiki#ui#legacy#input(a:options)
endfunction

" }}}1
function! wiki#ui#vim#select(options, list) abort " {{{1
  return wiki#ui#legacy#select(a:options, a:list)
endfunction

" }}}1
