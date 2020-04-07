source ../init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['wiki', 'md']
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ex1-basic/subwiki/test.wiki
call wiki#test#assert(exists('b:wiki'))

" Test open wiki from globally specified index
bwipeout!
let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/ex1-basic'
call wiki#test#assert(!exists('b:wiki'))
silent call wiki#goto_index()
call wiki#test#assert(exists('b:wiki'))

" Test open wiki with .md extension
bwipeout!
let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/ex2-markdown'
call wiki#test#assert(!exists('b:wiki'))
silent call wiki#goto_index()
call wiki#test#assert(exists('b:wiki'))

if $QUIT | quitall! | endif
