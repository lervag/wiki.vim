source init.vim

try
  set filetype=wiki
endtry

try
  let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/example'
  silent call wiki#goto_index()
  if &filetype !=# 'wiki'
    call wiki#test#error(expand('<sfile>'), 'The example index should have been initialized.')
  endif
endtry

call wiki#test#quit()
