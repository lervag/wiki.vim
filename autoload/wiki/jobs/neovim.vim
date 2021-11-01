" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#jobs#neovim#run(cmd) abort " {{{1
  call s:neovim_{s:os}_run(a:cmd)
endfunction

" }}}1
function! wiki#jobs#neovim#capture(cmd) abort " {{{1
  return s:neovim_{s:os}_capture(a:cmd)
endfunction

" }}}1

let s:os = has('win32') ? 'win' : 'unix'


function! s:neovim_unix_run(cmd) abort " {{{1
  call system(['sh', '-c', a:cmd])
endfunction

" }}}1
function! s:neovim_unix_capture(cmd) abort " {{{1
  return systemlist(['sh', '-c', a:cmd])
endfunction

" }}}1

function! s:neovim_win_run(cmd) abort " {{{1
  let s:saveshell = [&shell, &shellcmdflag, &shellslash]
  set shell& shellcmdflag& shellslash&

  call system('cmd /s /c "' . a:cmd . '"')

  let [&shell, &shellcmdflag, &shellslash] = s:saveshell
endfunction

" }}}1
function! s:neovim_win_capture(cmd) abort " {{{1
  let s:saveshell = [&shell, &shellcmdflag, &shellslash]
  set shell& shellcmdflag& shellslash&

  let l:output = systemlist('cmd /s /c "' . a:cmd . '"')

  let [&shell, &shellcmdflag, &shellslash] = s:saveshell

  return l:output
endfunction

" }}}1

