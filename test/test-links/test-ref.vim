source ../init.vim

runtime plugin/wiki.vim
silent edit ../wiki-basic/links.wiki

let s:link = wiki#link#get_at_pos(9, 3)
call assert_equal('reference', s:link.type)
call assert_equal('wiki:index', s:link.url)

let s:link = wiki#link#get_at_pos(10, 3)
call assert_equal('wiki:file with spaces', s:link.url)

let s:link = wiki#link#get_at_pos(12, 3)
call assert_equal('reference', s:link.type)

let s:link = wiki#link#get_at_pos(12, 39)
call assert_equal('reference', s:link.type)

let s:link = wiki#link#get_at_pos(13, 42)
call assert_equal('pageA', s:link.url)

let s:link = wiki#link#get_at_pos(14, 42)
call assert_false(has_key(s:link, 'url'))

let s:link = wiki#link#get_at_pos(15, 54)
call assert_equal('reference', s:link.type)
call assert_equal(0, s:link.lnum_target)

call wiki#test#finished()
