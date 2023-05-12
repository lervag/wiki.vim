source ../init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['org']
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ../wiki-orgmode/README.org
silent execute "normal \<Plug>(wiki-link-next)"
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('test.org', expand('%:t'))

" Test transform normal on text
silent bwipeout!
silent edit ../wiki-orgmode/README.org
normal! 03G3w
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('[[simple.org][simple]]', expand('<cWORD>'))

" Test transform visual on text
silent bwipeout!
silent edit ../wiki-orgmode/README.org
normal! 03G3w
silent execute "normal viw\<Plug>(wiki-link-transform-visual)"
call assert_equal('[[simple.org][simple]]', expand('<cWORD>'))

" Test transform operator on text
silent normal! u
silent execute "normal \<Plug>(wiki-link-transform-operator)w"
call assert_equal('[[simple.org][simple]]', expand('<cWORD>'))

" Test transform normal on regular orgmode links
silent bwipeout!
silent edit ../wiki-orgmode/README.org
" Do a yank at the end; the space in "test file" makes <cWORD> useless.
normal! 03G8wya]
" Ensure correct location.
call assert_equal('[[test.org][test file]]', @")
silent execute "normal \<Plug>(wiki-link-transform)"
" Actual test: default transform doesn't do anything
normal! ya]
call assert_equal('[[test.org][test file]]', @")
" Actual test: wiki transform changes the link.
let g:wiki_link_transforms.org = 'wiki#link#templates#wiki'
silent execute "normal \<Plug>(wiki-link-transform)"
normal! ya]
call assert_equal('[[test.org|test file]]', @")

call wiki#test#finished()
