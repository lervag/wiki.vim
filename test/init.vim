set nocompatible
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath
filetype plugin indent on
syntax enable

call wiki#test#init()
