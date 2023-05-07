source ../init.vim

runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki
normal! G

" Target exists
normal! otagged
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[[tagged]]', getline('.'))

" Target does not exist
normal! oBar
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[[Bar]]', getline('.'))

" Target candidates exist
normal! oNew
silent execute "normal \<Plug>(wiki-link-transform)1"
call assert_equal('[[NewPage]]', getline('.'))

call wiki#test#finished()
