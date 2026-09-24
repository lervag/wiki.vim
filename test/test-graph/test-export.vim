source ../init.vim

" The export reports both its progress and the bad arguments below
let g:wiki_log_verbose = 0

runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:dir = tempname()

"
" Export the links out of the index page as a graphviz file
"
let s:output = s:dir . '/graph.dot'
execute 'WikiGraphExport --from --depth=1 --output=' . s:output
call assert_true(filereadable(s:output))

let s:lines = readfile(s:output)
call assert_equal('digraph wiki {', s:lines[1])
call assert_equal('}', s:lines[-1])

let s:nodes = sort(map(
      \ filter(copy(s:lines), { _, x -> x =~# '^  "[^"]*" \[' }),
      \ { _, x -> matchstr(x, '^  "\zs[^"]*\ze"') }))
call assert_equal(['NewPage.wiki', 'index.wiki', 'sub/Foo.wiki'], s:nodes)

" Notice that the index page links twice to sub/Foo
let s:edges = sort(filter(copy(s:lines), { _, x -> x =~# ' -> ' }))
call assert_equal([
      \ '  "index.wiki" -> "NewPage.wiki";',
      \ '  "index.wiki" -> "sub/Foo.wiki" [label="2", penwidth=2];',
      \], s:edges)

"
" The same graph as a mermaid file
"
let s:output = s:dir . '/graph.mmd'
execute 'WikiGraphExport --format=mermaid --from --depth=1 --output=' . s:output

let s:lines = readfile(s:output)
call assert_equal([
      \ 'graph LR',
      \ '  n0["NewPage"]',
      \ '  n1["index"]',
      \ '  n2["sub/Foo"]',
      \ '  n1 --> n0',
      \ '  n1 -->|2| n2',
      \ '  classDef origin fill:#fdae6b,stroke-width:3px;',
      \ '  class n1 origin;',
      \], s:lines[1:])

"
" A relative output path is resolved relative to the wiki root
"
execute 'WikiGraphExport --from --depth=1 --output=' . 'exported/graph.dot'
call assert_true(filereadable(wiki#get_root() . '/exported/graph.dot'))
call delete(wiki#get_root() . '/exported', 'rf')

"
" The --edit option opens the exported file
"
let s:output = s:dir . '/edit.dot'
execute 'WikiGraphExport --from --edit --output=' . s:output
call assert_equal(s:output, expand('%:p'))
silent edit ../wiki-basic/index.wiki

"
" Bad arguments are reported and nothing is written
"
let s:output = s:dir . '/bad.dot'
execute 'WikiGraphExport --format=bogus --output=' . s:output
execute 'WikiGraphExport --depth=deep --output=' . s:output
execute 'WikiGraphExport --bogus --output=' . s:output
call assert_false(filereadable(s:output))

call assert_equal(
      \ ['error', 'error', 'error'],
      \ map(wiki#log#get()[-3:], { _, x -> x.type }))

call delete(s:dir, 'rf')

call wiki#test#finished()
