source ../init.vim

runtime plugin/wiki.vim
silent edit ../wiki-basic/links_figref.wiki

let s:link = wiki#link#get_at_pos(3, 37)
call assert_equal('reference_fig', s:link.type)
call assert_equal('file:./balloons.jpg', s:link.resolve().url)

let s:link = wiki#link#get_at_pos(5, 21)
call assert_equal('reference_fig', s:link.type)
call assert_equal('file:/home/user/cloud/wiki/balloons.jpg', s:link.resolve().url)

let s:link = wiki#link#get_at_pos(7, 28)
call assert_equal('reference_fig', s:link.type)
call assert_equal('file:///home/user/cloud/wiki/balloons.jpg', s:link.resolve().url)

let s:link = wiki#link#get_at_pos(9, 28)
call assert_equal('reference_fig', s:link.type)
call assert_equal('file:./image.png', s:link.resolve().url)

let s:link = wiki#link#get_at_pos(11, 25)
call assert_equal('reference_fig', s:link.type)
call assert_equal('file:./image.png', s:link.resolve().url)

let s:link = wiki#link#get_at_pos(13, 19)
call assert_equal('reference_fig', s:link.type)
call assert_equal('file:./balloons.jpg', s:link.resolve().url)

call wiki#log#set_silent()
let s:link = wiki#link#get_at_pos(15, 30)
call assert_equal('reference_fig', s:link.type)
call assert_equal({}, s:link.resolve())
call wiki#log#set_silent_restore()

call wiki#test#finished()
