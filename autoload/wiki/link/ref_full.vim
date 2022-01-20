" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#ref_full#matcher() abort " {{{1
  let l:matcher = g:wiki#link#ref_shortcut#matcher()

  let l:matcher.rx = g:wiki#rx#link_ref_full
  let l:matcher.rx_target =
        \   '\['    . g:wiki#rx#reftext   . '\]'
        \ . '\[\zs' . g:wiki#rx#reflabel . '\ze\]'
  let l:matcher.rx_text =
        \   '\[\zs' . g:wiki#rx#reftext   . '\ze\]'
        \ . '\['    . g:wiki#rx#reflabel . '\]'

  return l:matcher
endfunction

" }}}1
