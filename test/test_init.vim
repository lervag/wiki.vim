source init.vim

" Test trivial buffer loading
try
  set filetype=wiki
endtry

" Test open existing wiki with no settings
try
  bwipeout!
  silent edit example/subwiki/test.wiki
  if &filetype !=# 'wiki'
    call wiki#test#error(expand('<sfile>'), 'Wiki should have been initialized (local).')
  endif
endtry


" Test open non-existing wiki with no settings (should not execute ftplugin)
try
  bwipeout!
  silent edit no-wiki/test.wiki
  if &filetype ==# 'wiki'
    call wiki#test#error(expand('<sfile>'), 'Wiki should not have been initialized (local).')
  endif
endtry

" Test open wiki from globally specified index
try
  bwipeout!
  let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/example'
  silent call wiki#goto_index()
  if &filetype !=# 'wiki'
    call wiki#test#error(expand('<sfile>'), 'Wiki should have been initialized (global).')
  endif
endtry

call wiki#test#quit()
