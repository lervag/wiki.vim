" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#test#assert(condition) abort " {{{1
  if a:condition | return 1 | endif

  call s:fail()
endfunction

" }}}1
function! wiki#test#assert_equal(expect, observe) abort " {{{1
  if a:expect ==# a:observe | return 1 | endif

  call s:fail([
        \ 'expect:  ' . string(a:expect),
        \ 'observe: ' . string(a:observe),
        \])
endfunction

" }}}1
function! wiki#test#assert_match(x, regex) abort " {{{1
  if a:x =~# a:regex | return 1 | endif

  call s:fail([
        \ 'x = ' . a:x,
        \ 'regex = ' . a:regex,
        \])
endfunction

" }}}1

function! wiki#test#completion(context, ...) abort " {{{1
  let l:base = a:0 > 0 ? a:1 : ''

  try
    silent execute 'normal GO' . a:context . "\<c-x>\<c-o>"
    silent normal! u
    return wiki#complete#omnicomplete(0, l:base)
  catch /.*/
    call s:fail(v:exception)
  endtry
endfunction

" }}}1

function! s:fail(...) abort " {{{1
  call wiki#log#warn('Assertion failed!')

  if a:0 > 0 && !empty(a:1)
    if type(a:1) == type('')
      echo a:1
    else
      for line in a:1
        echo line
      endfor
    endif
  endif
  echon "\n"

  cquit
endfunction

" }}}1
