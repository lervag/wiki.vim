source ../init.vim

runtime plugin/wiki.vim
silent edit ../wiki-basic/links.wiki

let s:link = wiki#link#get_at_pos(3, 3)
call wiki#test#assert_equal('wiki', s:link.type)
call wiki#test#assert_equal('wiki', s:link.scheme)

let s:link = wiki#link#get_at_pos(3, 30)
call wiki#test#assert_equal('md', s:link.type)
call wiki#test#assert_equal('wiki', s:link.scheme)

let s:link = wiki#link#get_at_pos(6, 1)
call wiki#test#assert_equal('url', s:link.type)
call wiki#test#assert_equal('https', s:link.scheme)

let s:link = wiki#link#get_at_pos(9, 3)
call wiki#test#assert_equal('ref', s:link.type)

let s:link = wiki#link#get_at_pos(12, 3)
call wiki#test#assert_equal('ref', s:link.type)

let s:link = wiki#link#get_at_pos(12, 39)
call wiki#test#assert_equal('ref', s:link.type)

for s:lnum in range(16, 19)
  let s:link = wiki#link#get_at_pos(s:lnum, 3)
  call wiki#test#assert_equal({}, s:link)
endfor

let s:link = wiki#link#get_at_pos(21, 23)
call wiki#test#assert_equal('url', s:link.type)
call wiki#test#assert_equal('zot', s:link.scheme)

let s:link = wiki#link#get_at_pos(21, 50)
call wiki#test#assert_equal('url', s:link.type)
call wiki#test#assert_equal('zot', s:link.scheme)

let s:link = wiki#link#get_at_pos(22, 11)
call wiki#test#assert_equal('url', s:link.type)
call wiki#test#assert_equal('zot', s:link.scheme)
call wiki#test#assert_equal('c1', s:link.key)

let s:link = wiki#link#get_at_pos(22, 18)
call wiki#test#assert_equal('url', s:link.type)
call wiki#test#assert_equal('zot', s:link.scheme)
call wiki#test#assert_equal('c2', s:link.key)

let s:link = wiki#link#get_at_pos(24, 5)
call wiki#test#assert_equal('md_fig', s:link.type)
call wiki#test#assert_equal('file', s:link.scheme)

if $QUIT | quitall! | endif
