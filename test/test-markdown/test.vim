source ../init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ../wiki-markdown/README.md
silent execute "normal \<Plug>(wiki-link-next)"
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('test.md', expand('%:t'))

" Test toggle normal on regular markdown links
silent bwipeout!
silent edit ../wiki-markdown/README.md
normal! 03G3w
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('[[simple.md|simple]]', expand('<cWORD>'))

" Test toggle visual on regular markdown links
silent bwipeout!
silent edit ../wiki-markdown/README.md
normal! 3G3w
silent execute "normal viw\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[[simple.md|simple]]', expand('<cWORD>'))

" Test toggle operator on regular markdown links
silent normal! u
silent execute "normal \<Plug>(wiki-link-toggle-operator)w"
call assert_equal('[[simple.md|simple]]', expand('<cWORD>'))

call wiki#test#finished()
