source ../init.vim

runtime plugin/wiki.vim

silent edit ../wiki-basic/sub/index.wiki
normal! G

" Target exists within subdirectory
normal! oFoo
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[Foo]]', getline('.'))

" Target candidates exist within subdirectory
normal! oFo
silent execute "normal \<Plug>(wiki-link-toggle)1"
call assert_equal('[[Foo]]', getline('.'))

" Target not found - create link to nonexistent page
normal! oBar
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[Bar]]', getline('.'))

call wiki#test#finished()
