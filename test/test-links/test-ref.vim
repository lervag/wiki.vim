source ../init.vim

runtime plugin/wiki.vim
silent edit ../wiki-basic/links.wiki

let s:link = wiki#link#get_at_pos(9, 3)
call assert_equal('reference', s:link.type)
call assert_equal('wiki:index', s:link.resolve().url)

let s:url = wiki#link#get_at_pos(10, 3).resolve()
call assert_equal('wiki:file with spaces', s:url.url)

let s:link = wiki#link#get_at_pos(12, 3)
call assert_equal('reference', s:link.type)

let s:link = wiki#link#get_at_pos(12, 39)
call assert_equal('reference', s:link.type)

let s:url = wiki#link#get_at_pos(13, 42).resolve()
call assert_equal('pageA', s:url.stripped)

let s:url = wiki#link#get_at_pos(14, 42).resolve()
call assert_equal('refbad', s:url.scheme)

call wiki#log#set_silent()
let s:link = wiki#link#get_at_pos(15, 54)
call assert_equal('reference', s:link.type)
call assert_equal({}, s:link.resolve())
call wiki#log#set_silent_restore()

call wiki#test#finished()
