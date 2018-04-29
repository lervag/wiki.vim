" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

if exists('g:wiki_loaded') | finish | endif
let g:wiki_loaded = 1

call wiki#init()
