set nocompatible
let &runtimepath = '~/.vim/bundle/wiki,' . &runtimepath
filetype plugin indent on
syntax enable

call wiki#init()

call wiki#test#init()
