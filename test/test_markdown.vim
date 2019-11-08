source init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ex2-markdown/README.md
silent execute "normal \<Plug>(wiki-link-next)"
silent execute "normal \<Plug>(wiki-link-open)"
call wiki#test#assert_equal(expand('%:t'), 'test.md')

" Test toggle normal on regular markdown links
silent bwipeout!
silent edit ex2-markdown/README.md
normal! 3G3w
silent execute "normal \<Plug>(wiki-link-open)"
call wiki#test#assert_equal(expand('<cWORD>'), '[[simple.md|simple]]')

" Test toggle visual on regular markdown links
silent bwipeout!
silent edit ex2-markdown/README.md
normal! 3G3w
silent execute "normal viw\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal(expand('<cWORD>'), '[[simple.md|simple]]')

" Test toggle operator on regular markdown links
silent normal! u
silent execute "normal \<Plug>(wiki-link-toggle-operator)w"
call wiki#test#assert_equal(expand('<cWORD>'), '[[simple.md|simple]]')

if $QUIT | quitall! | endif
