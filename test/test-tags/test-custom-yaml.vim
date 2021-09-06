source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0

let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
let g:wiki_tag_parsers = [
      \ g:wiki#tags#default_parser,
      \ { 'match': {x -> x =~# '^tags: '},
      \   'parse': {x -> split(matchstr(x, '^tags:\zs.*'), '[ ,]\+')}}
      \]

silent edit ../wiki-markdown/index.md

let s:tags = wiki#tags#get_all()
call assert_equal(['drink', 'good', 'life', 'work'], sort(keys(s:tags)))

call wiki#test#finished()
