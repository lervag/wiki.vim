source ../init.vim

runtime plugin/wiki.vim
silent edit ../wiki-basic/links.wiki

let s:link = wiki#link#get_at_pos(3, 3)
call assert_equal('wiki', s:link.type)
call assert_equal('wiki', s:link.scheme)

let s:link = wiki#link#get_at_pos(3, 26)
call assert_equal('md', s:link.type)
call assert_equal('wiki', s:link.scheme)

let s:link = wiki#link#get_at_pos(3, 55)
call assert_equal('org', s:link.type)
call assert_equal('wiki', s:link.scheme)

let s:link = wiki#link#get_at_pos(6, 1)
call assert_equal('url', s:link.type)
call assert_equal('https', s:link.scheme)

for s:lnum in range(18, 21)
  let s:link = wiki#link#get_at_pos(s:lnum, 3)
  call assert_equal({}, s:link)
endfor

let s:link = wiki#link#get_at_pos(23, 23)
call assert_equal('url', s:link.type)
call assert_equal('zot', s:link.scheme)

let s:link = wiki#link#get_at_pos(23, 50)
call assert_equal('url', s:link.type)
call assert_equal('zot', s:link.scheme)

let s:link = wiki#link#get_at_pos(24, 11)
call assert_equal('url', s:link.type)
call assert_equal('zot', s:link.scheme)
call assert_equal('c1', s:link.key)

let s:link = wiki#link#get_at_pos(24, 18)
call assert_equal('url', s:link.type)
call assert_equal('zot', s:link.scheme)
call assert_equal('c2', s:link.key)

let s:link = wiki#link#get_at_pos(26, 5)
call assert_equal('md_fig', s:link.type)
call assert_equal('file', s:link.scheme)

let s:link = wiki#link#get_at_pos(39, 5)
call assert_equal('md', s:link.type)
call assert_equal('wiki', s:link.scheme)

" Avoid checking links inside code snippets
syntax enable
setf markdown
let s:link = wiki#link#get_at_pos(41, 19)
call assert_equal({}, s:link)
let s:link = wiki#link#get_at_pos(41, 35)
call assert_equal('md', s:link.type)
call assert_equal('wiki', s:link.scheme)

call wiki#test#finished()
