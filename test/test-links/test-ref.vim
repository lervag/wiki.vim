source ../init.vim

runtime plugin/wiki.vim
silent edit ../wiki-basic/links.wiki

let s:link = wiki#link#get_at_pos(9, 3)
call assert_equal('ref', s:link.type)
call assert_equal('wiki:index', s:link.url)

let s:link = wiki#link#get_at_pos(10, 3)
call assert_equal('wiki:file with spaces', s:link.url)

let s:link = wiki#link#get_at_pos(12, 3)
call assert_equal('ref', s:link.type)

let s:link = wiki#link#get_at_pos(12, 39)
call assert_equal('ref', s:link.type)

call wiki#test#finished()
