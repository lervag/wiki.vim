source init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['wiki', 'md']
runtime plugin/wiki.vim

" Test open existing wiki with no settings
try
  bwipeout!
  silent edit ex1-basic/subwiki/test.wiki
  if !exists('b:wiki')
    call wiki#test#error(expand('<sfile>'), 'Wiki should have been initialized (local).')
  endif
endtry

" Test open wiki from globally specified index
try
  bwipeout!
  let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/ex1-basic'
  call wiki#goto_index()
  if !exists('b:wiki')
    call wiki#test#error(expand('<sfile>'), 'Wiki should have been initialized (global).')
  endif
endtry

" Test open wiki with .md extension
try
  bwipeout!
  let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/ex2-markdown'
  call wiki#goto_index()
  if !exists('b:wiki')
    call wiki#test#error(expand('<sfile>'), 'Wiki should have been initialized (global).')
  endif
endtry

call wiki#test#quit()
