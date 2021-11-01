" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" These are wrapper functions for starting processes. They are created to give
" a unified interface that should work reliably on both Vim and neovim on all
" OSes.

function! wiki#jobs#run(cmd, ...) abort " {{{1
  " Run an external process.
  "
  " The optional argument is a dictionary of options. Each option is parsed in
  " the code below.
  "
  " Return: Nothing.
  let l:opts = a:0 > 0 ? a:1 : {}

  call wiki#paths#pushd(get(l:opts, 'cwd', ''))
  call wiki#jobs#{s:backend}#run(a:cmd)
  call wiki#paths#popd()
endfunction

" }}}1
function! wiki#jobs#capture(cmd, ...) abort " {{{1
  " Run an external process and capture the command output.
  "
  " The optional argument is a dictionary of options. Each option is parsed in
  " the code below.
  "
  " Return: Command output as list of strings.
  let l:opts = a:0 > 0 ? a:1 : {}

  call wiki#paths#pushd(get(l:opts, 'cwd', ''))
  let l:output = wiki#jobs#{s:backend}#capture(a:cmd)
  call wiki#paths#popd()

  return l:output
endfunction

" }}}1
function! wiki#jobs#cached(cmd) abort " {{{1
  " Cached version of wiki#jobs#capture(...)
  let l:cache = wiki#cache#open('capture')

  return l:cache.has(a:cmd)
        \ ? l:cache.get(a:cmd)
        \ : l:cache.set(a:cmd, wiki#jobs#capture(a:cmd))
endfunction

" }}}1

let s:backend = has('nvim') ? 'neovim' : 'vim'
