source ../init.vim

" The export reports its progress
let g:wiki_log_verbose = 0

runtime plugin/wiki.vim

" Create a small wiki where two of the pages link to each other
let s:root = tempname()
call mkdir(s:root, 'p')
call writefile(['[[a]]', '[[b]]'], s:root . '/index.wiki')
call writefile(['[[b]]', '[[b]]'], s:root . '/a.wiki')
call writefile(['[[a]]'], s:root . '/b.wiki')

let g:wiki_root = s:root
silent execute 'edit' s:root . '/index.wiki'

"
" The three links between "a" and "b" become a single bidirectional edge
"
let s:output = s:root . '/graph.dot'
execute 'WikiGraphExport --output=' . s:output

let s:edges = sort(filter(readfile(s:output), { _, x -> x =~# ' -> ' }))
call assert_equal([
      \ '  "a.wiki" -> "b.wiki" [dir="both", label="3", penwidth=3];',
      \ '  "index.wiki" -> "a.wiki";',
      \ '  "index.wiki" -> "b.wiki";',
      \], s:edges)

" The degrees are still counted per direction, i.e. both "a" and "b" have
" "index" and each other as incoming links
let s:tooltips = sort(filter(readfile(s:output),
      \ { _, x -> x =~# 'incoming, ' }))
call assert_equal(
      \ ['2 incoming, 1 outgoing', '2 incoming, 1 outgoing',
      \  '0 incoming, 2 outgoing'],
      \ map(s:tooltips, { _, x -> matchstr(x, 'tooltip="\zs[^"]*\ze"') }))

"
" The same graph in the mermaid format
"
let s:output = s:root . '/graph.mmd'
execute 'WikiGraphExport --format=mermaid --output=' . s:output

call assert_equal([
      \ 'graph LR',
      \ '  n0["a"]',
      \ '  n1["b"]',
      \ '  n2["index"]',
      \ '  n0 <-->|3| n1',
      \ '  n2 --> n0',
      \ '  n2 --> n1',
      \], readfile(s:output)[1:])

call delete(s:root, 'rf')

call wiki#test#finished()
