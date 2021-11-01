" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#jobs#vim#run(cmd) abort " {{{1
  call s:vim_{s:os}_run(a:cmd)
endfunction

" }}}1
function! wiki#jobs#vim#capture(cmd) abort " {{{1
  return s:vim_{s:os}_capture(a:cmd)
endfunction

" }}}1

let s:os = has('win32') ? 'win' : 'unix'


function! s:vim_unix_run(cmd) abort " {{{1
  silent! call system(a:cmd)
endfunction

" }}}1
function! s:vim_unix_capture(cmd) abort " {{{1
  silent! let l:output = systemlist(a:cmd)
  return v:shell_error == 127 ? ['command not found'] : l:output
endfunction

" }}}1

function! s:vim_win_run(cmd) abort " {{{1
  let s:saveshell = [
        \ &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash
        \]
  set shell& shellcmdflag& shellquote& shellxquote& shellredir& shellslash&

  silent! call system('cmd /s /c "' . a:cmd . '"')

  let [   &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash] = s:saveshell
endfunction

" }}}1
function! s:vim_win_capture(cmd) abort " {{{1
  let s:saveshell = [
        \ &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash
        \]
  set shell& shellcmdflag& shellquote& shellxquote& shellredir& shellslash&

  silent! let l:output = systemlist('cmd /s /c "' . a:cmd . '"')

  let [   &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash] = s:saveshell

  return l:output
endfunction

" }}}1

