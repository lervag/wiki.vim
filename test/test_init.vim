source init.vim

try
  set filetype=wiki
  call wiki#test#error(expand('<sfile>'), 'Did not require g:wiki!')
catch /E121/
endtry

try
  let g:wiki = {}
  let g:wiki.root = fnamemodify(expand('<cfile>'), ':p:h')
  set filetype=wiki
catch /E121/
  call wiki#test#error(expand('<sfile>'), 'The wiki should have been initialized')
endtry

call wiki#test#quit()
