source ../init.vim

let g:wiki_link_target_type = 'adoc'
let g:wiki_filetypes = ['adoc']

runtime plugin/wiki.vim

" Test toggle on selection (g:wiki_link_extension should not matter here)
silent edit ../wiki-adoc/index.adoc
normal! 13G
silent execute "normal f.2lve\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('Some text, cf. <<foo.adoc#,foo>>.', getline('.'))
bwipeout!
let g:wiki_link_extension = '.adoc'
silent edit ../wiki-adoc/index.adoc
normal! 13G
silent execute "normal f.2lve\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('Some text, cf. <<foo.adoc#,foo>>.', getline('.'))


if $QUIT | quitall! | endif
