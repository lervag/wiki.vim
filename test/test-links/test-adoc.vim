source ../init.vim

let g:wiki_filetypes = ['adoc']

runtime plugin/wiki.vim


" Test toggle on selection
silent edit ../wiki-adoc/index.adoc
normal! 15G
silent execute "normal f.2lve\<Plug>(wiki-link-toggle-visual)"
call assert_equal('Some text, cf. <<foo.adoc#,foo>>.', getline('.'))


" Test link to other document
set hidden
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal('foo.adoc', expand('%:t'))


" Test navigation to next link
silent %bwipeout!
silent edit ../wiki-adoc/foo.adoc
silent execute "normal \<Plug>(wiki-link-next)"
call assert_equal(5, line('.'))
call assert_equal(5, col('.'))


" Test links within a document
silent execute "normal \<Plug>(wiki-link-follow)"
call assert_equal(7, line('.'))
call assert_equal(1, col('.'))


silent %bwipeout!
silent edit ../wiki-adoc/index.adoc
let s:link = wiki#link#get_at_pos(7, 1)
call assert_equal('foo.adoc', fnamemodify(s:link.path, ':t'))
let s:link = wiki#link#get_at_pos(8, 1)
call assert_equal('_section_2', s:link.anchor)
call assert_equal('foo.adoc', fnamemodify(s:link.path, ':t'))


call wiki#test#finished()
