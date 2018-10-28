source init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['md']
runtime plugin/wiki.vim

" Test open existing wiki with no settings
try
  bwipeout!
  silent edit ex3/README.md
  silent execute "normal \<Plug>(wiki-link-next)"
  silent execute "normal \<Plug>(wiki-link-open)"

  if expand('%:t') !=# 'test.md'
    call wiki#test#error(expand('<sfile>'), 'Should have opened test.md!')
  endif
endtry

let $QUIT = 1
call wiki#test#quit()
