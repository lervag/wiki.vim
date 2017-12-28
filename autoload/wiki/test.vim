" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#test#init() abort " {{{1
  set noswapfile
  let v:errors = []
  nnoremap q :qall!<cr>
endfunction

" }}}1
function! wiki#test#quit() abort " {{{1
  if !empty(v:errors)
    for l:error in v:errors
      verbose echo l:error . ' (' . v:progname . ')'
    endfor
    verbose echo ''
  endif

  if $QUIT
    if !empty(v:errors)
      cquit
    else
      quitall!
    endif
  endif
endfunction

" }}}1

function! wiki#test#error(fname, msg) abort " {{{1
  call add(v:errors, fnamemodify(a:fname, ':t') . ': ' . a:msg)
endfunction

" }}}1
function! wiki#test#append(msg) abort " {{{1
  if type(a:msg) == type([])
    call extend(v:errors, a:msg)
  else
    call add(v:errors, a:msg)
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
