" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#ref_double#matcher() abort " {{{1
  let l:matcher = g:wiki#link#ref_single#matcher()

  let l:matcher.rx = g:wiki#rx#link_ref_double
  let l:matcher.rx_target =
        \   '\['    . g:wiki#rx#reftext   . '\]'
        \ . '\[\zs' . g:wiki#rx#reftarget . '\ze\]'
  let l:matcher.rx_text =
        \   '\[\zs' . g:wiki#rx#reftext   . '\ze\]'
        \ . '\['    . g:wiki#rx#reftarget . '\]'

  return l:matcher
endfunction

" }}}1
