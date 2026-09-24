source ../init.vim

" The export reports its progress and the warning below
let g:wiki_log_verbose = 0

runtime plugin/wiki.vim

" Create a small wiki that is a chain of pages away from the index
let s:root = tempname()
call mkdir(s:root, 'p')
call writefile(['[[a]]'], s:root . '/index.wiki')
call writefile(['[[b]]'], s:root . '/a.wiki')
call writefile(['[[c]]'], s:root . '/b.wiki')
call writefile([''], s:root . '/c.wiki')

let g:wiki_root = s:root
silent execute 'edit' s:root . '/index.wiki'

"
" The origin is highlighted also without --color-distance
"
let s:output = s:root . '/plain.dot'
execute 'WikiGraphExport --from --output=' . s:output

let s:lines = readfile(s:output)
call assert_equal(1, len(filter(copy(s:lines), { _, x -> x =~# 'fillcolor' })))

let s:origin = filter(copy(s:lines), { _, x -> x =~# '^  "index.wiki" \[' })[0]
call assert_true(s:origin =~# 'style="rounded,filled,bold"')
call assert_true(s:origin =~# 'tooltip="0 incoming, 1 outgoing (origin)"')

"
" With --color-distance each node is filled according to its distance
"
let s:output = s:root . '/distance.dot'
execute 'WikiGraphExport --from --color-distance --output=' . s:output

let s:lines = readfile(s:output)
call assert_equal([
      \ ['a.wiki', '1', '#6baed6'],
      \ ['b.wiki', '2', '#9ecae1'],
      \ ['c.wiki', '3', '#c6dbef'],
      \ ], map(
      \   filter(copy(s:lines), { _, x -> x =~# 'distance \d' }),
      \   { _, x -> [
      \     matchstr(x, '^  "\zs[^"]*\ze"'),
      \     matchstr(x, 'distance \zs\d\+\ze'),
      \     matchstr(x, 'fillcolor="\zs[^"]*\ze"'),
      \   ] }))

"
" The mermaid format uses classes for the same purpose
"
let s:output = s:root . '/distance.mmd'
execute 'WikiGraphExport --from --color-distance --format=mermaid --output='
      \ . s:output

call assert_equal([
      \ '  classDef distance1 fill:#6baed6;',
      \ '  class n0 distance1;',
      \ '  classDef distance2 fill:#9ecae1;',
      \ '  class n1 distance2;',
      \ '  classDef distance3 fill:#c6dbef;',
      \ '  class n2 distance3;',
      \ '  classDef origin fill:#fdae6b,stroke-width:3px;',
      \ '  class n3 origin;',
      \ ], readfile(s:output)[-8:])

"
" There is no origin to measure the distance from for the entire wiki
"
let s:output = s:root . '/whole.dot'
execute 'WikiGraphExport --color-distance --output=' . s:output

call assert_equal('warning', wiki#log#get()[-2].type)
call assert_equal(0, len(filter(readfile(s:output),
      \ { _, x -> x =~# 'fillcolor' })))

call delete(s:root, 'rf')

call wiki#test#finished()
