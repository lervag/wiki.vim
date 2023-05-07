source ../init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['md']
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ../wiki-markdown/README.md
silent execute "normal \<Plug>(wiki-link-next)"
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('test.md', expand('%:t'))

" Test toggle normal on text
silent bwipeout!
silent edit ../wiki-markdown/README.md
normal! 03G3w
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('[simple](simple.md)', expand('<cWORD>'))

" Test toggle visual on text
silent bwipeout!
silent edit ../wiki-markdown/README.md
normal! 03G3w
silent execute "normal viw\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[simple](simple.md)', expand('<cWORD>'))

" Test toggle operator on text
silent normal! u
silent execute "normal \<Plug>(wiki-link-toggle-operator)w"
call assert_equal('[simple](simple.md)', expand('<cWORD>'))

" Test toggle normal on regular markdown links
silent bwipeout!
silent edit ../wiki-markdown/README.md
" Do a yank at the end; the space in "test file" makes <cWORD> useless.
normal! 03G8wyf)
" Ensure correct location.
call assert_equal('[test file](test.md)', @")
silent execute "normal \<Plug>(wiki-link-toggle)"
" Actual test.
normal! ya]
call assert_equal('[[test.md|test file]]', @")

call wiki#test#finished()
