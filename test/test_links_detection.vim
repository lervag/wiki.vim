source init.vim

runtime plugin/wiki.vim
silent edit ex1-basic/links.wiki

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

for s:lnum in range(15, 18)
  let s:link = wiki#link#get_at_pos(s:lnum, 3)
  call wiki#test#assert_equal({}, s:link)
endfor

if $QUIT | quitall! | endif
