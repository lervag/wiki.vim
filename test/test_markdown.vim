source init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
runtime plugin/wiki.vim

" Test open existing wiki with no settings
try
  bwipeout!
  silent edit ex2-markdown/README.md
  silent execute "normal \<Plug>(wiki-link-next)"
  silent execute "normal \<Plug>(wiki-link-open)"

  if expand('%:t') !=# 'test.md'
    call wiki#test#error(expand('<sfile>'), 'Should have opened test.md!')
  endif
endtry

" Test toggle normal on regular markdown links
try
  bwipeout!
  silent edit ex2-markdown/README.md
  normal! 3G3w
  silent execute "normal \<Plug>(wiki-link-open)"

  if expand('<cWORD>') !=# '[[simple.md|simple]]'
    call wiki#test#error(expand('<sfile>'), 'Should have made link with extension!')
  endif
endtry

" Test toggle visual and operator on regular markdown links
try
  bwipeout!
  silent edit ex2-markdown/README.md
  normal! 3G3w
  silent execute "normal viw\<Plug>(wiki-link-toggle-visual)"

  if expand('<cWORD>') !=# '[[simple.md|simple]]'
    call wiki#test#error(expand('<sfile>'), 'Should have made link with extension!')
  endif

  silent normal! u
  silent execute "normal \<Plug>(wiki-link-toggle-operator)w"
  if expand('<cWORD>') !=# '[[simple.md|simple]]'
    call wiki#test#error(expand('<sfile>'), 'Should have made link with extension!')
  endif
endtry

call wiki#test#quit()
