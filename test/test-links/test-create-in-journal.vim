source ../init.vim

runtime plugin/wiki.vim

silent edit ../wiki-basic/journal/2021-09-27.wiki

" Target exists within journal
normal! iFooBar
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[FooBar]]', getline('.'))

" Target exists at root
normal! opageA
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[/pageA]]', getline('.'))

" Target candidates exist at root - select number 2
normal! opage
silent execute "normal \<Plug>(wiki-link-toggle)2"
call assert_equal('[[/pageB]]', getline('.'))

" Target not found - create link to nonexistent page at root
normal! opageC
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[/pageC]]', getline('.'))

call wiki#test#finished()
