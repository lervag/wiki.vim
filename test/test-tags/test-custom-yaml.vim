source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0
let g:wiki_log_verbose = 0

let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
let g:wiki_tag_parsers = [
      \ g:wiki#tags#default_parser,
      \ {
      \   'match': {x -> x =~# '^tags: '},
      \   'parse': {x -> split(matchstr(x, '^tags:\zs.*'), '[ ,]\+')},
      \   'make': {t, l -> empty(t) ? '' : 'tags: ' . join(t, ', ')},
      \ }
      \]

silent edit wiki-tmp/index.md

let s:tags = wiki#tags#get_all()
call assert_equal(['drink', 'good', 'life', 'work'], sort(keys(s:tags)))

call wiki#tags#rename('drink', 'coffee', 1)
call wiki#tags#rename('work', 'coffee', 1)
call wiki#tags#rename('life', 'good', 1)
call assert_equal(
      \ 'tags: coffee, good',
      \ readfile('wiki-tmp/yaml-tags.md')[2])

call wiki#test#finished()
