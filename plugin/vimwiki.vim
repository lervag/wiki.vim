" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('g:vimwiki_loaded') | finish | endif
let g:vimwiki_loaded = 1

if !exists('g:vimwiki_path')
  echomsg 'Please define g:vimwiki_path!'
  finish
endif

let g:vimwiki_path = fnamemodify(g:vimwiki_path, ':p')
if !isdirectory(g:vimwiki_path)
  echomsg 'Please set g:vimwiki_path to a valid wiki path!'
  finish
endif

call vimwiki#init()

" vim: fdm=marker sw=2
