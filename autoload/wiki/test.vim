" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#test#assert(condition) abort " {{{1
  if a:condition | return 1 | endif

  echo 'Assertion failed!'
  cquit
endfunction

" }}}1
function! wiki#test#assert_equal(x, y) abort " {{{1
  if a:x ==# a:y | return 1 | endif

  echo 'Assertion failed!'
  echo 'x =' a:x
  echo 'y =' a:y
  echo "---\n"
  cquit
endfunction

" }}}1
function! wiki#test#assert_match(x, regex) abort " {{{1
  if a:x =~# a:regex | return 1 | endif

  echo 'Assertion failed!'
  echo 'x =' a:x
  echo 'regex =' a:regex
  echo "---\n"
  cquit
endfunction

" }}}1
