" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

if exists('b:did_ftplugin') | finish | endif
let b:did_ftplugin = 1

call wiki#init_buffer()
