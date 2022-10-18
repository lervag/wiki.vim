source ../init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['org']
let g:wiki_link_extension = '.org'
let g:wiki_link_target_type = 'org'
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ../wiki-orgmode/README.org
silent execute "normal \<Plug>(wiki-link-next)"
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('test.org', expand('%:t'))

" Test toggle normal on text
silent bwipeout!
silent edit ../wiki-orgmode/README.org
normal! 03G3w
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('[[simple.org][simple]]', expand('<cWORD>'))

" Test toggle visual on text
silent bwipeout!
silent edit ../wiki-orgmode/README.org
normal! 03G3w
silent execute "normal viw\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[[simple.org][simple]]', expand('<cWORD>'))

" Test toggle operator on text
silent normal! u
silent execute "normal \<Plug>(wiki-link-toggle-operator)w"
call assert_equal('[[simple.org][simple]]', expand('<cWORD>'))

" Test toggle normal on regular orgmode links
silent bwipeout!
silent edit ../wiki-orgmode/README.org
" Do a yank at the end; the space in "test file" makes <cWORD> useless.
normal! 03G8wya]
" Ensure correct location.
call assert_equal('[[test.org][test file]]', @")
silent execute "normal \<Plug>(wiki-link-toggle)"
" Actual test: default toggle doesn't do anything
normal! ya]
call assert_equal('[[test.org][test file]]', @")
" Actual test: wiki toggle changes the link.
let g:wiki_link_toggles.org = 'wiki#link#wiki#template'
silent execute "normal \<Plug>(wiki-link-toggle)"
normal! ya]
call assert_equal('[[test.org|test file]]', @")

call wiki#test#finished()
